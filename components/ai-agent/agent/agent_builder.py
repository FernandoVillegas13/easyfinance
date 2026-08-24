from strands import Agent
from strands.models import BedrockModel
from settings.general import settings
from strands.agent.conversation_manager import SlidingWindowConversationManager


class AgentBuilder:

    conversation_manager = SlidingWindowConversationManager(
        window_size=10,
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

        print("session_recibida:", session_manager)

        agent = Agent(
            model=bedrock_model,
            tools=self._tools,
            conversation_manager=self.conversation_manager,
            session_manager=session_manager,
        )

        return agent