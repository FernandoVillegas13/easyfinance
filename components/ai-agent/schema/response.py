from pydantic import BaseModel


class UserRequest(BaseModel):
    user_id: str
    query: str


class AgentResponse(BaseModel):
    response: str
