from functools import lru_cache
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    api_version: str = "v1"
    agent_model: str = "us.amazon.nova-2-lite-v1:0"
    region_name: str = Field(default="us-east-1", validation_alias="AWS_REGION")
    temperature: float = 0.3

    # Session Manager
    bucket_session: str = "easyfinance"
    bucket_prefix: str = "production/"

    # PostgreSQL
    db_host: str = "localhost"
    db_port: int = 5432
    db_name: str = "easyfinance"
    db_user: str = "postgres"
    db_password: str = ""
    db_table: str = "spendings"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
    ) ##Saca las verdaderas variables desde el .env


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
