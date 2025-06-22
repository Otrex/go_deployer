package utils

import (
	"encoding/json"
	"log"
	"os"
)

type App struct {
	ID   int    `json:"id"`
	Name string `json:"name"`
	RepoURL string `json:"repo_url"`
	Branch  string `json:"branch"`
	LocalPath string `json:"local_path"`
}

func LoadDB() []App {
		config := GetConfig()
		var apps []App

		jsonPath := config.DBPath

    if jsonPath == "" {
        log.Fatal("No JSON file provided. Set JSON_PATH in .env")
        os.Exit(1)
    }

    data, err := os.ReadFile(jsonPath)
    if err != nil {
        log.Fatalf("failed to read JSON file: %v", err)
        os.Exit(1)
    }
    if err := json.Unmarshal(data, &apps); err != nil {
        log.Fatalf("invalid JSON: %v", err)
        os.Exit(1)
    }

		return apps
}