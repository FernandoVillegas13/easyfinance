from agent.agent_builder import AgentBuilder
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from setttings.general import settings
from schema.response import UserResponse

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],        # en prod reemplaza por tu dominio
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def get_health():
    return {"status": 200}

@app.post(f"api/{settings.api_version}/chat")
async def chat(response: UserResponse):
    print(settings.api_version)
    print(response)