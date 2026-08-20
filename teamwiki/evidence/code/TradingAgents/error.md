---
title: TradingAgents error
domain: code-knowledge
source:
  - agent_service.py
  - tradingagents/default_config.py
  - tradingagents/dataflows/alpha_vantage_common.py
  - tradingagents/dataflows/alpha_vantage_indicator.py
  - tradingagents/dataflows/errors.py
  - tradingagents/dataflows/fred.py
  - tradingagents/dataflows/interface.py
  - tradingagents/dataflows/market_data_validator.py
  - tradingagents/dataflows/stockstats_utils.py
  - tradingagents/dataflows/utils.py
  - tradingagents/dataflows/y_finance.py
  - tradingagents/graph/analyst_execution.py
  - tradingagents/graph/trading_graph.py
  - tradingagents/llm_clients/bedrock_client.py
  - tradingagents/llm_clients/factory.py
  - tradingagents/llm_clients/openai_client.py
  - tradingagents/agents/utils/structured.py
---

# Error

- `AgentServiceError` ← agent_service.py:31 [EXTRACTED]
  ```
  class AgentServiceError(Exception):
  ```
- `HTTPException` ← agent_service.py:65 [INFERRED]
  ```
  raise HTTPException(status_code=401, detail={"error": "unauthorized", "message": "研究服务认证失败。"})
  ```
- `ValueError` ← tradingagents/default_config.py:48 [INFERRED]
  ```
  raise ValueError(
  ```
- `AlphaVantageNotConfiguredError` ← tradingagents/dataflows/alpha_vantage_common.py:18 [EXTRACTED]
  ```
  class AlphaVantageNotConfiguredError(VendorNotConfiguredError):
  ```
- `ValueError` ← tradingagents/dataflows/alpha_vantage_common.py:52 [INFERRED]
  ```
  raise ValueError(f"Unsupported date format: {date_input}") from None
  ```
- `AlphaVantageRateLimitError` ← tradingagents/dataflows/alpha_vantage_common.py:58 [EXTRACTED]
  ```
  class AlphaVantageRateLimitError(VendorRateLimitError):
  ```
- `ValueError` ← tradingagents/dataflows/alpha_vantage_indicator.py:63 [INFERRED]
  ```
  raise ValueError(
  ```
- `VendorError` ← tradingagents/dataflows/errors.py:21 [EXTRACTED]
  ```
  class VendorError(Exception):
  ```
- `NoMarketDataError` ← tradingagents/dataflows/errors.py:25 [EXTRACTED]
  ```
  class NoMarketDataError(VendorError):
  ```
- `VendorRateLimitError` ← tradingagents/dataflows/errors.py:46 [EXTRACTED]
  ```
  class VendorRateLimitError(VendorError):
  ```
- `VendorNotConfiguredError` ← tradingagents/dataflows/errors.py:50 [EXTRACTED]
  ```
  class VendorNotConfiguredError(VendorError, ValueError):
  ```
- `FredNotConfiguredError` ← tradingagents/dataflows/fred.py:75 [EXTRACTED]
  ```
  class FredNotConfiguredError(VendorNotConfiguredError):
  ```
- `ValueError` ← tradingagents/dataflows/fred.py:110 [INFERRED]
  ```
  raise ValueError(
  ```
- `ValueError` ← tradingagents/dataflows/interface.py:151 [INFERRED]
  ```
  raise ValueError(f"Method '{method}' not found in any category")
  ```
- `RuntimeError` ← tradingagents/dataflows/interface.py:262 [INFERRED]
  ```
  raise RuntimeError(f"No available vendor for '{method}'")
  ```
- `ValueError` ← tradingagents/dataflows/market_data_validator.py:37 [INFERRED]
  ```
  raise ValueError(f"No OHLCV data available for {symbol}.")
  ```
- `NoMarketDataError` ← tradingagents/dataflows/stockstats_utils.py:123 [INFERRED]
  ```
  raise NoMarketDataError(
  ```
- `ValueError` ← tradingagents/dataflows/utils.py:30 [INFERRED]
  ```
  raise ValueError(f"ticker must be a non-empty string, got {value!r}")
  ```
- `NoMarketDataError` ← tradingagents/dataflows/y_finance.py:41 [INFERRED]
  ```
  raise NoMarketDataError(
  ```
- `ValueError` ← tradingagents/dataflows/y_finance.py:155 [INFERRED]
  ```
  raise ValueError(
  ```
- `ValueError` ← tradingagents/graph/analyst_execution.py:63 [INFERRED]
  ```
  raise ValueError(f"unknown analyst key: {analyst_key}")
  ```
- `ValueError` ← tradingagents/graph/trading_graph.py:55 [INFERRED]
  ```
  raise ValueError(f"llm_max_retries must be an integer, not a boolean: {value!r}")
  ```
- `ImportError` ← tradingagents/llm_clients/bedrock_client.py:26 [INFERRED]
  ```
  raise ImportError(
  ```
- `ValueError` ← tradingagents/llm_clients/factory.py:54 [INFERRED]
  ```
  raise ValueError(f"Unsupported LLM provider: {provider}")
  ```
- `NotImplementedError` ← tradingagents/llm_clients/openai_client.py:41 [INFERRED]
  ```
  raise NotImplementedError(
  ```
- `ValueError` ← tradingagents/llm_clients/openai_client.py:292 [INFERRED]
  ```
  raise ValueError(
  ```
- `ValueError` ← tradingagents/agents/utils/structured.py:80 [INFERRED]
  ```
  raise ValueError("structured output returned no parsed result")
  ```