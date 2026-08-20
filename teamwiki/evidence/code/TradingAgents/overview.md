---
title: TradingAgents overview
domain: code-knowledge
---

# TradingAgents

**514 facts** extracted from 83 files.
Graph: 100 nodes, 13 edges.

## Module Structure

| Module | Facts | Components | Interfaces |
|--------|-------|------------|------------|
| tradingagents | 69 | 36 | 1 |
| cli | 13 | 6 | 0 |
| pyproject.toml | 11 | 0 | 0 |
| agent_service.py | 5 | 1 | 2 |

## Dependencies

(No cross-module dependencies detected)

## Interfaces

Types: HTTP(2)

## Key Dependency Paths

- MessageBuffer (cli/main.py): MessageBuffer
- GET /health (agent_service.py): GET /health
- POST /v1/research (agent_service.py): POST /v1/research
- StatsCallbackHandler (cli/stats_handler.py): StatsCallbackHandler
- _fetch_openrouter_models (cli/utils.py): _fetch_openrouter_models
