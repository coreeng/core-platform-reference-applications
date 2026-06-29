import { createServer, type Server } from "node:http";
import { registry } from "./metrics";

export function startMetricsServer(port: number): Server {
  const server = createServer((req, res) => {
    if (req.method !== "GET" || req.url !== "/metrics") {
      res.writeHead(404).end("Not Found");
      return;
    }
    registry
      .metrics()
      .then((body) => {
        res.writeHead(200, { "Content-Type": registry.contentType }).end(body);
      })
      .catch(() => {
        res.writeHead(500).end("Internal Server Error");
      });
  });
  server.on("error", (err) => {
    console.error("metrics server failed to start:", err);
    process.exit(1);
  });
  server.listen(port, "0.0.0.0");
  return server;
}
