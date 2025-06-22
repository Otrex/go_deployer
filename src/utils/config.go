package utils

import (
	"os"
	"os/user"
)

type ConfigType struct {
	Port string
	DBPath string 
	ScriptPath string
	User *user.User
}

func GetConfig() ConfigType {
	port := os.Getenv("PORT")

	if port == "" {
		port = "8080"
	}

	dbPath := os.Getenv("JSON_PATH")

	if dbPath == "" {
		dbPath = "apps.json"
	}

	scriptPath := os.Getenv("SCRIPT_PATH")

	if scriptPath == "" {
		scriptPath = "./deploy.sh"
	}

	return ConfigType{
		Port: port,
		DBPath: dbPath,
		ScriptPath: scriptPath,
		User: InstalledUser,
	}
}