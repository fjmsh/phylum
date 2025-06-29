package auth

import (
	"strconv"
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
	if len(password) < passwordConfig.Requirements.Length {
		return &PasswordStrengthError{Reason: "password must be at least " + strconv.Itoa(passwordConfig.Requirements.Length) + " characters long."}
	}
	count := map[charType]int{}
	for _, c := range password {
		count[charTypes[c]]++
	}

	if count[charTypeLower] < passwordConfig.Requirements.Lower {
		return &PasswordStrengthError{Reason: "password must have at least " + strconv.Itoa(passwordConfig.Requirements.Lower) + " lower case."}
	}
	if count[charTypeUpper] < passwordConfig.Requirements.Upper {
		return &PasswordStrengthError{Reason: "password must have at least " + strconv.Itoa(passwordConfig.Requirements.Upper) + " upper case."}
	}
	if count[charTypeNumeric] < passwordConfig.Requirements.Numeric {
		return &PasswordStrengthError{Reason: "password must have at least " + strconv.Itoa(passwordConfig.Requirements.Numeric) + " numeric."}
	}
	if count[charTypeSymbol] < passwordConfig.Requirements.Symbols {
		return &PasswordStrengthError{"password must have at least " + strconv.Itoa(passwordConfig.Requirements.Symbols) + " symbols."}
	}
	return nil
}
