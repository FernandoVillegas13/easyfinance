from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request

from schema.response import UserRequest
from settings.general import settings
from agent.log_agent_builder import LogAgentBuilder
from agent.chat_agent_builder import ChatAgentBuilder
from agent.session_manager import SessionManager
from services.database.do_database_service import DoDatabaseService
from tools.tools import Tools

# Inicializar service
database_service = DoDatabaseService()
session_manager = SessionManager()
tools = Tools(database_service=database_service)

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


class ApiKeyMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        if request.url.path == "/health":
            return await call_next(request)
        if request.headers.get("X-Api-Key") != settings.api_key:
            return JSONResponse(status_code=401, content={"detail": "Unauthorized"})
        return await call_next(request)


app.add_middleware(ApiKeyMiddleware)


@app.get("/health")
async def get_health() -> dict[str, int]:
    return {"status": 200}


@app.post(f"/api/{settings.api_version}/log")
async def log(user_request: UserRequest) -> dict[str, str]:
    """
    Silent logging endpoint. Extracts expenses from the message and saves them.
    """
    agent = LogAgentBuilder(tools=tools.get_log_tools(user_request.user_id)).build_agent()
    agent_response = agent(user_request.query)

    return {"response": str(agent_response)}


@app.post(f"/api/{settings.api_version}/chat")
async def chat(user_request: UserRequest) -> dict[str, str]:
    """
    Conversational endpoint. Can log expenses and answer analytical questions.
    Query tools are bound per-request to enforce row-level security by user_id.
    """
    chat_agent_builder = ChatAgentBuilder(
        tools=tools.get_chat_tools(user_request.user_id)
    )
    session = session_manager.get_session_manager(user_request.user_id)
    agent = chat_agent_builder.build_agent(session)
    agent_response = agent(user_request.query)

    return {"response": str(agent_response)}
