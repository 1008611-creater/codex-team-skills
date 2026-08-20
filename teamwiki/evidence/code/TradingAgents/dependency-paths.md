---
title: TradingAgents dependency paths
domain: code-knowledge
---

# Dependency Paths

Static import dependency paths (not runtime call traces).

10 dependency path(s) traced from entry points (max depth 4).

## MessageBuffer (cli/main.py)

    - [service] `MessageBuffer` ← cli/main.py:76

## GET /health (agent_service.py)

    - [service] `GET /health` ← agent_service.py:320

## POST /v1/research (agent_service.py)

    - [service] `POST /v1/research` ← agent_service.py:325

## StatsCallbackHandler (cli/stats_handler.py)

- [entry] `StatsCallbackHandler` ← cli/stats_handler.py:9

## _fetch_openrouter_models (cli/utils.py)

- [entry] `_fetch_openrouter_models` ← cli/utils.py:212

## select_openrouter_model (cli/utils.py)

- [entry] `select_openrouter_model` ← cli/utils.py:246

## route_to_vendor (tradingagents/dataflows/interface.py)

- [entry] `route_to_vendor` ← tradingagents/dataflows/interface.py:168

## main (main.py)

    - [service] `main` ← main.py:1

## main (start_server.py)

    - [service] `main` ← start_server.py:1

## main (cli/main.py)

    - [service] `main` ← cli/main.py:1
