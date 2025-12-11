package server

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/labstack/echo"
	"github.com/stretchr/testify/assert"
)

func setup() func() {
	mockDB = true
	ResetAPI()

	return func() {
		mockDB = false
	}
}

func TestHello(t *testing.T) {
	teardown := setup()
	defer teardown()

	req := httptest.NewRequest(http.MethodGet, "/api/hello", nil)
	req.Header.Set(echo.HeaderContentType, echo.MIMETextPlain)
	recorder := httptest.NewRecorder()
	GetAPI().Serve(recorder, req)

	assert.Equal(t, 200, recorder.Code, "Bad status code")
	assert.Equal(t, "hi", recorder.Body.String(), "Bad response")
}

func TestNonExistentEndpoint(t *testing.T) {
	teardown := setup()
	defer teardown()

	req := httptest.NewRequest(http.MethodGet, "/api/blank", nil)
	req.Header.Set(echo.HeaderContentType, echo.MIMETextPlain)
	recorder := httptest.NewRecorder()
	GetAPI().Serve(recorder, req)

	assert.Equal(t, 404, recorder.Code, "Bad status code")
	assert.True(t, strings.Contains(recorder.Body.String(), "Not Found"), "Bad response")
}
