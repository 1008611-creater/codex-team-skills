# 念念线上版本基准台账

每个正式版本一行，值必须来自发布线程的真实回读；候选包不得登记为正式版本。

| release_id | repository | branch | commit | artifact | activated_at | rollback_release | production_readback |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `niannian-web-20260820-rename-bridge-r1` | `1008611-creater/niannianzhijian` | `codex/fix-project-rename-bridge` | `94719c79b786fd2ee82f7e7adff36f5d500d6056` | `rename-bridge-r1` | `2026-08-20` | 待发布线程填写 | 待发布线程填写 |

## 更新规则

- `commit` 必须是可从远程仓库直接获取的完整提交号，不能只写本地目录名或短标签。
- `artifact` 必须能定位到候选包或正式发布目录。
- 发布、回滚和回读由发布线程填写；开发线程只能提交候选数据。
- 发现线上版本与台账不一致时，先停止继续发布，重新核对源代码和激活元数据。
