from strands import Agent
from strands.models import BedrockModel
from strands.agent.conversation_manager import SlidingWindowConversationManager
from strands.tools.executors import ConcurrentToolExecutor

from prompts.chat_prompt import CHAT_PROMPT
from settings.general import settings


class ChatAgentBuilder:

    conversation_manager = SlidingWindowConversationManager(
        window_size=20,
        should_truncate_results=True,
    )

    def __init__(self, tools: list):
        self._tools = tools

    def build_agent(self, session_manager) -> Agent:
        bedrock_model = BedrockModel(
            model_id=settings.agent_model,
            region_name=settings.region_name,
            temperature=settings.temperature,
        )

        return Agent(
            model=bedrock_model,
            system_prompt=CHAT_PROMPT,
            tools=self._tools,
            tool_executor=ConcurrentToolExecutor(),
            conversation_manager=self.conversation_manager,
            session_manager=session_manager,
        )
