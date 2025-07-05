package auth

import (
	"net/http"
	"strconv"

	"codeberg.org/shroff/phylum/server/internal/core"
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

type PasswordStrengthError struct {
	Reason string
}

func (e PasswordStrengthError) Error() string {
	return e.Reason
}

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
	if len(password) < passwordRequirements.Length {
		return core.NewError(http.StatusBadRequest, "invalid_password", "password must be at least "+strconv.Itoa(passwordRequirements.Length)+" characters long.")
	}
	count := map[charType]int{}
	for _, c := range password {
		count[charTypes[c]]++
	}

	if count[charTypeLower] < passwordRequirements.Lower {
		return core.NewError(http.StatusBadRequest, "invalid_password", "password must have at least "+strconv.Itoa(passwordRequirements.Lower)+" lower case.")
	}
	if count[charTypeUpper] < passwordRequirements.Upper {
		return core.NewError(http.StatusBadRequest, "invalid_password", "password must have at least "+strconv.Itoa(passwordRequirements.Upper)+" upper case.")
	}
	if count[charTypeNumeric] < passwordRequirements.Numeric {
		return core.NewError(http.StatusBadRequest, "invalid_request", "password must have at least "+strconv.Itoa(passwordRequirements.Numeric)+" numeric.")
	}
	if count[charTypeSymbol] < passwordRequirements.Symbols {
		return core.NewError(http.StatusBadRequest, "invalid_password", "password must have at least "+strconv.Itoa(passwordRequirements.Symbols)+" symbols.")
	}
	return nil
}
