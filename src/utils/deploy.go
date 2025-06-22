package utils

import (
	"log"
	"os"
	"os/exec"
	"path/filepath"
)


func Deploy(app App, stream *StreamManager) {
	go func() {
			config := GetConfig()
			log.Printf("Deploying %s", app.Name)

			scriptPath := filepath.Join(app.LocalPath, config.ScriptPath)

			if _, err := os.Stat(scriptPath); os.IsNotExist(err) {
				log.Printf("Script file does not exist: %s", scriptPath)
				stream.Broadcast("[error] Script file not found: " + scriptPath)
				return
			}

			if err := os.Chmod(scriptPath, 0755); err != nil {
				log.Printf("Failed to make script executable: %v", err)
				stream.Broadcast("[error] Could not chmod script: " + err.Error())
				return
			}			

			cmd := exec.Command(scriptPath)
			cmd.Dir = app.LocalPath 
			cmd.Env = append(os.Environ(),
				"DEPLOYER_APP_NAME=" + app.Name,
				"DEPLOYER_APP_BRANCH=" + app.Branch,
				"DEPLOYER_APP_REPO_URL=" + app.RepoURL,
				"DEPLOYER_APP_ROOT=" + app.LocalPath,
			)	
			
			stdout, err := cmd.StdoutPipe()
			if err != nil {
				log.Printf("Error creating stdout pipe: %v", err)
				stream.Broadcast("[error] Failed to create stdout pipe: " + err.Error())
				return
			}

			stderr, err := cmd.StderrPipe()
			if err != nil {
				log.Printf("Error creating stderr pipe: %v", err)
				stream.Broadcast("[error] Failed to create stderr pipe: " + err.Error())
				return
			}

			if err := cmd.Start(); err != nil {
				log.Printf("Error starting command: %v", err)
				stream.Broadcast("[error] Failed to start command: " + err.Error())
				return
			}

			go StreamOutput(stdout, stream)
			go StreamOutput(stderr, stream)

			if err := cmd.Wait(); err != nil {
				log.Printf("Command failed: %v", err)
				stream.Broadcast("[error] Command failed: " + err.Error())
			} else {
				log.Printf("Command completed successfully")
			}

			stream.Broadcast("[done]")

		}()
	}