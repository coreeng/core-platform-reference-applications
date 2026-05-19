from fastapi import FastAPI
from fastapi.responses import PlainTextResponse

app = FastAPI()


@app.get("/hello", response_class=PlainTextResponse)
async def hello(name: str = "world") -> str:
    return f"Hello {name}"
