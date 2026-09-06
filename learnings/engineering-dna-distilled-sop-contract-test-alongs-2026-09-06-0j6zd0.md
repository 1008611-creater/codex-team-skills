---
title: "工程 DNA 提炼的可复用 SOP：契约测试同行 + 修复优先 + 双高频战场优先"
category: sop
tags: [engineering-sop, quality-gate, fix-first, codex, niannianai, distilled]
severity: medium
date: 2026-09-07
author: 1008611-creater
session_signals:
  interrupts: 0
  tool_retries: 0
  rejected_calls: 0
---

# 工程 DNA 提炼的可复用 SOP

> 来源：对 `niannianai/` 主仓库（485 提交）+ `authoritative-main/`（563 提交）的 git 历史，以及 32 个 codex archived_sessions（678 条用户消息）做蒸馏（V2 报告，2026-09-06）。以下结论**跨项目可复用**，已剔除项目专属细节。
> 配套沉淀：本结论与 `teamai-push-on-windows-5-pitfalls` 互为姊妹篇（坑 vs 纪律）。

## SOP #1：改动跟随契约测试（质量门禁 SOP）

- **现象**：双仓库 git 历史里，`studio/index.html`（107/125 次）、`server.js`（70/75 次）、`s1-chain-ui.js`（34/35 次）改动最频繁，且**每次核心改动都伴随对应的 `test_*_contract.js` / `test_*_identity.js` 同步更新**（如 `test_studio_root_module_identity.js` 43/45 次、`test_studio_s1_chain_ui_contract.js`）。
- **结论**：你的真实质量门禁不是 CI（本项目 CI 已因账单停用），而是 **"契约测试随改同行"**——改了运行时/服务端契约，就必须同步改对应 `*_contract.js`，否则视为改动不完整。
- **可复用规则**：任何触及模块身份、API 契约、UI 契约的提交，PR 自检清单必须含"对应 contract 测试已更新"。这是单人高强度并行开发（238 分支）下防回归的唯一可靠护栏。

## SOP #2：修复优先于特性（节奏 SOP）

- **现象**：`fix : feat : merge : docs : test : chore ≈ 5 : 1 : 2.7 : 0.6 : 0.5 : 0.2`（主仓库 239:47）。
- **结论**：工程节奏是 **"快修快合、小步 PR、坏了立刻修"**，而非"先堆特性"。feat 占比极低说明特性型工作多在对话/草稿阶段就被拆小或直接并入 fix。
- **可复用规则**：排期时默认把"修通断点"放在"加新能力"之前。断点（链路死锁、返回 409/503、硬编码 blocked）不解锁，新特性没有验收闭环。

## SOP #3：双高频战场优先（资源排布 SOP）

- **现象**：archived_sessions 主题聚类（画布 31% / 模型渠道 16.5% / skill团队 10.8%）+ git 高频文件交叉比对，得到一条规律：**"对话高频"与"代码高频"的交集，才是真战场**。
- **结论**：
  - 画布/Studio = 对话高频（31%）+ 代码高频（studio/server 改动最密）→ **双密集，资源优先压这里**。
  - 模型/API 渠道 = 对话高频（16.5%，反复调网关/key）→ 列基础设施 P0 看护，不归特性。
  - S1 转绘链 = 对话**几乎零命中**但代码高频 → 说明它是"写代码修 bug"型卡点，**需直接动手改代码而非对话调度**（印证 `s1_chain.js:134` Step01 硬编码 blocked 整链死锁，应排期直接改而非绕）。
- **可复用规则**：用"对话频次 × 代码改动频次"二维定位优先级，单维高频（只对话或只代码）的次之，双维交集最高。

## 状态更新（修正姊妹篇遗留项）

- `teamai-push-on-windows-5-pitfalls` 第 144 行"WorkBuddy hook 没装 / 必须手动 `teamai session save --push`"**已闭环**：2026-09-06 手动把标准 `hooks` 段写入 `~/.workbuddy/settings.json`（Stop/SessionStart/PostToolUse/UserPromptUse），实测 `teamai hook-dispatch stop` 已生成 `sessions/*.json` 摩擦信号日志。现在会话结束自动 sync，无需手动。
- 注：`teamai hooks list` 仍标 workbuddy "missing" 是 inspector 的 shell 误判（它查 `/bin/sh` 可用性），配置本身已生效，不影响实际派发。

## 召回验证

`teamai recall --check "质量门禁 契约测试同行 修复优先 双高频战场"` 应命中本文。
