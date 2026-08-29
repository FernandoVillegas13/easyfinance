from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request

from agent.chat_agent_builder import ChatAgentBuilder
from agent.log_agent_builder import LogAgentBuilder
from agent.session_manager import SessionManager
from schema.response import AgentResponse, SpendingsRequest, UserRequest
from schema.spending import SpendingListResponse
from services.database.do_database_service import DoDatabaseService
from settings.general import settings
from settings.logger import logger
from tools.tools import Tools


database_service = DoDatabaseService()
session_manager = SessionManager()

app = FastAPI()

logger.info("EasyFinance AI agent starting up")

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


@app.post(f"/api/{settings.api_version}/log", response_model=AgentResponse)
async def log(user_request: UserRequest) -> AgentResponse:
    """Extract expenses from a message and save them without chat history."""
    logger.info(f"[log] user={user_request.user_id} query={user_request.query!r}")
    request_tools = Tools(database_service, user_request.user_id)
    agent = LogAgentBuilder(tools=request_tools.get_log_tools()).build_agent()
    agent_response = agent(user_request.query)

    return AgentResponse(response=str(agent_response))


@app.post(f"/api/{settings.api_version}/chat", response_model=AgentResponse)
async def chat(user_request: UserRequest) -> AgentResponse:
    """Answer financial questions with user-scoped tools and S3 chat history."""
    logger.info(f"[chat] user={user_request.user_id} query={user_request.query!r}")
    request_tools = Tools(database_service, user_request.user_id)
    chat_agent_builder = ChatAgentBuilder(tools=request_tools.get_chat_tools())
    session = session_manager.get_session_manager(user_request.user_id)
    agent = chat_agent_builder.build_agent(session)
    agent_response = agent(user_request.query)

    return AgentResponse(response=str(agent_response))


@app.post(f"/api/{settings.api_version}/spendings", response_model=SpendingListResponse)
async def spendings(request: SpendingsRequest) -> SpendingListResponse:
    """Return recent expenses as structured data for trusted first-party clients."""
    logger.info(f"[spendings] user={request.user_id} limit={request.limit}")
    rows = database_service.list_spendings(request.user_id, request.limit)
    return SpendingListResponse(spendings=rows)
