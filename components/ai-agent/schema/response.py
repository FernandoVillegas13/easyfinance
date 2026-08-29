from pydantic import BaseModel, Field


class UserRequest(BaseModel):
    user_id: str = Field(min_length=1, max_length=128)
    query: str = Field(min_length=1, max_length=4_000)


class SpendingsRequest(BaseModel):
    user_id: str = Field(min_length=1, max_length=128)
    limit: int = Field(default=100, ge=1, le=200)


class AgentResponse(BaseModel):
    response: str
