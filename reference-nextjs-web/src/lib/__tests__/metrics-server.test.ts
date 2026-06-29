/**
 * @jest-environment node
 */
import { get } from "node:http";
import type { AddressInfo } from "node:net";
import { startMetricsServer } from "../metrics-server";

function request(
  port: number,
  path: string,
): Promise<{ status: number; contentType?: string; body: string }> {
  return new Promise((resolve, reject) => {
    get({ host: "127.0.0.1", port, path }, (res) => {
      let body = "";
      res.on("data", (chunk) => (body += chunk));
      res.on("end", () =>
        resolve({
          status: res.statusCode ?? 0,
          contentType: res.headers["content-type"],
          body,
        }),
      );
    }).on("error", reject);
  });
}

async function listen(server: ReturnType<typeof startMetricsServer>) {
  await new Promise<void>((resolve) => server.once("listening", resolve));
  return (server.address() as AddressInfo).port;
}

describe("metrics server", () => {
  it("serves Prometheus exposition on /metrics", async () => {
    const server = startMetricsServer(0);
    try {
      const res = await request(await listen(server), "/metrics");
      expect(res.status).toBe(200);
      expect(res.contentType).toContain("text/plain");
      expect(res.body).toContain("nodejs_eventloop_lag_seconds");
      expect(res.body).toContain("nextjs_build_info");
    } finally {
      server.close();
    }
  });

  it("returns 404 for other paths", async () => {
    const server = startMetricsServer(0);
    try {
      const res = await request(await listen(server), "/other");
      expect(res.status).toBe(404);
    } finally {
      server.close();
    }
  });

  it("exits the process when the port cannot be bound", async () => {
    const blocker = startMetricsServer(0);
    const port = await listen(blocker);
    const exitSpy = jest
      .spyOn(process, "exit")
      .mockImplementation(() => undefined as never);
    await new Promise<void>((resolve) => {
      startMetricsServer(port).on("error", () => resolve());
    });
    expect(exitSpy).toHaveBeenCalledWith(1);
    exitSpy.mockRestore();
    blocker.close();
  });
});
