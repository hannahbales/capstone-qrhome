package util

import (
	"math/rand"
	"strconv"
	"strings"
	"time"
)

const sourceCharacters string = "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

// TODO: This will likely change depending on the date format client side
const timeLayout = "2006-01-02"

func GenerateCode(length int) string {
	b := new(strings.Builder)
	for i := 0; i < length; i++ {
		j := rand.Intn(len(sourceCharacters))
		_ = b.WriteByte(sourceCharacters[j])
	}
	return b.String()
}

func GenerateNumberCode(digits int) string {
	b := new(strings.Builder)
	for i := 0; i < digits; i++ {
		b.WriteByte(strconv.Itoa(rand.Intn(10))[0])
	}
	return b.String()
}

func WrapDefault[T any](f func() (T, bool), defaultResult T) T {
	if res, ok := f(); ok {
		return res
	}
	return defaultResult
}

// Parse a time string into a time.Time object.
func ParseTime(timeStr string) (time.Time, error) {
	return time.Parse(timeLayout, timeStr)
}
