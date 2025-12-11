package handler

import (
	"api/core/server"
	"net/http"
)

func Handler(w http.ResponseWriter, r *http.Request) {
	server.GetAPI().Serve(w, r)
}
