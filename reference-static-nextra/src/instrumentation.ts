import type { Instrumentation } from "next";

export async function register(): Promise<void> {
  if (process.env.NEXT_RUNTIME === "nodejs") {
    await import("./lib/metrics");

    const { startMetricsServer } = await import("./lib/metrics-server");
    startMetricsServer(Number(process.env.METRICS_PORT) || 8081);
  }
}

export const onRequestError: Instrumentation.onRequestError = async (
  _error,
  _request,
  context,
) => {
  if (process.env.NEXT_RUNTIME !== "nodejs") {
    return;
  }
  const { recordServerError } = await import("./lib/metrics");
  recordServerError(context.routeType, context.routePath);
};
