package utils

import (
	"flag"
	"log"
	"os"

	"github.com/joho/godotenv"
)

func LoadConfig() ConfigType {
	envPath := flag.String("envFile", "", "Path to .env config file")
    flag.Parse()

    if *envPath != "" {
        if err := godotenv.Load(*envPath); err != nil {
            log.Fatalf("Failed to load .env from %s: %v", *envPath, err)
            os.Exit(1)
        }
    }

    return GetConfig()
}
