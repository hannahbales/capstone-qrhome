package testutil

import (
	"encoding/json"
	"fmt"
	"net/http/httptest"
	"net/url"
	"strings"

	"github.com/labstack/echo"
)

func PrepareRequestJSON(method string, target string, jsonBody interface{}) (recorder *httptest.ResponseRecorder, c echo.Context, err error) {
	jsonData, err := json.Marshal(jsonBody)
	if err != nil {
		return
	}
	e := echo.New()
	req := httptest.NewRequest(method, target, strings.NewReader(string(jsonData)))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	recorder = httptest.NewRecorder()
	c = e.NewContext(req, recorder)
	return
}

func PrepareRequestParams(method string, target string, parameters *map[string]string) (recorder *httptest.ResponseRecorder, c echo.Context, err error) {
	var params []string
	if parameters != nil {
		for key, value := range *parameters {
			params = append(params, fmt.Sprintf("%v=%v", url.QueryEscape(key), url.QueryEscape(value)))
		}
	}
	e := echo.New()
	if len(params) != 0 {
		target = fmt.Sprintf("%v?%v", target, strings.Join(params, "&"))
	}
	req := httptest.NewRequest(method, target, nil)
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	recorder = httptest.NewRecorder()
	c = e.NewContext(req, recorder)
	return
}
