package utils

import (
	"flag"
	"log"
	"os"
	"os/user"

	"github.com/joho/godotenv"
)

var InstalledUser *user.User
func getCurrentUser() *user.User {
	u, err := user.Current()
	if err != nil {
		log.Fatalf("Failed to get current user: %v", err)
        os.Exit(1)
	}
	InstalledUser = u
	return u
}

func LoadConfig() ConfigType {
	envPath := flag.String("envFile", "", "Path to .env config file")
    flag.Parse()

    if *envPath != "" {
        if err := godotenv.Load(*envPath); err != nil {
            log.Fatalf("Failed to load .env from %s: %v", *envPath, err)
            os.Exit(1)
        }
    }

    getCurrentUser()
    return GetConfig()
}
