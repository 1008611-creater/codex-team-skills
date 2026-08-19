# WorkBuddy 同步说明

本仓库同时作为 Codex 与 WorkBuddy 的共享技能仓库，由 `teamai-cli` 负责把 GitHub 上的版本同步到本机工具目录。

## 第一次配置

在 WorkBuddy 所在电脑执行：

```powershell
npm install -g teamai-cli
teamai init https://github.com/1008611-creater/codex-team-skills.git --scope project --agent workbuddy
```

`--scope project` 会把项目规则放在当前项目的 `.workbuddy/` 下；如果希望当前用户的所有项目共用，改成 `--scope user`。

## 日常同步

进入项目目录后执行：

```powershell
teamai pull
```

需要把本机新增或修改的安全规则提交到团队仓库时执行：

```powershell
teamai status
teamai push
```

`teamai push` 只创建分支和 Pull Request（拉取请求），合并后其他成员再用 `teamai pull` 获取同一版本。不要直接把本机 `.workbuddy`、`.codex`、`.env`、浏览器会话或运行产物复制进仓库。

## 目录映射

| 共享内容 | WorkBuddy | Codex |
| --- | --- | --- |
| 技能 | `.workbuddy/skills` | `.codex/skills` |
| 规则 | `.workbuddy/rules` | `.codex/rules` |
| Agent（代理） | `.workbuddy/agents` | `.codex/agents` |
| 项目总规则 | `AGENTS.md` | `AGENTS.md` |

本次同步的技能仍按 `skills/<skill-name>/SKILL.md` 保存，TeamAI 会根据目标 Agent（代理）安装到对应目录，不需要改写技能内容。

## 安全检查

提交前确认以下内容没有被加入：

- API Key（接口密钥）、Token（令牌）、Cookie（会话凭据）和私钥
- `.env`、浏览器 profile（浏览器配置）和真实用户媒体
- 任务输出、临时 URL（网址）和供应商原始响应

需要外部服务的技能只读取本机环境变量或 Agent Vault（代理密钥库），共享仓库只保留示例字段和使用说明。

官方工具与文档：<https://github.com/Tencent/teamai-cli>
