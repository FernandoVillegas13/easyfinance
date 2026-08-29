from functools import lru_cache
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    api_version: str = "v1"
    api_key: str = Field(validation_alias="API_KEY")
    agent_model: str = Field(default="us.anthropic.claude-haiku-4-5-20251001-v1:0", validation_alias="AGENT_MODEL")
    region_name: str = Field(default="us-east-1", validation_alias="AWS_REGION")
    temperature: float = 0.3

    # Session Manager
    bucket_session: str = Field(default="easyfinance", validation_alias="BUCKET_SESSION")
    bucket_prefix: str = Field(default="production/", validation_alias="BUCKET_PREFIX")

    # PostgreSQL
    db_host: str = Field(default="localhost", validation_alias="DB_HOST")
    db_port: int = Field(default=5432, validation_alias="DB_PORT")
    db_name: str = Field(default="easyfinance", validation_alias="DB_NAME")
    db_user: str = Field(default="postgres", validation_alias="DB_USER")
    db_password: str = Field(default="", validation_alias="DB_PASSWORD")
    db_schema: str = Field(default="easyfinance", validation_alias="DB_SCHEMA")
    db_table: str = "spendings"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
    ) ##Saca las verdaderas variables desde el .env


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
