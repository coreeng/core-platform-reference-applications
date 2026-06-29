import { Counter, Gauge, Registry, collectDefaultMetrics } from "prom-client";

type Metrics = {
  registry: Registry;
  serverErrors: Counter<"route_type" | "route">;
};

const globalForMetrics = globalThis as typeof globalThis & {
  __appMetrics?: Metrics;
};

function createMetrics(): Metrics {
  const registry = new Registry();
  collectDefaultMetrics({ register: registry });

  const serverErrors = new Counter({
    name: "nextjs_server_errors_total",
    help: "Total server-side errors captured by the onRequestError hook.",
    labelNames: ["route_type", "route"],
    registers: [registry],
  });

  const buildInfo = new Gauge({
    name: "nextjs_build_info",
    help: "Build and runtime information for the server.",
    labelNames: ["node_version"],
    registers: [registry],
  });
  buildInfo.set({ node_version: process.version }, 1);

  return { registry, serverErrors };
}

const metrics = globalForMetrics.__appMetrics ?? createMetrics();
globalForMetrics.__appMetrics = metrics;

export const registry = metrics.registry;
export const serverErrors = metrics.serverErrors;

export function recordServerError(routeType: string, route: string): void {
  serverErrors.inc({ route_type: routeType, route: route || "unknown" });
}
