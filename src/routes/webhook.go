package routes

import (
	"fmt"
	"net/http"
	"os"
	"strconv"

	"github.com/Otrex/go_deployer/src/utils"
	"github.com/gin-gonic/gin"
)

func Register(router *gin.Engine, apps []utils.App) {
	stream := utils.NewStreamManager()

	router.GET("/", func(c *gin.Context) {
		content, err := os.ReadFile("src/views/index.html")
		if err != nil {
			c.String(500, "Failed to load page: %v", err)
			return
		}
		c.Data(200, "text/html; charset=utf-8", content)
	})

	router.Any("/webhook/:project/:key", func(ctx *gin.Context) {
    project := ctx.Param("project")
		key, err := strconv.Atoi(ctx.Param("key"))

		if err != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{
				"message": "Invalid key",
			})
			return
		}

    found := false
    for _, app := range apps {
      if app.Name == project && app.ID == key {
        utils.Deploy(app, stream)
        found = true
      }
    }

    if !found {
      ctx.JSON(404, gin.H{
        "message": "App not found",
      })
      return
    }

		ctx.JSON(200, gin.H{
      "message": "Deployment started",
    })
  })

	router.GET("/stream", func(c *gin.Context) {
		c.Writer.Header().Set("Content-Type", "text/event-stream")
		c.Writer.Header().Set("Cache-Control", "no-cache")
		c.Writer.Header().Set("Connection", "keep-alive")
	
		flusher, ok := c.Writer.(http.Flusher)
		if !ok {
			c.String(http.StatusInternalServerError, "SSE not supported")
			return
		}

		ch := stream.Subscribe()
		defer stream.Remove(ch)
		for {
			select {
				case msg, ok := <-ch:
					if !ok {
						return
					}
					fmt.Fprintf(c.Writer, "data: %s\n\n", msg)
					flusher.Flush()
					// if msg == "[done]" {
					// 	return
					// }
				case <-c.Request.Context().Done():
					return
			}
		}
	})
}