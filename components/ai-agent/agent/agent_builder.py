from strands import Agent
from strands.models import BedrockModel
from settings.general import settings
from strands.agent.conversation_manager import SlidingWindowConversationManager



class AgentBuilder:


    conversation_manager = SlidingWindowConversationManager(
        window_size=10,  # Maximum number of messages to keep
        should_truncate_results=True, # Enable truncating the tool result when a message is too large for the model's context window
    )

    def build_agent(self, session_manager) -> Agent:
        bedrock_model = BedrockModel(
            model_id=settings.agent_model,
            region_name=settings.region_name,
            temperature=settings.temperature,
            conversation_manager=self.conversation_manager,
            session_manager = session_manager
        )

        return Agent(model=bedrock_model)