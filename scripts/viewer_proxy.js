/**
 * Unified Maestro Viewer & MJPEG Stream Proxy
 * Resolves Mixed Content errors and supports POST / body forwarding.
 */
const http = require("http");

const STREAM_PORT = parseInt(process.env.STREAM_PORT || "52402", 10);
const VIEWER_PORT = parseInt(process.env.VIEWER_PORT || "8081", 10);
const PROXY_PORT = parseInt(process.env.PROXY_PORT || "8082", 10);

const server = http.createServer((req, res) => {
  if (req.url.startsWith("/stream.mjpeg")) {
    const streamUrl = `http://127.0.0.1:${STREAM_PORT}${req.url}`;
    const streamReq = http.get(streamUrl, r => {
      res.writeHead(r.statusCode, r.headers);
      r.pipe(res);
    });
    streamReq.on("error", () => {
      res.writeHead(502, { "Content-Type": "text/plain" });
      res.end("MJPEG stream server not ready yet.");
    });
  } else {
    const opt = {
      hostname: "127.0.0.1",
      port: VIEWER_PORT,
      path: req.url,
      method: req.method,
      headers: req.headers
    };
    const proxyReq = http.request(opt, r => {
      const ct = r.headers["content-type"] || "";
      if (/html|javascript|json/i.test(ct)) {
        let body = "";
        r.on("data", d => body += d);
        r.on("end", () => {
          const streamRegex = new RegExp(`http://(127\\.0\\.0\\.1|localhost):${STREAM_PORT}`, "g");
          const viewerRegex = new RegExp(`http://(127\\.0\\.0\\.1|localhost):${VIEWER_PORT}`, "g");
          let out = body.replace(streamRegex, "").replace(viewerRegex, "");
          
          delete r.headers["content-length"];
          res.writeHead(r.statusCode, r.headers);
          res.end(out);
        });
      } else {
        res.writeHead(r.statusCode, r.headers);
        r.pipe(res);
      }
    });
    proxyReq.on("error", () => {
      res.writeHead(502, { "Content-Type": "text/plain" });
      res.end("Maestro Viewer backend not reachable.");
    });
    req.pipe(proxyReq);
  }
});

server.listen(PROXY_PORT, "127.0.0.1", () => {
  console.log(`✅ Unified Viewer Proxy running on port ${PROXY_PORT} (Stream: ${STREAM_PORT}, Viewer: ${VIEWER_PORT})`);
});
