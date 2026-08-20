---
title: TradingAgents component
domain: code-knowledge
source:
  - cli/main.py
  - cli/models.py
  - agent_service.py
  - cli/stats_handler.py
  - cli/utils.py
  - tradingagents/agents/schemas.py
  - tradingagents/dataflows/interface.py
  - tradingagents/dataflows/stockstats_utils.py
  - tradingagents/graph/analyst_execution.py
  - tradingagents/graph/conditional_logic.py
  - tradingagents/graph/propagation.py
  - tradingagents/graph/reflection.py
  - tradingagents/graph/setup.py
  - tradingagents/graph/signal_processing.py
  - tradingagents/graph/trading_graph.py
  - tradingagents/llm_clients/anthropic_client.py
  - tradingagents/llm_clients/azure_client.py
  - tradingagents/llm_clients/bedrock_client.py
  - tradingagents/llm_clients/capabilities.py
  - tradingagents/llm_clients/google_client.py
  - tradingagents/llm_clients/openai_client.py
  - tradingagents/agents/utils/agent_states.py
  - tradingagents/agents/utils/memory.py
---

# Component

- `MessageBuffer` ← cli/main.py:76 [EXTRACTED]
  ```
  class MessageBuffer:
  ```
- `AnalystType` ← cli/models.py:4 [EXTRACTED]
  ```
  class AnalystType(str, Enum):
  ```
- `AssetType` ← cli/models.py:13 [EXTRACTED]
  ```
  class AssetType(str, Enum):
  ```
- `ResearchRequest` ← agent_service.py:25 [EXTRACTED]
  ```
  class ResearchRequest(BaseModel):
  ```
- `StatsCallbackHandler` ← cli/stats_handler.py:9 [EXTRACTED]
  ```
  class StatsCallbackHandler(BaseCallbackHandler):
  ```
- `_fetch_openrouter_models` ← cli/utils.py:212 [EXTRACTED]
  ```
  def _fetch_openrouter_models() -> list[tuple[str, str]]:
  ```
- `select_openrouter_model` ← cli/utils.py:246 [EXTRACTED]
  ```
  def select_openrouter_model(mode: str) -> str:
  ```
- `PortfolioRating` ← tradingagents/agents/schemas.py:44 [EXTRACTED]
  ```
  class PortfolioRating(str, Enum):
  ```
- `TraderAction` ← tradingagents/agents/schemas.py:54 [EXTRACTED]
  ```
  class TraderAction(str, Enum):
  ```
- `ResearchPlan` ← tradingagents/agents/schemas.py:73 [EXTRACTED]
  ```
  class ResearchPlan(BaseModel):
  ```
- `TraderProposal` ← tradingagents/agents/schemas.py:121 [EXTRACTED]
  ```
  class TraderProposal(BaseModel):
  ```
- `PortfolioDecision` ← tradingagents/agents/schemas.py:188 [EXTRACTED]
  ```
  class PortfolioDecision(BaseModel):
  ```
- `SentimentBand` ← tradingagents/agents/schemas.py:258 [EXTRACTED]
  ```
  class SentimentBand(str, Enum):
  ```
- `SentimentReport` ← tradingagents/agents/schemas.py:273 [EXTRACTED]
  ```
  class SentimentReport(BaseModel):
  ```
- `route_to_vendor` ← tradingagents/dataflows/interface.py:168 [EXTRACTED]
  ```
  def route_to_vendor(method: str, *args, **kwargs):
  ```
- `StockstatsUtils` ← tradingagents/dataflows/stockstats_utils.py:238 [EXTRACTED]
  ```
  class StockstatsUtils:
  ```
- `AnalystNodeSpec` ← tradingagents/graph/analyst_execution.py:7 [EXTRACTED]
  ```
  class AnalystNodeSpec:
  ```
- `AnalystExecutionPlan` ← tradingagents/graph/analyst_execution.py:16 [EXTRACTED]
  ```
  class AnalystExecutionPlan:
  ```
- `AnalystWallTimeTracker` ← tradingagents/graph/analyst_execution.py:76 [EXTRACTED]
  ```
  class AnalystWallTimeTracker:
  ```
- `ConditionalLogic` ← tradingagents/graph/conditional_logic.py:6 [EXTRACTED]
  ```
  class ConditionalLogic:
  ```
- `Propagator` ← tradingagents/graph/propagation.py:11 [EXTRACTED]
  ```
  class Propagator:
  ```
- `Reflector` ← tradingagents/graph/reflection.py:6 [EXTRACTED]
  ```
  class Reflector:
  ```
- `GraphSetup` ← tradingagents/graph/setup.py:45 [EXTRACTED]
  ```
  class GraphSetup:
  ```
- `SignalProcessor` ← tradingagents/graph/signal_processing.py:20 [EXTRACTED]
  ```
  class SignalProcessor:
  ```
- `TradingAgentsGraph` ← tradingagents/graph/trading_graph.py:65 [EXTRACTED]
  ```
  class TradingAgentsGraph:
  ```
- `NormalizedChatAnthropic` ← tradingagents/llm_clients/anthropic_client.py:41 [EXTRACTED]
  ```
  class NormalizedChatAnthropic(ChatAnthropic):
  ```
- `AnthropicClient` ← tradingagents/llm_clients/anthropic_client.py:53 [EXTRACTED]
  ```
  class AnthropicClient(BaseLLMClient):
  ```
- `NormalizedAzureChatOpenAI` ← tradingagents/llm_clients/azure_client.py:14 [EXTRACTED]
  ```
  class NormalizedAzureChatOpenAI(AzureChatOpenAI):
  ```
- `AzureOpenAIClient` ← tradingagents/llm_clients/azure_client.py:21 [EXTRACTED]
  ```
  class AzureOpenAIClient(BaseLLMClient):
  ```
- `BedrockClient` ← tradingagents/llm_clients/bedrock_client.py:41 [EXTRACTED]
  ```
  class BedrockClient(BaseLLMClient):
  ```
- `ModelCapabilities` ← tradingagents/llm_clients/capabilities.py:30 [EXTRACTED]
  ```
  class ModelCapabilities:
  ```
- `NormalizedChatGoogleGenerativeAI` ← tradingagents/llm_clients/google_client.py:9 [EXTRACTED]
  ```
  class NormalizedChatGoogleGenerativeAI(ChatGoogleGenerativeAI):
  ```
- `GoogleClient` ← tradingagents/llm_clients/google_client.py:20 [EXTRACTED]
  ```
  class GoogleClient(BaseLLMClient):
  ```
- `NormalizedChatOpenAI` ← tradingagents/llm_clients/openai_client.py:16 [EXTRACTED]
  ```
  class NormalizedChatOpenAI(ChatOpenAI):
  ```
- `LocalCompatibleChatOpenAI` ← tradingagents/llm_clients/openai_client.py:54 [EXTRACTED]
  ```
  class LocalCompatibleChatOpenAI(NormalizedChatOpenAI):
  ```
- `DeepSeekChatOpenAI` ← tradingagents/llm_clients/openai_client.py:88 [EXTRACTED]
  ```
  class DeepSeekChatOpenAI(NormalizedChatOpenAI):
  ```
- `MinimaxChatOpenAI` ← tradingagents/llm_clients/openai_client.py:132 [EXTRACTED]
  ```
  class MinimaxChatOpenAI(NormalizedChatOpenAI):
  ```
- `ProviderSpec` ← tradingagents/llm_clients/openai_client.py:184 [EXTRACTED]
  ```
  class ProviderSpec:
  ```
- `OpenAIClient` ← tradingagents/llm_clients/openai_client.py:257 [EXTRACTED]
  ```
  class OpenAIClient(BaseLLMClient):
  ```
- `InvestDebateState` ← tradingagents/agents/utils/agent_states.py:8 [EXTRACTED]
  ```
  class InvestDebateState(TypedDict):
  ```
- `RiskDebateState` ← tradingagents/agents/utils/agent_states.py:22 [EXTRACTED]
  ```
  class RiskDebateState(TypedDict):
  ```
- `AgentState` ← tradingagents/agents/utils/agent_states.py:47 [EXTRACTED]
  ```
  class AgentState(MessagesState):
  ```
- `TradingMemoryLog` ← tradingagents/agents/utils/memory.py:9 [EXTRACTED]
  ```
  class TradingMemoryLog:
  ```