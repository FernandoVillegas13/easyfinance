import os
from functools import lru_cache


class Settings:
    api_version: str = "v1"
    agent_model: str = "us.amazon.nova-2-lite-v1:0"
    region_name: str = os.getenv("AWS_REGION", "us-east-1")
    temperature: int = 0.3

    # Session Manager
    bucket_session: str = os.getenv("BUCKET_SESSION", "easyfinance")
    bucket_prefix: str = os.getenv("BUCKET_PREFIX", "production/")


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
