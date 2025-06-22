# Go Deployer

## Starting the app

To run this app, you need to run the following command:

```bash
./deployer --envFile=/path/to/env/file
```

Your env file should contain the following variables:

- PORT: The port on which the app will run.
- JSON_PATH: The path to the JSON file that contains the app information.
- SCRIPT_PATH: The path to the script that will be executed to deploy the app.

> You can copy the [.env.example](./.env.example) file to get the required variables.

Next, you before you run the app make sure you have the apps defined in the JSON_PATH file. following the format of the example file [apps.example.json](./apps.example.json).

> Ensure you also have the script defined in the SCRIPT_PATH file. This is name of the file in the project that would be executed. Check [deploy.sh](./tests/deploy.sh) for an example.

## Runing on Linux

sudo cp build/linux/deployer.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable deployer
sudo systemctl start deployer

## Runing on Mac

cp build/mac/com.example.deployer.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.example.deployer.plist
