---
title: TradingAgents interface
domain: code-knowledge
source:
  - agent_service.py
  - tradingagents/llm_clients/base_client.py
---

# Interface

- `GET /health` ← agent_service.py:320 [EXTRACTED]
  ```
  @app.get("/health")
  ```
- `POST /v1/research` ← agent_service.py:325 [EXTRACTED]
  ```
  @app.post("/v1/research")
  ```
- `BaseLLMClient` ← tradingagents/llm_clients/base_client.py:25 [EXTRACTED]
  ```
  class BaseLLMClient(ABC):
  ```