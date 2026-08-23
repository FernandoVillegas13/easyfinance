from pydantic import BaseModel, Field, ConfigDict, BaseSettings
from functools import lru_cache

class Settings:
    api_version: str = "v1"

@lru.cache
def get_settings() -> Settings
    return Settings()

settings = get_settings()