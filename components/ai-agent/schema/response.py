from pydantic import BaseModel, Field, ConfigDict

class UserResponse(BaseModel):
    user_id: str
    query: str
    audio: str