# Team Codex Skills

这目录是团队版 Codex skills 包。它从本机 `$env:USERPROFILE\.codex\skills` 同步而来，已经排除 `.env`、`config.env`、token、cookie、浏览器登录态等不该进 GitHub 的内容。

## 安装

在仓库根目录执行：

```powershell
.\skills\install-team-skills.ps1
```

安装后重启 Codex。脚本会把这些 skill 复制到：

```text
$env:USERPROFILE\.codex\skills
```

如果只想预览安装内容：

```powershell
.\skills\install-team-skills.ps1 -DryRun
```

## 凭据

不要把 API key 写进仓库。需要外部服务时，在个人机器上设置环境变量或本地未提交的 `config.env`。

常见变量：

```text
OPENAI_API_KEY
JINA_API_KEY
RUNNINGHUB_API_KEY
BEECODE_OPENAI_API_KEY
IKUN_IMAGE2_API_KEY
MONKEY_TOOLS_API_KEY
NEWAPI_API_KEY
FIGMA_OAUTH_TOKEN
PEXO_API_KEY
```

`beecode-image2` 和 `ikun-image2` 目录里只保留 `config.env.example`，真实 `config.env` 必须留在个人本地。

## 推荐使用顺序

新成员不需要一次记住所有 skill。先按工作类型调用：

| 工作类型 | 优先 skill |
|---|---|
| 三窗口 / 复杂任务验收 | `agent-team-workflow` |
| 长期上下文 / 记忆层 | `codex-agent-mem` |
| 联网检索 / 网页读取 | `jina-search` |
| 闲鱼需求挖掘与发布包 | `xianyu-ai-demand-radar`、`xianyu-product-publisher` |
| 抖音 / 快手流程 | `douyin-workflow-orchestrator`、`kuaishou-content-pipeline` |
| Image2 / GPT Image 2 | `image2-direct`、`runninghub-image2-text`、`runninghub-image2-image`、`beecode-image2`、`ikun-image2` |
| 数字人 / 视频 / 带货视频 | `seedance2-commerce-video`、`runninghub-fruit-commerce-video`、`pexoai-agent` |
| Figma / 前端设计 | `figma-*`、`frontend-design`、`impeccable` |
| 文档 / PDF / 截图 | `doc`、`pdf`、`screenshot` |
| 安全审查 | `security-best-practices`、`security-threat-model` |

## 团队规则

- 先读仓库 `AGENTS.md`，再按任务选择 skill。
- 涉及外部资料，优先用 `jina-search`。
- 涉及长期项目、三窗口、内容生产或配置变更，优先用 `codex-agent-mem`。
- 涉及上传、发布、删除、付款、登录、扫码、账号设置，必须停在用户最终确认前。
- 不提交 `.env`、`config.env`、API key、cookie、账号口令、二维码、登录态。
- 新增或修改 skill 后，同步更新这个 README 和 `TEAM_ONBOARDING_PROMPT.md`。

## 新员工提示词

见：

```text
skills/TEAM_ONBOARDING_PROMPT.md
```
