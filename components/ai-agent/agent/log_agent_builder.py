from datetime import datetime
from zoneinfo import ZoneInfo

from strands import Agent
from strands.models import BedrockModel
from strands.agent.conversation_manager import SlidingWindowConversationManager
from strands.tools.executors import ConcurrentToolExecutor

from prompts.log_prompt import build_log_prompt
from settings.general import settings


class LogAgentBuilder:

    def __init__(self, tools: list):
        self._tools = tools
        self._conversation_manager = SlidingWindowConversationManager(
            window_size=5,
            should_truncate_results=True,
        )

    def build_agent(self) -> Agent:
        bedrock_model = BedrockModel(
            model_id=settings.agent_model,
            region_name=settings.region_name,
            temperature=settings.temperature,
        )

        now = datetime.now(ZoneInfo(settings.app_timezone))
        system_prompt = build_log_prompt(
            today=now.strftime("%Y-%m-%d"),
            weekday=now.strftime("%A"),
        )

        return Agent(
            model=bedrock_model,
            system_prompt=system_prompt,
            tools=self._tools,
            tool_executor=ConcurrentToolExecutor(),
            conversation_manager=self._conversation_manager,
        )
