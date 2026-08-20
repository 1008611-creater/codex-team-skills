---
title: TradingAgents — tradingagents module
domain: code-knowledge
source: [tradingagents/]
---

# tradingagents

**69 facts** (error: 25, config: 7, component: 36, interface: 1)

## Core components

- `PortfolioRating` ← tradingagents/agents/schemas.py:44
- `TraderAction` ← tradingagents/agents/schemas.py:54
- `ResearchPlan` ← tradingagents/agents/schemas.py:73
- `TraderProposal` ← tradingagents/agents/schemas.py:121
- `PortfolioDecision` ← tradingagents/agents/schemas.py:188
- `SentimentBand` ← tradingagents/agents/schemas.py:258
- `SentimentReport` ← tradingagents/agents/schemas.py:273
- `route_to_vendor` ← tradingagents/dataflows/interface.py:168
- `StockstatsUtils` ← tradingagents/dataflows/stockstats_utils.py:238
- `AnalystNodeSpec` ← tradingagents/graph/analyst_execution.py:7
- `AnalystExecutionPlan` ← tradingagents/graph/analyst_execution.py:16
- `AnalystWallTimeTracker` ← tradingagents/graph/analyst_execution.py:76
- `ConditionalLogic` ← tradingagents/graph/conditional_logic.py:6
- `Propagator` ← tradingagents/graph/propagation.py:11
- `Reflector` ← tradingagents/graph/reflection.py:6
- `GraphSetup` ← tradingagents/graph/setup.py:45
- `SignalProcessor` ← tradingagents/graph/signal_processing.py:20
- `TradingAgentsGraph` ← tradingagents/graph/trading_graph.py:65
- `NormalizedChatAnthropic` ← tradingagents/llm_clients/anthropic_client.py:41
- `AnthropicClient` ← tradingagents/llm_clients/anthropic_client.py:53

## Config

- `DEFAULT_CONFIG` ← tradingagents/default_config.py
- `DEFAULT_CONFIG` ← tradingagents/dataflows/config.py
- `PROVIDER_API_KEY_ENV` ← tradingagents/llm_clients/api_key_env.py
- `AZURE_OPENAI_DEPLOYMENT_NAME` ← tradingagents/llm_clients/azure_client.py
- `AWS_REGION` ← tradingagents/llm_clients/bedrock_client.py
- `AWS_DEFAULT_REGION` ← tradingagents/llm_clients/bedrock_client.py
- `AWS_BEARER_TOKEN_BEDROCK` ← tradingagents/llm_clients/bedrock_client.py

## Errors

- `ValueError` ← tradingagents/default_config.py
- `AlphaVantageNotConfiguredError` ← tradingagents/dataflows/alpha_vantage_common.py
- `ValueError` ← tradingagents/dataflows/alpha_vantage_common.py
- `AlphaVantageRateLimitError` ← tradingagents/dataflows/alpha_vantage_common.py
- `ValueError` ← tradingagents/dataflows/alpha_vantage_indicator.py
- `VendorError` ← tradingagents/dataflows/errors.py
- `NoMarketDataError` ← tradingagents/dataflows/errors.py
- `VendorRateLimitError` ← tradingagents/dataflows/errors.py
- `VendorNotConfiguredError` ← tradingagents/dataflows/errors.py
- `FredNotConfiguredError` ← tradingagents/dataflows/fred.py
