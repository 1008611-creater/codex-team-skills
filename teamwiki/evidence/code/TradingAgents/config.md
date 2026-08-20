---
title: TradingAgents config
domain: code-knowledge
source:
  - start_server.py
  - cli/main.py
  - cli/config.py
  - cli/utils.py
  - tradingagents/default_config.py
  - tradingagents/dataflows/config.py
  - tradingagents/llm_clients/api_key_env.py
  - tradingagents/llm_clients/azure_client.py
  - tradingagents/llm_clients/bedrock_client.py
  - pyproject.toml
  - railway.toml
---

# Config

- `PORT` ← start_server.py:14 [EXTRACTED]
  ```
  port=int(os.environ.get("PORT", "8080")),
  ```
- `TRADINGAGENTS_OUTPUT_LANGUAGE` ← cli/main.py:577 [EXTRACTED]
  ```
  if os.environ.get("TRADINGAGENTS_OUTPUT_LANGUAGE"):
  ```
- `TRADINGAGENTS_MAX_DEBATE_ROUNDS` ← cli/main.py:606 [EXTRACTED]
  ```
  depth_from_env = bool(os.environ.get("TRADINGAGENTS_MAX_DEBATE_ROUNDS")) and bool(
  ```
- `TRADINGAGENTS_MAX_RISK_ROUNDS` ← cli/main.py:607 [EXTRACTED]
  ```
  os.environ.get("TRADINGAGENTS_MAX_RISK_ROUNDS")
  ```
- `TRADINGAGENTS_LLM_PROVIDER` ← cli/main.py:628 [EXTRACTED]
  ```
  provider_from_env = bool(os.environ.get("TRADINGAGENTS_LLM_PROVIDER"))
  ```
- `TRADINGAGENTS_QUICK_THINK_LLM` ← cli/main.py:678 [EXTRACTED]
  ```
  if os.environ.get("TRADINGAGENTS_QUICK_THINK_LLM") or os.environ.get("TRADINGAGENTS_DEEP_THINK_LLM"):
  ```
- `CLI_CONFIG` ← cli/config.py:1 [INFERRED]
  ```
  CLI_CONFIG = {
  ```
- `OLLAMA_BASE_URL` ← cli/utils.py:347 [EXTRACTED]
  ```
  ollama_url = os.environ.get("OLLAMA_BASE_URL") or "http://localhost:11434/v1"
  ```
- `DEFAULT_CONFIG` ← tradingagents/default_config.py:71 [INFERRED]
  ```
  DEFAULT_CONFIG = _apply_env_overrides({
  ```
- `DEFAULT_CONFIG` ← tradingagents/dataflows/config.py:13 [INFERRED]
  ```
  _config = deepcopy(default_config.DEFAULT_CONFIG)
  ```
- `PROVIDER_API_KEY_ENV` ← tradingagents/llm_clients/api_key_env.py:14 [INFERRED]
  ```
  PROVIDER_API_KEY_ENV: dict[str, str | None] = {
  ```
- `AZURE_OPENAI_DEPLOYMENT_NAME` ← tradingagents/llm_clients/azure_client.py:40 [EXTRACTED]
  ```
  "azure_deployment": os.environ.get("AZURE_OPENAI_DEPLOYMENT_NAME", self.model),
  ```
- `AWS_REGION` ← tradingagents/llm_clients/bedrock_client.py:58 [EXTRACTED]
  ```
  os.environ.get("AWS_REGION")
  ```
- `AWS_DEFAULT_REGION` ← tradingagents/llm_clients/bedrock_client.py:59 [EXTRACTED]
  ```
  or os.environ.get("AWS_DEFAULT_REGION")
  ```
- `AWS_BEARER_TOKEN_BEDROCK` ← tradingagents/llm_clients/bedrock_client.py:66 [EXTRACTED]
  ```
  bearer_token = os.environ.get("AWS_BEARER_TOKEN_BEDROCK")
  ```
- `build-system` ← pyproject.toml:1 [EXTRACTED]
  ```
  [build-system]
  ```
- `project` ← pyproject.toml:5 [EXTRACTED]
  ```
  [project]
  ```
- `project.optional-dependencies` ← pyproject.toml:38 [EXTRACTED]
  ```
  [project.optional-dependencies]
  ```
- `project.scripts` ← pyproject.toml:50 [EXTRACTED]
  ```
  [project.scripts]
  ```
- `tool.setuptools.packages.find` ← pyproject.toml:53 [EXTRACTED]
  ```
  [tool.setuptools.packages.find]
  ```
- `tool.setuptools.package-data` ← pyproject.toml:56 [EXTRACTED]
  ```
  [tool.setuptools.package-data]
  ```
- `tool.pytest.ini_options` ← pyproject.toml:59 [EXTRACTED]
  ```
  [tool.pytest.ini_options]
  ```
- `tool.ruff` ← pyproject.toml:71 [EXTRACTED]
  ```
  [tool.ruff]
  ```
- `tool.ruff.lint` ← pyproject.toml:76 [EXTRACTED]
  ```
  [tool.ruff.lint]
  ```
- `tool.ruff.lint.per-file-ignores` ← pyproject.toml:84 [EXTRACTED]
  ```
  [tool.ruff.lint.per-file-ignores]
  ```
- `tool.ruff.lint.isort` ← pyproject.toml:87 [EXTRACTED]
  ```
  [tool.ruff.lint.isort]
  ```
- `build` ← railway.toml:1 [EXTRACTED]
  ```
  [build]
  ```
- `deploy` ← railway.toml:4 [EXTRACTED]
  ```
  [deploy]
  ```