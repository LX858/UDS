// Tiny static server for previewing the ox_target NUI (web/) via the harness
// at .preview/dev.html. Also accepts POST /__save/<name>.png so the page can
// rasterize itself when the preview pane won't composite. Not shipped in-game.
const http = require("http");
const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname);
const PORT = 8785;

const TYPES = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".mjs": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".woff2": "font/woff2",
};

const server = http.createServer((req, res) => {
  if (req.method === "POST" && req.url.startsWith("/__save/")) {
    const name = path.basename(req.url.slice("/__save/".length)) || "shot.png";
    const chunks = [];
    req.on("data", (c) => chunks.push(c));
    req.on("end", () => {
      const body = Buffer.concat(chunks).toString();
      const b64 = body.replace(/^data:image\/png;base64,/, "");
      fs.writeFile(path.resolve(ROOT, ".preview", name), Buffer.from(b64, "base64"), (err) => {
        res.writeHead(err ? 500 : 200);
        res.end(err ? String(err) : "ok");
      });
    });
    return;
  }

  let rel = decodeURIComponent(req.url.split("?")[0]);
  if (rel === "/") rel = "/.preview/dev.html";

  const file = path.resolve(ROOT, "." + rel);
  if (!file.startsWith(ROOT)) {
    res.writeHead(403);
    res.end("forbidden");
    return;
  }

  fs.readFile(file, (err, data) => {
    if (err) {
      res.writeHead(404);
      res.end("not found: " + rel);
      return;
    }
    res.writeHead(200, { "Content-Type": TYPES[path.extname(file)] || "application/octet-stream" });
    res.end(data);
  });
});

server.listen(PORT, () => console.log(`ox_target preview → http://localhost:${PORT}/`));
