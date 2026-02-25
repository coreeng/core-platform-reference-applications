import asyncio
import logging

import uvicorn
from prometheus_fastapi_instrumentator import Instrumentator

from app.handler import app as handler_app
from app.internal import app as internal_app

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def setup_metrics() -> None:
    Instrumentator().instrument(handler_app)


async def main() -> None:
    setup_metrics()

    config_app = uvicorn.Config(handler_app, host="0.0.0.0", port=8080, log_level="info")
    config_internal = uvicorn.Config(internal_app, host="0.0.0.0", port=8081, log_level="info")

    server_app = uvicorn.Server(config_app)
    server_internal = uvicorn.Server(config_internal)

    logger.info("Starting application server on port 8080")
    logger.info("Starting internal server on port 8081")

    await asyncio.gather(server_app.serve(), server_internal.serve())


if __name__ == "__main__":
    asyncio.run(main())
