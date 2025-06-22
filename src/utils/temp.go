package utils

var IndexTemplate = `
<!DOCTYPE html>
<html>
  <head>
    <title>Deployment Status</title>
    <style>
      body {
        font-family: Arial, sans-serif;
        max-width: 800px;
        margin: 0 auto;
        padding: 20px;
        background-color: #f5f5f5;
      }
      h1 {
        color: #333;
        text-align: center;
        margin-bottom: 30px;
      }
      #output {
        background-color: #fff;
        border: 1px solid #ddd;
        border-radius: 5px;
        padding: 15px;
        min-height: 200px;
        white-space: pre-wrap;
        font-family: monospace;
        font-size: 14px;
        line-height: 1.5;
        overflow-y: auto;
        max-height: 500px;
      }
      .status-container {
        text-align: center;
        margin-bottom: 20px;
      }
      .status-badge {
        display: inline-block;
        padding: 8px 16px;
        border-radius: 20px;
        background-color: #007bff;
        color: white;
        font-weight: bold;
      }
    </style>
  </head>
  <body>
    <h1>Deployment Status Monitor</h1>
    <div class="status-container">
      <span class="status-badge">Live Deployment Status</span>
    </div>
    <pre id="output"></pre>

    <script>
      const eventSource = new EventSource("/stream");
      const output = document.getElementById("output");

      eventSource.onmessage = function (e) {
        const newLine = e.data + "\n";
        output.textContent += newLine;
        output.scrollTop = output.scrollHeight;

        if (e.data === "[done]") {
          eventSource.close();
          document.querySelector(".status-badge").style.backgroundColor =
            "#28a745";
          document.querySelector(".status-badge").textContent =
            "Deployment Complete";
        }
      };

      eventSource.onerror = function () {
        document.querySelector(".status-badge").style.backgroundColor =
          "#dc3545";
        document.querySelector(".status-badge").textContent =
          "Connection Error";
      };
    </script>
  </body>
</html>

`