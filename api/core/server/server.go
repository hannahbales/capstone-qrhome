package server

// This package handles the serving of the API endpoints,
// as well as static assets for the web app.

import (
	"api/core/server/account"
	"api/core/server/data"
	"api/core/server/file"
	db "api/db"
	"fmt"
	"os"
	"strings"

	"net/http"

	"github.com/joho/godotenv"
	"github.com/labstack/echo"
	"github.com/labstack/echo/middleware"
)

// APIServer contains the echo server and the database client.
// These exist as a singleton and allow for easy testing and use
// with other core executables so there isn't a requirement to have
// this bind to a port and serve standalone.
type APIServer struct {
	e      *echo.Echo
	client *db.PrismaClient
}

// Singleton instance of APIServer.
var api_instance *APIServer = nil

var mockDB = false
var baseUrl string = ""

// initApi creates the APIServer object that contains the echo server
// and the db client. This is to make it so you don't have to serve
// the server and instead manually feed it http requests and get responses.
func initApi() *APIServer {

	api := new(APIServer)
	api.e = echo.New()

	if mockDB {
		api.client, _, _ = db.NewMock()
	} else {
		api.client = db.NewClient()
		if err := api.client.Prisma.Connect(); err != nil {
			fmt.Printf("Fail to connect to database\n")
			return nil
		}

		account.CreateDefaultAccounts(api.client)
	}

	api.e.Pre(BaseURLMiddleware)

	api.e.GET("/api/hello", func(c echo.Context) error {
		return c.String(200, "hi")
	})

	// TODO: Consider turning ValidateAuth into a middleware function for endpoints.
	api.e.POST("/api/account/create", func(c echo.Context) error { return account.CreateAccount(c, api.client) })
	api.e.POST("/api/account/auth", func(c echo.Context) error { return account.AuthenticateAccount(c, api.client) })
	api.e.GET("/api/account/validate", func(c echo.Context) error { return account.ValidateAuthHandler(c, api.client) })
	api.e.GET("api/data/personal", func(c echo.Context) error { return data.GetPersInfoHandler(c, api.client) })
	api.e.POST("api/data/personal", func(c echo.Context) error { return data.UpdatePersInfoHandler(c, api.client) })
	api.e.GET("api/data/family", func(c echo.Context) error { return data.GetFamilyMembersHandler(c, api.client) })
	api.e.POST("api/data/family/create", func(c echo.Context) error { return data.AddFamilyMemberHandler(c, api.client) })
	api.e.POST("api/data/family/update", func(c echo.Context) error { return data.UpdateFamilyMemberHandler(c, api.client) })
	api.e.POST("api/data/family/delete", func(c echo.Context) error { return data.DeleteFamilyMemberHandler(c, api.client) })
	api.e.GET("api/data/application", func(c echo.Context) error { return data.GetApplicationDataHandler(c, api.client) })
	api.e.POST("api/data/application", func(c echo.Context) error { return data.UpdateApplicationDataHandler(c, api.client) })
	api.e.GET("/api/account/validate-2fa", func(c echo.Context) error { return account.Validate2FAHandler(c, api.client) })
	api.e.GET("/api/account/enable-2fa", func(c echo.Context) error { return account.Enable2FAHandler(c, api.client) })
	api.e.GET("/api/account/disable-2fa", func(c echo.Context) error { return account.Disable2FAHandler(c, api.client) })
	api.e.GET("/api/account/2fa-status", func(c echo.Context) error { return account.Get2FAStatus(c, api.client) })
	api.e.GET("/api/account/link", func(c echo.Context) error { return account.GetAccountLinkCode(c, api.client) })
	api.e.POST("/api/account/delete-account", func(c echo.Context) error { return account.DeleteAccount(c, api.client) })
	api.e.GET("/api/account/linkcode", func(c echo.Context) error { return account.GetAccountLinkCode(c, api.client) })
	api.e.GET("/api/account/linkcode/meta", func(c echo.Context) error { return account.GetAccountLinkCodeMeta(c, api.client) })
	api.e.POST("/api/account/link", func(c echo.Context) error { return account.LinkAccountsHandler(c, api.client) })
	api.e.POST("/api/account/unlink", func(c echo.Context) error { return account.UnlinkAccountHandler(c, api.client) })
	api.e.GET("/api/account/links", func(c echo.Context) error { return account.GetAccountConnections(c, api.client) })
	api.e.GET("/api/seed", func(c echo.Context) error { return seedDB(c, api.client) })

	// File routes
	api.e.POST("/api/file/upload", func(c echo.Context) error { return file.UploadFileHandler(c, api.client) })
	api.e.GET("/api/file/list", func(c echo.Context) error { return file.GetFilesHandler(c, api.client) })
	api.e.GET("/api/file", func(c echo.Context) error { return file.GetFileByIDHandler(c, api.client) })
	api.e.DELETE("/api/file", func(c echo.Context) error { return file.DeleteFileHandler(c, api.client) })

	api.e.GET("/api/seed", func(c echo.Context) error { return seedDB(c, api.client) })
	api.e.Use(middleware.CORS())
	return api
}

// Get APIServer singleton.
func GetAPI() *APIServer {
	if api_instance == nil {
		api_instance = initApi()
	}
	return api_instance
}

func ResetAPI() {
	api_instance = nil
}

func BaseURLMiddleware(inFunc echo.HandlerFunc) echo.HandlerFunc {
	return func(c echo.Context) error {
		req := c.Request()
		// fmt.Printf("Path: %s\n", req.URL.Path)
		if len(baseUrl) == 0 || baseUrl == "/" {
			return inFunc(c)
		}
		index := strings.Index(req.URL.Path, baseUrl)
		req.URL.Path = fmt.Sprintf("%s%s", req.URL.Path[:index], req.URL.Path[index+len(baseUrl):])
		// fmt.Printf("New Path: %s\n", req.URL.Path)
		return inFunc(c)
	}
}

// Start serving.
func (api *APIServer) Start() {

	currentWorkDirectory, _ := os.Getwd()
	fmt.Printf("Cwd: %v\n", currentWorkDirectory)
	godotenv.Load(currentWorkDirectory + "/../.env")

	baseUrl = os.Getenv("HTML_ROOT")
	api.e.Static("/", "app")
	fmt.Printf("%s -> app\n", baseUrl)

	addr := fmt.Sprintf(":%s", os.Getenv("API_PORT"))
	api.e.Logger.Fatal(api.e.Start(addr))
}

// Serve specific request.
func (api *APIServer) Serve(w http.ResponseWriter, r *http.Request) {
	api.e.ServeHTTP(w, r)
}

func seedDB(c echo.Context, client *db.PrismaClient) error {
	account.CreateDefaultAccounts(client)

	return c.String(200, "")
}
