package file

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"

	"api/core/server/account"
	db "api/db"

	"github.com/labstack/echo"
)

const MaxFileSize = 10 * 1024 * 1024

// Response structs
type FileUploadResponse struct {
	Success  bool   `json:"success"`
	FileType string `json:"file_type,omitempty"`
	Error    string `json:"error,omitempty"`
}

type FileResponse struct {
	ID       string `json:"id"`
	Filename string `json:"filename"`
	FileType string `json:"file_type"`
	MimeType string `json:"mime_type"` 
}

type GetFilesResponse struct {
	Success bool           `json:"success"`
	Files   []FileResponse `json:"files,omitempty"`
	Error   string         `json:"error,omitempty"`
}

type DeleteFileResponse struct {
	Success bool `json:"success"`
	Error   string `json:"error"`
}

/* UploadFileHandler handles file uploads and saves them to the database. */
func UploadFileHandler(c echo.Context, client *db.PrismaClient) error {
	user := account.ValidateAuth(c, client)
	if user == nil {
		return c.JSON(400, FileUploadResponse{Success: false, Error: "Failed to authenticate"})
	}

	personalInfo, personalInfoErr := client.PersonalInfo.FindFirst(
		db.PersonalInfo.User.Where(
			db.User.ID.Equals(user.ID),
		),
	).Exec(context.Background())
	if personalInfo == nil || personalInfoErr != nil {
		fmt.Printf("[ERROR] Personal info not found\n")
		return c.JSON(400, FileUploadResponse{
			Success: false,
			Error:   "Personal info not found for account",
		})
	}

	form, err := c.MultipartForm()
	if err != nil {
		return c.JSON(500, FileUploadResponse{Success: false, Error: "Failed to get multipart form"})
	}

	files := form.File["file"]
	if len(files) == 0 {
		return c.JSON(500, FileUploadResponse{
			Success: false,
			Error:   "No files uploaded",
		})
	}

	fileTypeValues := form.Value["file_type"]
	var uploadedFileType string
	if len(fileTypeValues) > 0 {
		uploadedFileType = fileTypeValues[0]
	}

	var uploadedFiles []string

	for _, file := range files {
		src, err := file.Open()
		if err != nil {
			return c.JSON(500, FileUploadResponse{
				Success: false,
				Error:   "Failed to open uploaded file",
			})
		}
		defer src.Close()

		fileBytes, err := io.ReadAll(src)
		if err != nil {
			return c.JSON(500, FileUploadResponse{
				Success: false,
				Error:   "Failed to read uploaded file",
			})
		}

		if len(fileBytes) > MaxFileSize {
			return c.JSON(500, FileUploadResponse{
				Success: false,
				Error:   "Uploaded file is too large",
			})
		}

		detectedMimeType := http.DetectContentType(fileBytes)
		if !allowedFileType(detectedMimeType) {
			return c.JSON(http.StatusBadRequest, FileUploadResponse{
				Success:  false,
				FileType: detectedMimeType,
				Error:    fmt.Sprintf("File type '%s' is not allowed", detectedMimeType),
			})
		}

		_, err = client.UploadedFile.CreateOne(
			db.UploadedFile.Filename.Set(file.Filename),
			db.UploadedFile.FileType.Set(uploadedFileType),
			db.UploadedFile.MimeType.Set(detectedMimeType),
			db.UploadedFile.FileData.Set(fileBytes),

			db.UploadedFile.PersonalInfo.Link(
				db.PersonalInfo.ID.Equals(personalInfo.ID),
			),
		).Exec(context.Background())
		if err != nil {
			return c.JSON(500, FileUploadResponse{
				Success: false,
				Error:   "Failed to save uploaded file",
			})
		}

		uploadedFiles = append(uploadedFiles, file.Filename)
	}

	// Respond with list of successfully uploaded filenames
	return c.JSON(http.StatusOK, map[string]interface{}{
		"success":        true,
		"file_type":      uploadedFileType,
		"files_uploaded": uploadedFiles,
	})
}

/* GetFilesHandler retrieves all uploaded files and returns them in a JSON response. */
func GetFilesHandler(c echo.Context, client *db.PrismaClient) error {
	user := account.ValidateAuth(c, client)
	if user == nil {
		return c.JSON(400, GetFilesResponse{Success: false, Error: "Failed to authenticate"})
	}

	ownerEmail := c.QueryParam("email")
	if ownerEmail != user.Email {
		userLink, userLinkErr := client.UserLink.FindFirst(
			db.UserLink.Caseworker.Where(
				db.User.Email.Equals(user.Email),
			),
			db.UserLink.Client.Where(
				db.User.Email.Equals(ownerEmail),
			),
		).Exec(context.Background())

		if userLink == nil || userLinkErr != nil {
			fmt.Printf("[ERROR] Not a caseworker for owner email: %s\n", ownerEmail)
			return c.JSON(400, GetFilesResponse{
				Success: false,
				Error:   "Not a caseworker for account",
			})
		}
	}

	files, filesErr := client.UploadedFile.FindMany(
		db.UploadedFile.PersonalInfo.Where(
			db.PersonalInfo.User.Where(
				db.User.Email.Equals(ownerEmail),
			),
		),
	).Exec(context.Background())
	if filesErr != nil {
		fmt.Printf("[ERROR] Failed to retrieve files for email: %s, error: %v\n", ownerEmail, filesErr)
		return c.JSON(500, GetFilesResponse{
			Success: false,
			Error:   "Failed to retrieve files",
		})
	}

	fileResponses := make([]FileResponse, len(files))
	for i, file := range files {
		fileResponses[i] = FileResponse{
			ID:       strconv.Itoa(file.ID),
			Filename: file.Filename,
			FileType: file.FileType, 
			MimeType: file.MimeType,
		}
	}

	return c.JSON(http.StatusOK, GetFilesResponse{
		Success: true,
		Files:   fileResponses,
	})
}

/* GetFileByIDHandler retrieves a file by its ID and returns the file data as a blob. */
func GetFileByIDHandler(c echo.Context, client *db.PrismaClient) error {
	user := account.ValidateAuth(c, client)
	if user == nil {
		return c.Blob(500, "text/plain", []byte("Failed to authenticate"))
	}

	id, idErr := strconv.Atoi(c.QueryParam("id"))
	if idErr != nil {
		return c.Blob(500, "text/plain", []byte("Invalid ID"))
	}

	file, err := client.UploadedFile.FindUnique(
		db.UploadedFile.ID.Equals(id),
	).With(
		db.UploadedFile.PersonalInfo.Fetch().With(
			db.PersonalInfo.User.Fetch(),
		),
	).Exec(context.Background())
	if file == nil || err != nil {
		return c.Blob(500, "text/plain", []byte("Unable to retrieve file"))
	}

	if file.PersonalInfo() == nil {
		return c.Blob(500, "text/plain", []byte("File does not belong to any personal info"))
	}

	ownerUser, hasOwnerUser := file.PersonalInfo().User()
	if !hasOwnerUser {
		return c.Blob(500, "text/plain", []byte("File does not belong to any user"))
	}

	if ownerUser.ID != user.ID {
		userLink, userLinkErr := client.UserLink.FindFirst(
			db.UserLink.Caseworker.Where(
				db.User.Email.Equals(user.Email),
			),
			db.UserLink.Client.Where(
				db.User.ID.Equals(ownerUser.ID),
			),
		).Exec(context.Background())
		if userLink == nil || userLinkErr != nil {
			fmt.Printf("[ERROR] Not a caseworker for owner user ID: %d\n", ownerUser.ID)
			return c.Blob(400, "text/plain", []byte("Not authorized to access this file"))
		}
	}

	c.Response().Header().Set(echo.HeaderContentType, file.MimeType)
	c.Response().Header().Set("Content-Disposition", fmt.Sprintf("attachment; filename=\"%s\"", file.Filename))

	return c.Blob(200, file.MimeType, file.FileData)
}

/* DeleteFileHandler deletes a file by its ID. */
func DeleteFileHandler(c echo.Context, client *db.PrismaClient) error {
	user := account.ValidateAuth(c, client)
	if user == nil {
		return c.JSON(400, DeleteFileResponse{Success: false, Error: "Failed to authenticate"})
	}

	id, idErr := strconv.Atoi(c.QueryParam("id"))
	if idErr != nil {
		return c.JSON(400, DeleteFileResponse{Success: false, Error: "Invalid file ID"})
	}

	// Try to delete the file
	_, deleteErr := client.UploadedFile.FindUnique(
		db.UploadedFile.ID.Equals(id),
	).Delete().Exec(context.Background())

	if deleteErr != nil {
		return c.JSON(500, DeleteFileResponse{
			Success: false,
			Error:   fmt.Sprintf("Failed to delete file with ID '%d'", id),
		})
	}

	return c.JSON(200, DeleteFileResponse{
		Success: true,
		Error:   "",
	})
}

// allowedFileType checks if the file type is allowed
func allowedFileType(mimeType string) bool {
	allowedTypes := []string{"image/jpeg", "image/png", "application/pdf"}
	for _, allowed := range allowedTypes {
		if strings.HasPrefix(mimeType, allowed) {
			return true
		}
	}
	return false
}
