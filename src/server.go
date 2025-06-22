package main

import (
	"embed"

	"github.com/Otrex/go_deployer/src/middlewares"
	"github.com/Otrex/go_deployer/src/routes"
	"github.com/Otrex/go_deployer/src/utils"
	"github.com/gin-gonic/gin"
)

//go:embed views/index.html
var htmlFS embed.FS


func main() {
  config := utils.LoadConfig()
  apps := utils.LoadDB()

  router := gin.Default()

  router.Use(middlewares.Cors())
  router.Use(middlewares.Logger())
  router.Use(gin.Recovery())

  routes.Register(router, apps)
  router.Run(":" + config.Port)
}