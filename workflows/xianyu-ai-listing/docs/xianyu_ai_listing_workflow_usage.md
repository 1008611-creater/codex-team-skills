# 闲鱼 AI 信息差商品工作流使用文档

版本: 2026-05-21（已并入起号与流量运营）

适用目标: 从一个 AI 热点、竞品链接、你已有的工作流/网站/案例库出发，挖掘需求，生成闲鱼商品图文，上架发布，并沉淀复利资产。

## 1. 工作流总览

这套流程分成 11 步:

1. 发现需求: 找 AI 热点、买家痛点、竞品商品、评论里的真实问题。
2. 定账号标签: 只做 AI 工作流/部署/图片视频交付，不做大杂烩号。
3. 评分筛选: 用 WORTH 模型判断是否值得上架。
4. 产品化: 把方向拆成一个能卖的首发商品，而不是泛泛的服务。
5. 写文案: 标题、详情、套餐、交付内容、边界话术。
6. 做图片: 优先用 RunningHub Image2 生成高质感底图，再本地叠中文卖点。
7. 发布闲鱼: 用 Playwright/CDP 自动填发布页、上传图片、设置价格并发布。
8. 起号运营: 每天 2-3 个高质量同垂类商品，先跑 7 天自然流量。
9. 流量测试: 免费擦亮可以每天做，付费曝光只放大已有咨询/想要的商品。
10. 交付沉淀: 把每次交付变成 SOP、FAQ、模板、截图、案例。
11. 复盘迭代: 记录链接、浏览、想要、买家问题，反向优化下一版商品。

## 2. 主要工具和 Skill

| 能力 | Skill / 脚本 | 用途 |
| --- | --- | --- |
| 需求挖掘 | `xianyu-ai-demand-radar` | 搜热点、打分、生成机会池 |
| 商品重构发布 | `xianyu-product-publisher` | 文案、图片、发布配置、闲鱼发布 |
| 联网搜索 | `jina-search` | 按本项目偏好读取网页和搜索资料 |
| 图片生成 | `runninghub-image2-text` | RunningHub Image G 2.0 低价通道文生图 |
| 闲鱼自动化 | `goofish_publish_helper.js` | Edge CDP 填表、上传、发布 |

关键路径:

```text
C:\Users\lsb\.codex\skills\xianyu-ai-demand-radar
C:\Users\lsb\.codex\skills\xianyu-product-publisher
C:\Users\lsb\.codex\skills\runninghub-image2-text
D:\codex-work\xianyu
```

## 3. 三种入口

### A. 从竞品链接开始

适合你看到一个闲鱼商品，想做自己的版本。

你可以这样说:

```text
这是竞品链接: <闲鱼/Goofish URL>
按工作流帮我重构成我的商品，文案要更真实，有爆点，图片用 RunningHub Image2 做，最后准备发布包。
```

流程:

1. 读取竞品: 商品类型、价格、卖点、图片结构、交付承诺。
2. 避免抄袭: 不复用对方图片，不直接复制文案。
3. 重构 offer: 标题、详情、套餐、下单要求、风险边界。
4. 生成原创图: 5-8 张。
5. 生成 `publish_config.json`。
6. 等你确认后发布。

### B. 从热点/关键词开始

适合挖新商品，比如 Hermes、OpenClaw、Wan2.2、展示面、Image2。

你可以这样说:

```text
用需求雷达帮我挖 {关键词} 在闲鱼上能卖什么，给我评分和前三个上架建议。
```

输出应该包含:

```text
需求名
目标买家
买家搜索词
证据链接和指标
WORTH 评分
可卖商品形态
首发标题
建议价格
交付内容
图片角度
风险边界
下一步素材缺口
```

### C. 从你的已有资产开始

适合把你积累的东西复利化，比如:

- Image2 案例库
- ComfyUI 工作流
- 电商带货视频矩阵
- AI 修图/高清修复
- AI 视频人物替换
- 网站/工具站
- Agent Skill

你可以这样说:

```text
我有这些资产: ...
帮我拆成 5 个闲鱼可卖商品，按 WORTH 排序，并选一个做上架包。
```

## 4. 需求挖掘方法

优先使用 Jina 搜索。

常用命令:

```powershell
python C:\Users\lsb\.codex\skills\jina-search\scripts\jina_search.py --timeout 45 search "OpenClaw 龙虾 Skill 部署 闲鱼"
python C:\Users\lsb\.codex\skills\jina-search\scripts\jina_search.py --timeout 45 read "https://example.com/page"
```

常用搜索词模板:

```text
闲鱼 {关键词} 教程
闲鱼 {关键词} 部署
site:goofish.com/item {关键词}
{关键词} 闲鱼 卖
{关键词} 工作流 下载
{关键词} 工作流 有分享吗
{关键词} 部署 教程 价格
{关键词} 必装 skill
{关键词} bilibili 工作流
{关键词} LiblibAI 工作流
{关键词} 报错 显存 节点缺失
男生 展示面 AI 照片
韩国棒球 抓拍 AI
AI 商品图 同款
AI 带货视频 矩阵
```

判断一个方向是否有需求，看这些信号:

| 信号 | 说明 |
| --- | --- |
| 评论里有人问“工作流有吗” | 有交付需求 |
| 有人问“电脑能跑吗/显存够吗” | 有排错和配置评估需求 |
| 竞品有“想要”数量 | 闲鱼已有购买意向 |
| B站/YouTube 高播放 | 热度正在外溢 |
| LiblibAI/ModelScope 下载/讨论多 | 工作流可卖，安装也可卖 |
| 你已有可交付资产 | 可复用，售后压力低 |

## 5. WORTH 评分模型

总分:

```text
score = heat + pain + asset_fit + reuse + price_power - risk
```

字段:

| 字段 | 含义 | 0 分 | 5 分 |
| --- | --- | --- | --- |
| `heat` | 热度证据 | 没证据 | 多平台近期热 |
| `pain` | 痛点强度 | 可有可无 | 买家卡住无法完成 |
| `asset_fit` | 资产匹配 | 你没有积累 | 你已有案例/流程/网站 |
| `reuse` | 复用程度 | 每单都重做 | 标准包可反复交付 |
| `price_power` | 客单价空间 | 只能低价 | 可低价引流+高价定制 |
| `risk` | 风险成本 | 基本无风险 | 合规/售后/平台风险高 |

优先级:

```text
18 分以上: 直接做首发商品
15-17 分: 做轻量测试
12-14 分: 做内容或组合包
12 分以下: 暂存
```

批量评分命令:

```powershell
python C:\Users\lsb\.codex\skills\xianyu-ai-demand-radar\scripts\score_opportunities.py D:\codex-work\xianyu\output\demand_radar\opportunities_2026-05-21.json --output D:\codex-work\xianyu\output\demand_radar\ranked_opportunities.md --format markdown
```

## 6. 商品产品化模板

每个方向都要先收敛成一个具体商品:

```text
需求名:
目标买家:
买家为什么会买:
买家搜索词:
首发标题:
展示价格:
套餐:
交付内容:
买家需要提供:
图片角度:
详情页第一段:
风险/边界话术:
售后边界:
```

常见商品形态:

| 商品形态 | 例子 |
| --- | --- |
| 低价资料/SOP | OpenClaw 必装 Skills 清单 |
| 工作流模板 | Wan2.2 Animate 工作流 |
| 远程部署 | Hermes / OpenClaw / ComfyUI 安装 |
| 定制服务 | 男生展示面 AI 套图 |
| 工具站入口 | Image2 案例库同款图 |
| 高价系统搭建 | 电商带货视频矩阵 |

## 7. 文案结构

闲鱼详情建议按这个顺序写:

```text
标题

痛点开场: 买家为什么卡住
我卖什么: 不是泛泛教程，而是具体交付

可做:
1. ...
2. ...
3. ...

套餐:
低价入口:
标准套餐:
推荐套餐:

下单前请发:
1. ...
2. ...
3. ...

说明:
密钥/账号/授权/效果边界
不承诺内容
```

标题公式:

```text
{热点词}{服务动作}｜{具体痛点}+{交付结果}
OpenClaw龙虾部署｜必装Skills配置报错排查
Wan2.2人物替换动作迁移｜ComfyUI工作流安装排错
Image2同款图生成｜1100+案例库免费试2张
```

## 8. 图片生成流程

推荐做法: Image2 生成无文字底图，本地叠中文卖点。

原因:

- Image2 直接生成中文容易乱码。
- 本地叠字更可控，适合闲鱼商品图。
- 底图有质感，文字有转化。

### 图片结构

建议 5-8 张:

| 图片 | 作用 |
| --- | --- |
| 01 首图 | 强钩子和价格入口 |
| 02 能力/案例 | 展示能做什么 |
| 03 套餐 | 价格阶梯 |
| 04 流程 | 下单步骤 |
| 05 场景 | 适用人群 |
| 06 要求/边界 | 减少售后纠纷 |

### RunningHub Image2 命令

先 dry-run:

```powershell
python C:\Users\lsb\.codex\skills\runninghub-image2-text\scripts\runninghub_image2_text.py --prompt-file D:\codex-work\xianyu\prompts\openclaw_image2_01_cover.txt --aspect-ratio 1:1 --resolution 2k --dry-run
```

提交并下载:

```powershell
python C:\Users\lsb\.codex\skills\runninghub-image2-text\scripts\runninghub_image2_text.py --prompt-file D:\codex-work\xianyu\prompts\openclaw_image2_01_cover.txt --aspect-ratio 1:1 --resolution 2k --wait --download-dir D:\codex-work\xianyu\output\openclaw_listing_pack\runninghub_raw
```

提示词建议:

```text
Create a premium square e-commerce service listing image background...
No readable text, no logos, no watermark.
Leave clean negative space for Chinese text overlay.
Realistic 3D product-ad style, sharp, professional, not cartoon.
```

### 后期叠字

OpenClaw 示例脚本:

```powershell
python D:\codex-work\xianyu\scripts\make_openclaw_image2_listing_pack.py
```

输出:

```text
D:\codex-work\xianyu\output\openclaw_listing_pack\images_image2
D:\codex-work\xianyu\output\openclaw_listing_pack\publish_config_image2.json
D:\codex-work\xianyu\publish_config_openclaw.json
```

## 9. 发布配置

发布配置 JSON 格式:

```json
{
  "title": "OpenClaw龙虾部署｜必装Skills配置报错排查",
  "body": "商品详情正文",
  "price": "9.9",
  "originalPrice": "199",
  "noShipping": true,
  "imagePaths": [
    "D:\\codex-work\\xianyu\\output\\openclaw_listing_pack\\images_image2\\01_Image2首图_OpenClaw龙虾部署.png"
  ]
}
```

要求:

- `imagePaths` 必须是 Windows 绝对路径。
- 图片建议 5-8 张。
- 数字商品/服务设置 `noShipping: true`。
- 标题不要太长，尽量保留核心关键词。

## 10. 闲鱼发布流程

打开或连接 Edge CDP:

```powershell
node C:\Users\lsb\.codex\skills\xianyu-product-publisher\scripts\goofish_publish_helper.js open --workspace D:\codex-work\xianyu
```

填充并上传:

```powershell
node C:\Users\lsb\.codex\skills\xianyu-product-publisher\scripts\goofish_publish_helper.js fill --workspace D:\codex-work\xianyu --config D:\codex-work\xianyu\publish_config_openclaw.json
```

检查页面:

```powershell
node C:\Users\lsb\.codex\skills\xianyu-product-publisher\scripts\goofish_publish_helper.js inspect --workspace D:\codex-work\xianyu
```

发布:

```powershell
node C:\Users\lsb\.codex\skills\xianyu-product-publisher\scripts\goofish_publish_helper.js publish --workspace D:\codex-work\xianyu --confirm-publish
```

注意:

- 发布前必须确认图片、标题、价格、正文都正确。
- 如果账号登录态掉出去了，发布页可能还停留在原页面，但下拉、按钮、类目选择会出现“能点 UI、改不动状态”的假活现象。遇到这种情况先重新登录，再刷新发布页并重新执行 `fill`，不要继续硬点。
- AI 图片/图文/ComfyUI 商品优先试 `AI图文工具/服务` 类目。当前可用字段组合: `计价方式=元/次`，`输入类型=文生图 + 图生图`，`功能类型=图片制作 + 图片修改`。这个类目网页端可以发布，但必须补齐三个字段。
- 如果网页端分类提示“不支持发布此分类”，先看按钮是否仍能发布；如果不能，换相近类目或用 APP 扫码继续。
- 如果 helper 超时但生成了 `goofish_publish_ready.png`，先看截图确认是否已填好。

## 11. 发布后记录

每次发布后保存:

```json
{
  "title": "商品标题",
  "url": "https://www.goofish.com/item?id=...",
  "price": "9.90",
  "publishedAt": "2026-05-21",
  "readyScreenshot": "填充截图",
  "publishedScreenshot": "发布后截图",
  "publishConfig": "发布配置路径",
  "imageDir": "图片目录"
}
```

OpenClaw 示例:

```text
商品: OpenClaw龙虾部署｜必装Skills配置报错排查
链接: https://www.goofish.com/item?id=1053188397667&categoryId=&spm=a21ybx.publish.0.0
记录: D:\codex-work\xianyu\output\openclaw_listing_pack\published_result.json
```

## 12. 每周复盘节奏

建议每周固定跑一次:

| 时间 | 动作 |
| --- | --- |
| 周一 | 搜新热点和竞品 |
| 周二 | 看评论和买家问题 |
| 周三 | 按 WORTH 打分 |
| 周四 | 做 1-3 个上架包 |
| 周五 | 发布并记录链接 |
| 周末 | 根据浏览、想要、私聊问题改标题/图/套餐 |

要重点记录:

- 哪个标题带来浏览。
- 买家第一句问什么。
- 是否有人直接问价格/交付。
- 哪些套餐没人问。
- 哪张图最像首图爆点。

## 13. 合规和边界话术

部署类:

```text
API Key 和账号授权由买家本人输入，我不代管密钥。
不同电脑配置、模型额度和网络环境会影响速度与效果。
不做批量骚扰、绕过风控、账号劫持等用途。
```

图像/视频类:

```text
只接买家本人或已授权素材。
不接公众人物、未授权换脸、擦边和侵权内容。
不承诺涨粉、必爆、包变现、包过审。
```

工作流类:

```text
工作流交付包含安装路径、节点说明、常见报错处理。
不提供盗版模型，模型许可和商用规则由买家自行确认。
```

## 14. 直接可复制的调用话术

挖需求:

```text
用 xianyu-ai-demand-radar 帮我挖 {方向} 的闲鱼需求，给我 10 个机会，按 WORTH 打分，选前三个适合上架的。
```

做上架包:

```text
把 {机会名} 做成闲鱼上架包，文案要真实、有爆点，价格分三档，图片用 RunningHub Image2 做底图再叠中文。
```

发布:

```text
用这份 publish_config 帮我填闲鱼发布页，上传图片，截图确认后发布。
```

复盘:

```text
帮我复盘这些已发布商品，根据浏览/想要/私聊问题，改标题、首图和套餐。
```

## 15. 当前已有案例

已发布:

| 商品 | 链接 |
| --- | --- |
| AI Agent/Skill 定制 | https://www.goofish.com/item?id=1054047380876 |
| AI短视频工作流模板 | https://www.goofish.com/item?id=1051401923934 |
| AI GEO优化诊断 | https://www.goofish.com/item?id=1052168586617 |
| AI短剧/漫剧前期包 | https://www.goofish.com/item?id=1051403251305 |
| DeepSeek/AI写作指令定制 | https://www.goofish.com/item?id=1053145077776 |
| OpenClaw龙虾部署 | https://www.goofish.com/item?id=1053188397667 |

这些案例可以作为以后继续扩展 Hermes、ComfyUI、Wan2.2、Image2、男生展示面、带货视频矩阵的样板。

## 16. 起号与流量运营并入流程

### 账号主心智

当前账号不要做成“什么都卖”的杂货号，最好收敛成:

```text
AI 工作流 / AI 部署 / AI 图片视频交付号
```

可以覆盖:

- OpenClaw / 龙虾部署和 Skills。
- Hermes / 赫妹 Agent 部署。
- ComfyUI 工作流、高清修复、人物替换、动作迁移。
- Image2 商品图、展示面、海报、电商主图。
- AI 自动化 Skill、网站/工具站、电商带货视频矩阵。

不要混入:

- 无关二手闲置。
- 低质虚拟资料搬运。
- 诱导站外、接码、群发、绕风控、侵犯隐私等高风险服务。

### 发布节奏

新号 / 重启号:

- 每天 2-3 个高质量商品。
- 连续跑 7 天自然流量。
- 每个商品对应不同搜索意图，不要只是换标题重复铺。

稳定后:

- 每天 3-5 个同垂类商品或变体。
- 围绕一个关键词簇扩展，比如 `OpenClaw部署`、`龙虾Skill`、`龙虾报错`、`低配电脑部署`。

不建议:

- 一天连续发 10-15 条以上同质商品。
- 短时间频繁上下架、删除重发、反复改标题主图。
- 直接复制别人的图和文案。

### 曝光策略

免费擦亮:

- 可以每天做。
- 它是短时刷新，不是核心增长点。

超级擦亮 / 付费曝光:

- 不要一上来就买。
- 只投已经有自然点击、想要、咨询的商品。
- 先小额测试 1 天，只看新增咨询成本，不只看曝光量。
- 投后没有咨询，先停，改首图、标题、价格和详情页。

### 每日动作表

| 时间 | 动作 |
| --- | --- |
| 早上 | 看昨天数据，选 2 个关键词，决定今天新链接 |
| 中午 | 发布 1 条新商品，擦亮已有商品，回复未完结咨询 |
| 晚上 7-9 点 | 发布第 2 条新商品，在线承接咨询，给套餐选择 |
| 睡前 | 记录买家问题，把高频问题变成下一条商品 |

## 17. 完整复利飞轮

这套工作流真正值钱的地方，不是单次发一个商品，而是每跑一次都会留下可复用资产。

```text
热点/竞品/买家问题
  -> 需求雷达搜索
  -> WORTH 打分
  -> 单品产品化
  -> RunningHub Image2 商品图
  -> Playwright 发布
  -> 买家咨询和成交
  -> 交付 SOP / FAQ / 案例
  -> 新商品变体
  -> 账号标签更稳定
  -> 下一轮流量和成交更容易
```

每一轮要沉淀 6 类资产:

| 资产 | 例子 | 复利用法 |
| --- | --- | --- |
| 需求资产 | 热点、竞品、买家问题 | 反复生成新商品角度 |
| 图像资产 | Image2 底图、叠字模板、案例图 | 换关键词即可复用成新图 |
| 文案资产 | 标题、详情、套餐、边界话术 | 快速改成同簇商品 |
| 交付资产 | SOP、脚本、工作流、报错处理 | 降低每单交付时间 |
| 证据资产 | 咨询截图、效果样片、发布链接 | 提升新链接信任感 |
| 数据资产 | 曝光、浏览、想要、咨询、成交 | 决定下一个商品做什么 |

## 18. 当前资产复利评级

评分口径:

```text
5 星 = 可长期复用，可拆多个商品，可从低价引流升级到高客单
4 星 = 可复用，但需要持续更新热点或案例
3 星 = 可卖，但人工交付占比偏高
2 星 = 偶发需求，适合测试
1 星 = 不建议当前主推
```

| 方向 | 复利程度 | 原因 | 当前动作 |
| --- | --- | --- | --- |
| Image2 案例库同款图 | 5 星 | 你已有 1100+ 案例库、免费试生成、能持续吸引作图需求 | 做成主引流入口 |
| OpenClaw / 龙虾部署 | 5 星 | 热点强、买家卡部署和 Skill、已发布首个商品 | 扩 3-5 个变体 |
| Hermes / 赫妹部署 | 5 星 | 可复用部署 SOP，可接 Telegram/私有助理/迁移 | 作为下一个部署商品 |
| ComfyUI 工作流合集 | 5 星 | 可拆高清修复、人物替换、商品图、动作迁移 | 做矩阵商品 |
| AI 自动化 Skill 定制 | 5 星 | 高客单、能沉淀脚本和案例，与你自己的 skill 体系强相关 | 做高价承接款 |
| 电商带货视频矩阵 | 5 星 | 工具化、模板化、商家愿意为效率付费 | 需要做样片和流程图 |
| Wan2.2 动作迁移/人物替换 | 4 星 | 热点强，但显卡、模型、授权和售后边界要控住 | 做工作流+远程排错 |
| 男生展示面 AI 套图 | 4 星 | 需求明确、容易传播，但人像授权和效果预期要管理 | 先做 9.9/29.9 样片款 |
| AI 高清修复/人像修图 | 4 星 | 稳定刚需，适合作为低价入口 | 做成快速成交款 |
| 网站/工具站成品交付 | 4 星 | 高客单，但售前沟通和定制占比高 | 放在咨询后转化 |
| AI GEO 优化诊断 | 3 星 | 概念较新，教育成本高 | 暂作测试款 |
| AI 短剧/漫剧前期包 | 3 星 | 可卖，但竞争和交付口径复杂 | 保留样板，少量迭代 |

整体判断:

```text
当前工作流复利程度: 4.5 / 5
```

扣掉的 0.5 主要来自两个风险:

- 闲鱼对虚拟服务、引导站外、夸大宣传比较敏感，标题和详情要稳。
- 高客单定制如果没有标准化问卷、套餐和交付边界，会吞掉时间。

## 19. 现在最值得跑的完整路径

建议先跑一个 14 天小周期:

### 第 1 阶段: 账号标签和锚点商品

目标: 让系统和买家都知道你是 AI 工作流服务号。

发布/保留这些锚点:

- OpenClaw 龙虾部署。
- Hermes 赫妹部署。
- Image2 案例库同款图。
- ComfyUI 工作流安装。
- AI 自动化 Skill 定制。
- 男生展示面 AI 套图。

### 第 2 阶段: 每天 2 条变体

每天结构:

- 1 条部署/工具类。
- 1 条图片/视频效果类。

示例:

```text
OpenClaw低配电脑部署方案
OpenClaw必装Skills清单
Hermes接Telegram私人助理
ComfyUI高清修复工作流
Image2商品图同款生成
韩国棒球抓拍AI图
```

### 第 3 阶段: 从咨询反推新品

买家问什么，就变成下一条商品:

| 买家问题 | 下一条商品 |
| --- | --- |
| 8G 显存能跑吗 | 低配电脑 ComfyUI/OpenClaw 方案 |
| Skill 怎么装 | 必装 Skill 配置包 |
| 能不能给我做同款图 | Image2 同款图生成 |
| 能不能替换视频人物 | 动作迁移/人物替换样片 |
| 公司能不能自动化 | AI 自动化 Skill 定制 |

### 第 4 阶段: 数据筛选和付费放大

24-72 小时看初筛:

- 曝光低: 换关键词。
- 点击低: 换首图。
- 咨询低: 换详情页和价格入口。
- 咨询高: 做套餐、做变体、小额投曝光。

## 20. 这套 workflow 的核心优势

你的优势不是“会发闲鱼”，而是有一条别人很难复制的链:

```text
热点嗅觉
+ Jina 需求雷达
+ Image2 案例库
+ RunningHub 出图
+ 自己的 Skill/脚本体系
+ Playwright 自动发布
+ 交付后的 SOP 沉淀
```

这条链越跑越强:

- 商品图会越来越快。
- 文案会越来越准。
- 咨询话术会越来越短。
- 交付会越来越标准化。
- 账号标签会越来越垂直。
- 买家问题会不断变成新的商品。

当前最该避免的是“看到什么火就都发”。正确路线是:

```text
一个账号心智
三条商品线
每天两条高质量新增
每周一次复盘
只给赢家买曝光
把每单交付沉淀成下一轮资产
```
