const fs = require("fs");

let fileCount = 1;

function createTestFile() {
  const content = `Hello test case ${fileCount}`;
  const fileName = `test${fileCount}.txt`;

  fs.writeFile(fileName, content, (err) => {
    if (err) {
      console.error("Error creating file:", err);
      return;
    }
    console.log(`Created file: ${fileName}`);
    fileCount++;
  });
}

// Create initial test file
createTestFile();
