package core

import (
	"net/http"
	"strconv"

	"github.com/shroff/phylum/server/internal/core/errors"
)

type charType int

const (
	charTypeOther charType = iota
	charTypeLower
	charTypeUpper
	charTypeNumeric
	charTypeSymbol
)

var charTypes = map[rune]charType{}

func init() {
	for _, c := range "abcdefghijklmnopqrstuvwxyz" {
		charTypes[c] = charTypeLower
	}
	for _, c := range "ABCDEFGHIJKLMNOPQRSTUVWXYZ" {
		charTypes[c] = charTypeUpper
	}
	for _, c := range "0123456789" {
		charTypes[c] = charTypeNumeric
	}
	for _, c := range "`~!@#$%^&*()-_=+[]{}\\|;:'\",.<>/?" {
		charTypes[c] = charTypeSymbol
	}
}

func checkPasswordStrength(password string) error {
	if len(password) < Cfg.Password.Length {
		return errors.NewError(http.StatusBadRequest, "password_invalid", "Must be at least "+strconv.Itoa(Cfg.Password.Length)+" characters long.")
	}
	count := map[charType]int{}
	for _, c := range password {
		count[charTypes[c]]++
	}

	if count[charTypeLower] < Cfg.Password.Lower {
		return errors.NewError(http.StatusBadRequest, "password_invalid", "Must have at least "+strconv.Itoa(Cfg.Password.Lower)+" lower case.")
	}
	if count[charTypeUpper] < Cfg.Password.Upper {
		return errors.NewError(http.StatusBadRequest, "password_invalid", "Must have at least "+strconv.Itoa(Cfg.Password.Upper)+" upper case.")
	}
	if count[charTypeNumeric] < Cfg.Password.Numeric {
		return errors.NewError(http.StatusBadRequest, "password_invalid", "Must have at least "+strconv.Itoa(Cfg.Password.Numeric)+" numeric.")
	}
	if count[charTypeSymbol] < Cfg.Password.Symbols {
		return errors.NewError(http.StatusBadRequest, "password_invalid", "Must have at least "+strconv.Itoa(Cfg.Password.Symbols)+" symbols.")
	}
	return nil
}
