import json
from typing import Any

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from schema.response import UserResponse
from settings.general import settings
from agent.agent_builder import AgentBuilder
from agent.session_manager import SessionManager

app = FastAPI()
agent_builder = AgentBuilder()
session_manager = SessionManager()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En producción, reemplazar por los dominios permitidos.
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def get_health() -> dict[str, int]:
    return {"status": 200}


@app.post(f"/api/{settings.api_version}/chat")
async def chat(user_response: UserResponse) -> dict[str, str]:

    session = session_manager.get_session_manager(user_response.user_id)
    agent = agent_builder.build_agent(session)

    agent_response = agent(user_response.query)

    return {
        "response": str(agent_response),
        "status": "received"
    }
