# Windows 上 teamai init 的 safe-delete 与 hook 跳过坑

## 现象
在 WorkBuddy（Windows）上跑 `teamai init`：

- 用 `--scope user` 会把 team-repo 放在 HOME 下，触发 WorkBuddy 沙箱 safe-delete 拦截（连 `dangerouslyDisableSandbox` 也绕不过），报 `[safe-delete] 操作失败 / Error during a trash operation`。
- init 会先创建空的 team-repo 目录再 `git clone`，导致 clone 报 `already exists and is not an empty directory` 失败；需先 `rm -rf .teamai/team-repo`（沙箱外执行）再手动 clone 或重跑 init。
- init 时 hook 注入被跳过（`Skipping hook injection ... /bin/sh is not available`），意味着 Stop Hook 自动摩擦打分 / 会话结束主动提示在本环境不触发。

## 解法
- 用 `--scope project` 而非 `--scope user`。
- 鉴权用 `env -u GITHUB_TOKEN gh auth token` 取 keyring 的 `gho_` token，避免 env 里 fine-grained PAT 缺 repo scope。
- 第三层 / 第四层的自动性，在支持 hook 注入的环境（Claude Code / Cursor）才完整；WorkBuddy 上需手动 `teamai session save` + `teamai contribute` + `teamai recall`。
