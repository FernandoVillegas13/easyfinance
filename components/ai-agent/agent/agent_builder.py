import boto3
from strands import Agent
from strands.models import BedrockModel


class AgentBuilder:

    def __init__(self) -> None:
        pass


    def get_agent(self):
        
        # Create a BedrockModel
        bedrock_model = BedrockModel(
            model_id="global.anthropic.claude-sonnet-4-6",
            region_name="us-west-2",
            temperature=0.3,
        )

        agent = Agent(model=bedrock_model)

        return agent