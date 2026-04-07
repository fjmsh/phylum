package ldap

import (
	"crypto/tls"
	"errors"
	"fmt"
	"net"
	"net/url"
	"strings"
	"sync"
	"time"

	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/go-ldap/ldap/v3"
	"github.com/rs/zerolog"
)

type Config struct {
	Debug          bool         `koanf:"debug"`
	URL            string       `koanf:"url"`
	StartTLS       bool         `koanf:"starttls"`
	ConnectTimeout string       `koanf:"connect_timeout"`
	RequestTimeout string       `koanf:"request_timeout"`
	UseFilter      bool         `koanf:"use_filter"`
	DNTemplate     string       `koanf:"dn_template"`
	Filter         FilterConfig `koanf:"filter"`
}

type FilterConfig struct {
	BindDN       string `koanf:"bind_dn"`
	BindPassword string `koanf:"bind_password"`
	BaseDN       string `koanf:"base_dn"`
	Template     string `koanf:"template"`
}

type Auth struct {
	logger         zerolog.Logger
	url            string
	hostName       string
	startTLS       bool
	conn           *ldap.Conn
	connLock       sync.Mutex
	connectTimeout time.Duration
	readTimeout    time.Duration
	dnTemplate     string
	search         FilterConfig
}

var a Auth

func NewAuth(cfg Config, logger zerolog.Logger) (*Auth, error) {
	a.logger = logger.With().Str("mod", "ldap").Logger()
	if cfg.Debug {
		a.logger = logger.Level(zerolog.DebugLevel)
	}

	info := a.logger.Debug()
	if cfg.UseFilter {
		if cfg.Filter.BaseDN == "" {
			return nil, errors.New("base DN not configured")
		}
		if cfg.Filter.Template == "" {
			return nil, errors.New("filter template not configured")
		}
		info = info.Str("base_dn", cfg.Filter.BaseDN)
		info = info.Str("filter_template", cfg.Filter.Template)
	} else {
		if cfg.DNTemplate == "" {
			return nil, errors.New("DN template not configured")
		}
		info = info.Str("dn_template", cfg.DNTemplate)
	}
	info.Msg("Using ldap auth")

	if parsedURL, err := url.Parse(cfg.URL); err != nil {
		return nil, errors.New("invalid server URL: " + err.Error())
	} else {
		a.url = cfg.URL
		a.startTLS = cfg.StartTLS
		a.hostName = strings.Split(parsedURL.Host, ":")[0]
	}

	if cfg.ConnectTimeout == "" {
		a.connectTimeout = 60 * time.Second
	} else if d, err := time.ParseDuration(cfg.ConnectTimeout); err != nil {
		return nil, errors.New("failed to parse connect timeout: " + err.Error())
	} else {
		a.connectTimeout = d
	}

	if cfg.RequestTimeout == "" {
		a.readTimeout = 60 * time.Second
	} else if d, err := time.ParseDuration(cfg.RequestTimeout); err != nil {
		return nil, errors.New("failed to parse read timeout: " + err.Error())
	} else {
		a.readTimeout = d
	}
	a.dnTemplate = cfg.DNTemplate
	a.search = cfg.Filter

	var err error
	a.conn, err = a.newConn()
	if err != nil {
		return nil, errors.New("failed to connect: " + err.Error())
	}
	return &a, nil
}

func (a *Auth) newConn() (*ldap.Conn, error) {
	tlsCfg := &tls.Config{ServerName: a.hostName}
	dialer := &net.Dialer{Timeout: a.connectTimeout}

	conn, err := ldap.DialURL(a.url, ldap.DialWithDialer(dialer), ldap.DialWithTLSConfig(tlsCfg))
	if err != nil {
		a.logger.Error().Err(err).Str("url", a.url).Msg("cannot contact directory server")
	}

	if a.readTimeout != 0 {
		conn.SetTimeout(a.readTimeout)
	}

	if a.startTLS {
		if err := conn.StartTLS(tlsCfg); err != nil {
			return nil, fmt.Errorf("auth.ldap: %w", err)
		}
	}

	return conn, nil
}

func (a *Auth) SupportsPasswordUpdate() bool {
	return false
}

func (a *Auth) UpdateUserPassword(db db.Handler, username, password string) error {
	return errors.New("password update not supported")
}

func (a *Auth) VerifyUserPassword(_ db.Handler, email, password string) (bool, error) {
	a.connLock.Lock()
	defer a.connLock.Unlock()

	var userDN string
	if a.dnTemplate != "" {
		userDN = strings.ReplaceAll(a.dnTemplate, "{email}", email)
	} else {
		if _, err := a.conn.SimpleBind(&ldap.SimpleBindRequest{
			Username:           a.search.BindDN,
			Password:           a.search.BindPassword,
			AllowEmptyPassword: true,
		}); err != nil {
			return false, err
		}

		req := ldap.NewSearchRequest(
			a.search.BaseDN, ldap.ScopeWholeSubtree, ldap.NeverDerefAliases,
			2, 0, false,
			strings.ReplaceAll(a.search.Template, "{email}", email),
			[]string{"dn"}, nil)
		res, err := a.conn.Search(req)

		if err != nil {
			return false, errors.New("failed to search ldap: " + err.Error())
		}
		if len(res.Entries) > 1 {
			return false, errors.New("too manu entries returned")
		}
		if len(res.Entries) == 0 {
			return false, nil
		}
		userDN = res.Entries[0].DN
	}

	if err := a.conn.Bind(userDN, password); err != nil {
		if e, ok := err.(*ldap.Error); ok && e.ResultCode == 49 {
			err = nil
		}
		return false, err
	}

	return true, nil
}
