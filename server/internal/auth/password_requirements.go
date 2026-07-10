package auth

import (
	"strconv"
	"strings"
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

type PasswordRequirementsError struct {
	minimumLength       int
	missingRequirements []string
}

func (e PasswordRequirementsError) Error() string {
	sb := strings.Builder{}
	sb.WriteString("password must")
	if e.missingRequirements != nil {
		sb.WriteString(" have at least ")
		sb.WriteString(strings.Join(e.missingRequirements, ", "))

		if e.minimumLength != 0 {
			sb.WriteString(", and")
		}
	}
	if e.minimumLength != 0 {
		sb.WriteString(" be at least ")
		sb.WriteString(strconv.Itoa(e.minimumLength))
		sb.WriteString(" characters long")
	}
	return sb.String()
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

func (h *Handler) checkPasswordStrength(password string) error {
	var minimumLength int
	var errors []string
	if len(password) < h.passwordRequirements.Length {
		minimumLength = h.passwordRequirements.Length
	}
	count := map[charType]int{}
	for _, c := range password {
		count[charTypes[c]]++
	}

	if count[charTypeLower] < h.passwordRequirements.Lower {
		errors = append(errors, strconv.Itoa(h.passwordRequirements.Lower)+" lower case characters")
	}
	if count[charTypeUpper] < h.passwordRequirements.Upper {
		errors = append(errors, strconv.Itoa(h.passwordRequirements.Upper)+" upper case characters")
	}
	if count[charTypeNumeric] < h.passwordRequirements.Numeric {
		errors = append(errors, strconv.Itoa(h.passwordRequirements.Numeric)+" numbers")
	}
	if count[charTypeSymbol] < h.passwordRequirements.Symbols {
		errors = append(errors, strconv.Itoa(h.passwordRequirements.Symbols)+" symbols")
	}
	if minimumLength != 0 || errors != nil {
		return &PasswordRequirementsError{
			minimumLength:       minimumLength,
			missingRequirements: errors,
		}
	}
	return nil
}
