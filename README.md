# Codex Team Skills

这个仓库用于团队共享 Codex skills、三窗口工作流和新员工上手材料。

当前已经同步 67 个非 `.system` skills（技能），包含 Codex 与 WorkBuddy 共用的念念 AI、画布、图像/视频和协作规则：

- `ikun-image2`
- `ip-video-topic-selection`
- `niannian-ai-canvas`
- `minimaxh3skill`
- `runninghub-workflow-api`

## 仓库结构

- `AGENTS.md`: 团队 Codex 工作规则，新成员和 Codex 都应先读这里。
- `skills/`: 从本机 `C:\Users\lsb\.codex\skills` 导出的非 `.system` skills。
- `skills/README.md`: skills 包的安装与安全说明。
- `skills/TEAM_ONBOARDING_PROMPT.md`: 可直接发给新员工的上手提示词。
- `skills/install-team-skills.ps1`: 一键把整个 skills 包复制到本机 Codex 目录。
- `workflows/xianyu-ai-listing/`: 闲鱼 AI 商品需求挖掘、配图、发布、三窗口验收的工作流资料和脚本。
- `SKILLS_INDEX.md`: 当前导出的 skills 索引。

## 安装方式

## WorkBuddy / TeamAI 同步

这个仓库也支持 WorkBuddy。推荐使用 `teamai-cli` 管理版本，不要手动复制整个本机配置目录：

```powershell
npm install -g teamai-cli
teamai init https://github.com/1008611-creater/codex-team-skills.git --scope project --agent workbuddy
teamai pull
```

完整的项目级、用户级目录映射和安全边界见 [`docs/workbuddy-teamai-sync.md`](docs/workbuddy-teamai-sync.md)。

推荐先预览一遍：

```powershell
.\skills\install-team-skills.ps1 -DryRun
```

确认列表无误后整包安装：

```powershell
.\skills\install-team-skills.ps1
```

也可以只手动复制需要的 skill 文件夹到团队成员本机的 Codex skills 目录：

```powershell
Copy-Item -Recurse .\skills\xianyu-ai-demand-radar "$env:USERPROFILE\.codex\skills\"
Copy-Item -Recurse .\skills\xianyu-product-publisher "$env:USERPROFILE\.codex\skills\"
```

如果要让新成员直接照着跑，先打开：

```text
skills/TEAM_ONBOARDING_PROMPT.md
```

## 凭证说明

仓库不包含任何 API Key、Cookie、账号会话、`.env`、浏览器缓存或运行产物。

需要用到外部服务的 skill，请团队成员在自己本机配置本地 `.env`，例如：

```text
JINA_API_KEY=your_local_key
RUNNINGHUB_API_KEY=your_local_key
```

不要把真实 key 提交到这个仓库。

## 推荐团队使用顺序

闲鱼 AI 商品工作流优先看：

1. `skills/xianyu-ai-demand-radar`
2. `skills/xianyu-product-publisher`
3. `skills/jina-search`
4. `skills/runninghub-image2-text`
5. `skills/agent-team-workflow`
6. `workflows/xianyu-ai-listing/docs/xianyu_ai_listing_workflow_usage.md`

三窗口方法看：

```text
skills/agent-team-workflow/SKILL.md
workflows/xianyu-ai-listing/docs/task-spec.md
workflows/xianyu-ai-listing/docs/worker-report.md
workflows/xianyu-ai-listing/docs/review-report.md
```

## 安全边界

- 不上传密钥、账号、Cookie、二维码、浏览器 profile。
- 不上传闲鱼/抖音/小红书等平台的登录态。
- 不上传买家隐私素材、未授权人脸、未授权 IP 图。
- 不把攻击、绕风控、自动骚扰、接码、账号买卖作为 workflow 交付内容。
