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

	"github.com/go-ldap/ldap/v3"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
)

type Config struct {
	Debug          bool         `koanf:"debug"`
	URL            string       `koanf:"url"`
	StartTLS       bool         `koanf:"starttls"`
	ConnectTimeout string       `koanf:"connect_timeout"`
	RequestTimeout string       `koanf:"request_timeout"`
	DNTemplate     string       `koanf:"dn_template"`
	Search         SearchConfig `koanf:"search"`
}

type SearchConfig struct {
	BindDN         string `koanf:"bind_dn"`
	BindPassword   string `koanf:"bind_password"`
	BaseDN         string `koanf:"base_dn"`
	FilterTemplate string `koanf:"filter_template"`
}

type Auth struct {
	log            zerolog.Logger
	url            string
	hostName       string
	startTLS       bool
	conn           *ldap.Conn
	connLock       sync.Mutex
	connectTimeout time.Duration
	readTimeout    time.Duration
	dnTemplate     string
	search         SearchConfig
}

var a Auth

func Init(cfg Config, log zerolog.Logger) error {
	a.log = log.With().Str("c", "ldap").Logger()
	if cfg.Debug {
		a.log = log.Level(zerolog.DebugLevel)
	}

	info := a.log.Debug()
	if cfg.DNTemplate == "" {
		if cfg.Search.BaseDN == "" {
			return errors.New("base_dn not set")
		}
		if cfg.Search.FilterTemplate == "" {
			return errors.New("filter_template not set")
		}
		info = info.Str("base_dn", cfg.Search.BaseDN)
		info = info.Str("filter_template", cfg.DNTemplate)
	} else {
		info = info.Str("dn_template", cfg.DNTemplate)
	}
	info.Msg("Using ldap auth")

	if parsedURL, err := url.Parse(cfg.URL); err != nil {
		return errors.New("invalid server URL: " + err.Error())
	} else {
		a.url = cfg.URL
		a.startTLS = cfg.StartTLS
		a.hostName = strings.Split(parsedURL.Host, ":")[0]
	}

	if cfg.ConnectTimeout == "" {
		a.connectTimeout = 60 * time.Second
	} else if d, err := time.ParseDuration(cfg.ConnectTimeout); err != nil {
		return errors.New("failed to parse connect timeout: " + err.Error())
	} else {
		a.connectTimeout = d
	}

	if cfg.RequestTimeout == "" {
		a.readTimeout = 60 * time.Second
	} else if d, err := time.ParseDuration(cfg.RequestTimeout); err != nil {
		return errors.New("failed to parse read timeout: " + err.Error())
	} else {
		a.readTimeout = d
	}
	a.dnTemplate = cfg.DNTemplate
	a.search = cfg.Search

	var err error
	a.conn, err = a.newConn()
	if err != nil {
		return errors.New("failed to connect: " + err.Error())
	}
	return nil
}

func (a *Auth) newConn() (*ldap.Conn, error) {
	tlsCfg := &tls.Config{ServerName: a.hostName}
	dialer := &net.Dialer{Timeout: a.connectTimeout}

	conn, err := ldap.DialURL(a.url, ldap.DialWithDialer(dialer), ldap.DialWithTLSConfig(tlsCfg))
	if err != nil {
		log.Error().Err(err).Str("url", a.url).Msg("cannot contact directory server")
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

func (a *Auth) VerifyNew(email, password string) (bool, error) {
	a.connLock.Lock()
	defer a.connLock.Unlock()

	var userDN string
	if a.dnTemplate != "" {
		userDN = strings.ReplaceAll(a.dnTemplate, "{email}", email)
	} else {
		if b, err := a.conn.SimpleBind(&ldap.SimpleBindRequest{
			Username:           a.search.BindDN,
			Password:           a.search.BindPassword,
			AllowEmptyPassword: true,
		}); err != nil {
			return false, err
		} else {
			fmt.Printf("%+v", b)
		}

		req := ldap.NewSearchRequest(
			a.search.BaseDN, ldap.ScopeWholeSubtree, ldap.NeverDerefAliases,
			2, 0, false,
			strings.ReplaceAll(a.search.FilterTemplate, "{email}", email),
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
		return false, err
	}

	return true, nil
}
