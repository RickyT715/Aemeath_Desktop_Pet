# Aemeath 桌面宠物

一款以《鸣潮》角色 **爱弥斯**（Aemeath）为主角的桌面宠物应用。她会在你的屏幕上飞来飞去、对鼠标做出反应、和你聊天，在你工作时陪伴你——还有她的黑猫和纸飞机相伴。

![.NET 8](https://img.shields.io/badge/.NET-8.0-purple) ![WPF](https://img.shields.io/badge/WPF-Windows-blue) ![License](https://img.shields.io/badge/license-MIT-green)

[English](README.md) | 中文

---

## 目录

- [快速开始](#快速开始)
- [操作与交互](#操作与交互)
- [功能详解](#功能详解)
  - [行为系统（26 状态 FSM）](#行为系统26-状态-fsm)
  - [属性系统](#属性系统)
  - [AI 聊天](#ai-聊天)
  - [气泡对话与闲聊](#气泡对话与闲聊)
  - [语音合成（TTS）](#语音合成tts)
  - [语音输入（按键说话）](#语音输入按键说话)
  - [截图支持](#截图支持)
  - [屏幕感知](#屏幕感知)
  - [黑猫伙伴](#黑猫伙伴)
  - [纸飞机系统](#纸飞机系统)
  - [粒子效果](#粒子效果)
  - [数字故障效果](#数字故障效果)
  - [窗口边缘停靠](#窗口边缘停靠)
  - [时间感知](#时间感知)
  - [全屏检测](#全屏检测)
  - [鼠标穿透模式](#鼠标穿透模式)
  - [系统托盘](#系统托盘)
  - [番茄钟 / 待办清单联动](#番茄钟--待办清单联动)
  - [活动监控联动](#活动监控联动)
  - [配套应用自动启动](#配套应用自动启动)
  - [随 Windows 启动](#随-windows-启动)
- [设置面板](#设置面板)
- [动画素材](#动画素材)
- [配置与数据文件](#配置与数据文件)
- [项目结构](#项目结构)
- [依赖项](#依赖项)
- [缺失素材与未实现功能](#缺失素材与未实现功能)
- [关于爱弥斯](#关于爱弥斯)

---

## 快速开始

### 环境要求

- **Windows 10/11**（x64）
- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)（编译用）或 [.NET 8 桌面运行时](https://dotnet.microsoft.com/download/dotnet/8.0)（运行发布版本）

### 安装 .NET 8 SDK

从官网下载：https://dotnet.microsoft.com/download/dotnet/8.0

或通过 winget 安装：
```
winget install Microsoft.DotNet.SDK.8
```

验证安装：
```
dotnet --version
```

### 编译并运行

**Windows（批处理）：**
```
run.bat
```

**手动运行：**
```
dotnet run --project src/AemeathDesktopPet
```

### 仅编译

```
dotnet build src/AemeathDesktopPet/AemeathDesktopPet.csproj
```

### 运行测试

```
dotnet test tests/AemeathDesktopPet.Tests/
```

### 发布（自包含）

```
dotnet publish src/AemeathDesktopPet/AemeathDesktopPet.csproj -c Release -r win-x64 --self-contained
```

输出位于 `src/AemeathDesktopPet/bin/Release/net8.0-windows/win-x64/publish/`。

---

## 操作与交互

### 鼠标操作

| 操作 | 效果 | 详情 |
|------|------|------|
| **左键单击** | 挥手动画 | 爱弥斯播放挥手打招呼的动画 |
| **悬停 2 秒** | 开心跳跃 | 将光标悬停在爱弥斯上方不要点击——她会开心地跳起来（心情 +5，好感度 +3） |
| **左键拖拽** | 拾取移动 | 按住左键可将爱弥斯拖到屏幕任意位置 |
| **快速拖拽 + 释放** | 抛掷 | 快速拖拽后松开——爱弥斯会带着速度飞出去，碰到屏幕边缘会反弹，然后在重力作用下落地 |
| **双击** | 打开聊天窗口 | 打开与爱弥斯的 AI 聊天窗口 |
| **右键单击** | 右键菜单 | 打开操作菜单（见下方） |

### 右键菜单

右键点击爱弥斯打开菜单：

| 选项 | 效果 | 详情 |
|------|------|------|
| **唱歌** | 唱歌动画 | 爱弥斯唱歌并释放音符粒子。需要在设置中配置音乐文件夹才能播放音频（心情 +8，体力 -5） |
| **和爱弥斯聊天** | 打开聊天窗口 | 与双击效果相同——打开 AI 聊天窗口 |
| **扔纸飞机** | 发射纸飞机 | 爱弥斯抛出一架纸飞机，划过屏幕。黑猫可能会去追（心情 +2，体力 -2） |
| **呼唤小猫** | 召唤伙伴 | 黑猫跑到爱弥斯身边（需在设置中启用黑猫） |
| **爱弥斯怎么样？** | 属性弹窗 | 显示心情、体力和好感度进度条以及累计互动数据 |
| **设置** | 设置面板 | 打开 6 个标签页的设置窗口 |
| **回头见！** | 隐藏宠物 | 将爱弥斯（和黑猫）从屏幕上隐藏。她仍在系统托盘中——双击托盘图标即可唤回 |
| **退出** | 退出程序 | 完全关闭应用。如果启用了"关闭到托盘"，需要用此选项才能真正退出 |

### 系统托盘操作

| 操作 | 效果 |
|------|------|
| **双击托盘图标** | 显示/隐藏宠物 |
| **右键托盘图标** | 托盘菜单（显示、切换鼠标穿透、设置、退出） |

### 键盘操作

| 操作 | 效果 | 详情 |
|------|------|------|
| **按键说话快捷键**（默认：`Ctrl+F2`） | 语音输入 | 按住录音，松开发送。需在设置中启用语音输入 |

---

## 功能详解

### 行为系统（26 状态 FSM）

爱弥斯的行为由一个 **26 状态有限状态机** 驱动，采用加权随机转换。每约 1 秒，引擎会根据以下因素评估是否切换状态：

- **基础权重** — 每个状态有默认概率（如飞行：15，唱歌：5，睡觉：1）
- **属性修正** — 心情、体力和时间段会动态调整权重
- **触发条件** — 部分状态仅在特定条件下触发

#### 全部 26 种状态

| 类别 | 状态 | 说明 |
|------|------|------|
| **核心** | 待机、左飞、右飞、下落、着陆 | 基本移动和休息 |
| **互动** | 拖拽、抛掷、挥手、开心、大笑 | 用户触发的反应 |
| **个性** | 唱歌、玩游戏、叹气、注视用户、睡觉 | 自主行为 |
| **社交** | 聊天、纸飞机、猫咪依偎、抚摸猫咪 | 互动与伙伴状态 |
| **窗口** | 探头、趴在窗口上、藏在任务栏、攀附边缘 | 窗口边缘交互 |
| **特殊** | 故障、朗读、屏幕评论 | 数字特效和语音 |

#### 动态权重示例

| 条件 | 效果 |
|------|------|
| 心情 < 50 | 叹气权重翻倍（更多忧郁表现） |
| 心情 > 70 | 大笑权重增加 1.5 倍 |
| 体力 < 30 | 睡觉权重提升至 5；玩游戏和唱歌被禁用 |
| 体力 < 20 | 玩游戏被禁用 |
| 体力 < 15 | 唱歌被禁用 |
| 夜间（21:00–5:59） | 睡觉状态可用 |
| 心情 < 20 | 唱歌被禁用（太难过了唱不出来） |
| 番茄钟工作模式 | 唱歌被抑制（专注时不会自动唱歌） |
| 未设置音乐文件夹 | 唱歌被抑制（没有可播放的音乐） |

每个状态有随机持续时间（如唱歌：5–15 秒，睡觉：8–20 秒）。拖拽、聊天和睡觉等状态由用户驱动，不会自动切换。

---

### 属性系统

爱弥斯有三项核心属性，跟踪她的情绪状态。它们影响行为、对话和动画。

#### 属性概览

| 属性 | 范围 | 默认值 | 影响内容 |
|------|------|--------|----------|
| **心情** | 0–100 | 70 | 行为权重（高心情多笑、低心情多叹气）、对话语气 |
| **体力** | 0–100 | 80 | 可用活动（体力低时无法唱歌、玩游戏）、睡觉倾向 |
| **好感度** | 0–100 | 50 | 长期羁绊指标、问候语的亲密程度 |

#### 属性变化方式

**交互（即时效果）：**

| 动作 | 心情 | 体力 | 好感度 |
|------|------|------|--------|
| 与爱弥斯聊天 | +3 | — | +2 |
| 抚摸（悬停 2 秒） | +5 | — | +3 |
| 唱歌 | +8 | -5 | — |
| 扔纸飞机 | +2 | -2 | — |
| 玩游戏 | +6 | -8 | — |
| 番茄钟工作完成 | +3 | — | — |

**运行时衰减（每 5 分钟）：**
- 体力：-1
- 心情：向 50 趋近（每次 ±0.5）

**离线衰减（应用关闭时）：**

| 属性 | 前几小时 | 之后 | 最低值 |
|------|----------|------|--------|
| 心情 | -5/小时（前 4 小时） | -2/小时 | 30 |
| 体力 | -3/小时（前 6 小时） | -1/小时 | 20 |
| 好感度 | -1/小时（前 12 小时） | -0.5/小时 | 40 |

**累计计数器**：总聊天次数、总抚摸次数、总唱歌次数、总纸飞机次数、总游戏次数、相伴天数。

#### 查看属性

右键爱弥斯 > **"爱弥斯怎么样？"** 查看各属性渐变进度条和累计数据。

---

### AI 聊天

双击爱弥斯或使用右键菜单打开聊天窗口。支持两种 AI 服务：

#### Claude（Anthropic）

1. 从 [console.anthropic.com](https://console.anthropic.com/) 获取 API 密钥
2. 打开 **设置**（右键 > 设置）> **AI** 标签页
3. 选择 **Claude** 作为服务商
4. 输入 API 密钥

#### Gemini（Google）

1. 从 [aistudio.google.com](https://aistudio.google.com/) 获取 API 密钥
2. 打开 **设置** > **AI** 标签页
3. 选择 **Gemini** 作为服务商
4. 输入 API 密钥

#### 离线模式

没有 API 密钥时，聊天使用 **75 条以上的预编写角色台词**，具有上下文感知：
- **时间段** — 早上打招呼、深夜困倦回复
- **心情** — 开心反应与忧郁台词
- **体力** — 体力低时的困倦回复
- **离开时长** — 长时间不在后的"你去哪了？"台词

#### 聊天功能

- **流式响应** — AI 文字在聊天窗口中逐字显示
- **角色人格** — 系统提示词维持爱弥斯的性格（活泼、数字幽灵、热爱唱歌）
- **聊天历史** — 最近 200 条消息跨会话保存
- **TTS 集成** — 启用 TTS 时 AI 回复会被朗读出来
- **截图支持** — 在消息中附带截图提供视觉上下文

---

### 气泡对话与闲聊

爱弥斯在空闲时会定期显示带有主题对话的气泡。

- **按场景可配置频率**：每种活动场景有独立的说话频率预设
- **打字机效果**：文字逐字显示
- **持续时间**：每个气泡停留约 5 秒

气泡在以下状态时**被抑制**：拖拽、抛掷、下落、聊天、睡觉、朗读。

#### 说话频率（按场景配置）

爱弥斯的闲聊频率会自动适应你当前的活动。系统检测六种活动场景，每种均可配置四种频率预设。

**活动场景：**

| 场景 | 默认预设 | 检测方式 |
|------|----------|----------|
| 番茄钟工作 | 静默 | 番茄钟工作模式激活 |
| 番茄钟休息 | 频繁 | 番茄钟休息模式激活 |
| 游戏 | 偶尔 | 进程名（Steam、Epic、原神等）+ 域名 |
| 看视频 | 偶尔 | 域名（YouTube、Twitch、B站、Netflix 等） |
| 学习 / 编程 | 正常 | 进程名（VS Code、DevEnv 等）+ 域名（GitHub、StackOverflow 等） |
| 默认 / 空闲 | 正常 | 未检测到特定活动时的回退 |

**频率预设：**

| 预设 | 间隔 | 说明 |
|------|------|------|
| 静默 | — | 不闲聊 |
| 偶尔 | 2–4 分钟 | 最少打扰 |
| 正常 | 45–90 秒 | 标准闲聊 |
| 频繁 | 15–30 秒 | 高频对话 |

**优先级：** 番茄钟状态 > 活动检测 > 默认

**配置方式：** 设置 > 常规 > 说话频率。每种场景有下拉菜单可选择预设。

> **注意：** 游戏、视频和学习/编程的检测需要启用活动监控并配置有效的数据库路径。

---

### 语音合成（TTS）

提供五种 TTS 服务。在 **设置** > **语音** 标签页中配置。

#### Edge TTS（默认 — 免费）

通过 WebSocket 使用微软 Edge 神经网络语音。**无需 API 密钥。**

- 默认语音：`en-US-AvaMultilingualNeural`
- 300 多种语音，涵盖多种语言
- 热门中文语音：`zh-CN-XiaoxiaoNeural`（晓晓）、`zh-CN-YunxiNeural`（云希）、`zh-CN-YunyangNeural`（云扬）
- 英文语音：`en-US-AvaMultilingualNeural`、`en-US-JennyNeural` 等

**使用方法：** 在设置 > 语音标签页选择"Edge TTS"，输入准确的语音名称。

> **注意：** Edge_tts_sharp v1.1.7 中 `Edge_tts.Await = true` 存在 bug——库的回调不会触发。程序使用 `Await = false` 配合 `ManualResetEventSlim` 来正确等待。

#### GPT-SoVITS（本地）

连接本地 [GPT-SoVITS](https://github.com/RVC-Boss/GPT-SoVITS) 服务器进行自定义声音克隆。
支持**模型配置文件**，可在多个训练模型间切换。

**前置条件：**
- 已安装 Python 3.9+
- 建议使用 NVIDIA 显卡（CUDA）；CPU 推理可用但速度较慢
- 已训练好的 GPT-SoVITS 模型（`.ckpt` + `.pth` 权重文件）及一段简短的参考音频

**服务器部署：**
1. 克隆或下载 [GPT-SoVITS](https://github.com/RVC-Boss/GPT-SoVITS)
2. 安装依赖：`pip install -r requirements.txt`
3. 启动 **API 服务器**（不是 WebUI）：
   ```bash
   python api_v2.py -a 127.0.0.1 -p 9880
   ```
   服务器默认监听 `http://localhost:9880`。
   > **提示：** 如果服务器运行在局域网内的其他机器上，使用 `-a 0.0.0.0`。

**桌面宠物配置：**
1. 打开 **设置** > **语音** 标签页
2. 选择 **GPT-SoVITS** 作为 TTS 服务商
3. 确认服务器地址（默认：`http://localhost:9880`）

**模型配置文件：**
1. 点击 **添加** 创建配置文件
2. 配置项：
   - **GPT 权重路径**（`.ckpt`）— **服务器机器上**的完整路径
   - **SoVITS 权重路径**（`.pth`）— **服务器机器上**的完整路径
   - **参考音频** — 目标声音的短音频片段（3-10 秒，发音清晰）
   - **提示文本** — 参考音频的精确文字转录
   - **提示 / 文本语言** — 自动、中文、英文、日文或韩文
   - **语速** — 0.5 倍到 2.0 倍
3. 从下拉列表选择配置文件激活

> 所有文件路径（权重、参考音频）在 **GPT-SoVITS 服务器端**解析，而非桌面宠物所在机器。
> 如果两者在同一台电脑上运行，请使用绝对路径，例如 `D:\GPT-SoVITS\models\my_model.ckpt`。

激活配置文件后，程序会自动调用 `/set_gpt_weights` 和 `/set_sovits_weights` 加载模型。选择 *"（无配置文件 - 传统模式）"* 使用服务器当前已加载的默认模型。

#### ElevenLabs（云端）

高质量云端 TTS，提供多种音色选择。

1. 从 [elevenlabs.io](https://elevenlabs.io/) 获取 API 密钥
2. 在设置中输入 API 密钥和音色 ID
3. 选择"ElevenLabs"作为 TTS 服务商

#### Fish Audio（云端）

通过 [Fish Audio](https://fish.audio/) 实现云端声音克隆与语音合成。支持零样本声音克隆，只需一段简短的参考音频，无需训练模型。

1. 从 [fish.audio](https://fish.audio/) 获取 API 密钥
2. **（可选）** 在 Fish Audio 上传参考音频创建声音模型，复制模型 ID
3. 在 **设置** > **语音** 标签页输入 API 密钥和模型 ID
4. 选择"Fish Audio"作为 TTS 服务商

> API 地址默认为 `https://api.fish.audio`。仅在自部署 Fish Speech 服务器时需要修改。

#### OpenAI TTS（云端）

通过 OpenAI API 实现简洁的云端语音合成。13 种预设音色，无声音克隆功能。

1. 从 [platform.openai.com](https://platform.openai.com/) 获取 API 密钥
2. 在 **设置** > **语音** 标签页输入 API 密钥
3. 选择模型（`tts-1`、`tts-1-hd` 或 `gpt-4o-mini-tts`）和音色
4. 选择"OpenAI TTS"作为 TTS 服务商

可用音色：`alloy`、`ash`、`coral`、`echo`、`fable`、`onyx`、`nova`、`sage`、`shimmer`。
语速可调范围：0.25 倍到 4.0 倍。

#### TTS 功能一览

| 功能 | 说明 |
|------|------|
| **自动朗读聊天** | 启用 TTS 后 AI 聊天回复会被朗读 |
| **自动朗读闲聊** | 气泡对话可选择性朗读（默认关闭） |
| **全屏自动静音** | 全屏应用活跃时 TTS 静音（可配置） |
| **队列系统** | 语音排队通过 NAudio 逐条播放 |
| **发送新消息时停止** | 发送新聊天消息会取消当前朗读 |
| **格式检测** | 自动处理 MP3（Edge TTS、ElevenLabs、OpenAI）和 WAV（GPT-SoVITS、Fish Audio） |
| **音量控制** | 在设置中调节，范围 0–100% |

#### 测试 TTS

包含独立的集成测试控制台应用：

```
dotnet run --project tests/TtsIntegrationTest
```

依次测试全部 5 种服务商。设置对应 API 密钥环境变量以包含云端服务商测试。

---

### 语音输入（按键说话）

录制语音消息并发送给 AI 聊天。

**配置步骤：**
1. 在 **设置** > **语音** 标签页中启用语音输入
2. 选择 STT 服务商：**Whisper**（OpenAI）或 **Gemini**（Google）
3. 输入所选服务商的 API 密钥
4. 设置按键说话快捷键（默认：`Ctrl+F2`）
5. 可选启用截图附件

**使用方法：**
1. 按住快捷键开始录音（出现麦克风图标）
2. 说出你的消息
3. 松开快捷键——音频被转录并作为聊天消息发送
4. 如果启用了截图，屏幕截图会自动附带

**STT 服务商：**

| 服务商 | 需要 API 密钥 | 备注 |
|--------|---------------|------|
| Whisper（OpenAI） | 是（OpenAI 密钥） | 准确，支持多种语言 |
| Gemini（Google） | 复用 Gemini 密钥 | 使用 AI 聊天的 Gemini 密钥 |

**支持语言：** 英语、中文、日语、韩语、西班牙语、法语、德语。

---

### 截图支持

在聊天消息中附带截图提供视觉上下文。

- **语音输入时**：在语音设置中启用"包含截图"——松开按键说话时自动截取屏幕
- **文字聊天时**：使用聊天窗口中的截图按钮截取并附带

截图以 JPEG 格式保存并缩放，优化 API 传输效率。

---

### 屏幕感知

爱弥斯可以定期截取屏幕截图，通过视觉 AI 分析你在做什么，然后通过气泡对话评论。

#### 工作原理

1. 后台计时器每 60 秒截取一次屏幕（可配置）
2. **第 1 层隐私保护**：如果前台应用在黑名单中（如 KeePass、银行网站），则跳过截图
3. **变化检测**：感知哈希比较当前截图与上一张，如果屏幕没有明显变化（汉明距离 < 10）则跳过
4. **预算检查**：如果月度花费估计超过配置上限，则跳过截图
5. 截图发送给配置的视觉 AI（Gemini Flash 或 Claude），附带隐私保护分析提示词
6. AI 生成简短的角色化观察（1-2 句话）
7. 下一次闲聊计时器触发时获取缓存的评论，显示为气泡对话

#### 隐私管线

| 层级 | 保护 | 说明 |
|------|------|------|
| **第 1 层** | 应用黑名单 | 可配置的应用/标题模式列表，阻止截图（如 `keepass.exe`、`chrome.exe:*bank*`） |
| **第 3 层** | 隐私提示词 | AI 被明确指示不要读取或重复屏幕上的具体文字、数字、名称、密码或可识别信息 |

#### 费用估算

| 服务商 | 每 1,000 张截图费用 | 月度（8小时/天，1/分钟） |
|----------|---------------------------|--------------------------|
| **Gemini 2.5 Flash** | ~$0.04 | ~$0.38/月（去重后） |
| Claude Haiku 4.5 | ~$1.33 | ~$12/月 |

默认服务商为 Gemini Flash，成本效率最优。可配置月度预算上限（默认：$5）防止超支。

#### 视觉指示器

屏幕感知激活时，爱弥斯附近会显示一个小徽章：**"👁 Aemeath can see"**。可在设置中关闭。

#### 配置

1. 打开 **设置** > **屏幕** 标签页
2. 勾选“启用屏幕感知”
3. 选择视觉服务商（推荐 Gemini Flash）
4. 输入视觉 API 密钥
5. 可选调整间隔、预算上限和黑名单

### 黑猫伙伴

一只黑猫在独立窗口中跟随爱弥斯在屏幕上活动。

#### 猫咪行为

黑猫拥有独立运行的 **12 状态 FSM**：

| 状态 | 说明 |
|------|------|
| **猫咪待机** | 静坐观察 |
| **猫咪走路** | 向爱弥斯走去 |
| **猫咪打盹** | 小憩中 |
| **猫咪梳毛** | 自我梳理 |
| **猫咪扑击** | 扑向某物 |
| **猫咪观察** | 警觉地注视爱弥斯 |
| **猫咪蹭蹭** | 蹭爱弥斯 |
| **猫咪受惊** | 受到惊吓 |
| **猫咪呼噜** | 满足地打呼噜 |
| **猫咪栖息** | 停在栖息处 |
| **猫咪追逐** | 追逐纸飞机 |
| **猫咪拍打** | 拍打某物 |

**行为细节：**
- **跟随爱弥斯**，水平偏移 40–80 像素，垂直偏移 10–30 像素
- **平滑移动** — 向目标位置插值移动
- **对事件做出反应** — 拖拽时受惊、追逐纸飞机、抚摸时呼噜
- **独立窗口** — 使用独立的透明 WPF 窗口实现独立移动

**自定义**（设置 > 外观）：
- 启用/禁用黑猫伙伴
- 设置猫咪名字（默认："Kuro"）

> **注意：** 目前使用 Unicode 表情符号占位。12 种状态的 GIF 素材已规划但尚未创建。

---

### 纸飞机系统

纸飞机有两种出现方式：

#### 环境纸飞机（自动）

- 从屏幕边缘随机间隔生成
- **默认频率**：每 5 分钟（随机 3–8 分钟）
- **可配置**：在设置 > 外观中选择 3、5、8 或 10 分钟
- **轨迹**：缓慢水平漂移 + 轻柔下沉 + 正弦波晃动
- **生命周期**：20 秒后自动消失

#### 抛出纸飞机（用户触发）

- 右键 > **"扔纸飞机"**
- 爱弥斯进入纸飞机状态并抛出一架飞机
- **物理效果**：抛物线轨迹 + 重力（20 像素/秒²）+ 晃动
- **速度**：水平 80–140 像素/秒，向上弧线
- **猫咪反应**：黑猫会追逐落地的纸飞机（触发追逐状态）

> **注意：** 目前使用 Unicode 飞机符号（✈）。素材资源已规划。

---

### 粒子效果

各种交互中出现的视觉粒子效果：

| 粒子 | 符号 | 出现时机 |
|------|------|----------|
| **音符** | ♪ | 唱歌时 |
| **爱心** | ♥ | 被抚摸时（悬停 2 秒） |
| **闪光** | ✦ | 番茄钟工作完成、特殊事件 |
| **睡眠 Z** | Z | 睡觉状态时 |
| **爪印** | 🐾 | 猫咪相关交互 |
| **毛团** | • | 猫咪梳毛/受惊 |

**物理效果**：粒子以随机偏移生成，在轻微重力下向上飘浮，约 1–2 秒后淡出。屏幕上最多同时显示 12 个粒子。

---

### 数字故障效果

爱弥斯是数字幽灵，她的形象偶尔会发生故障——微妙地提醒着她的本质。

- **触发**：每 5–10 秒有 2–5% 的随机概率
- **持续时间**：300–800 毫秒
- **视觉效果**：
  - **RGB 通道分离** — 色彩通道水平分离
  - **水平切片位移** — 图像切片随机偏移
  - **透明度闪烁** — 透明度快速变化
- **开关**：在设置 > 外观中启用/禁用
- **可强制触发**：某些事件（如特殊交互）会触发故障

---

### 窗口边缘停靠

爱弥斯可以与桌面上的其他窗口互动。

- **检测**：每 500 毫秒检查附近的窗口标题栏（30 像素范围内）
- **停靠状态**：`探头`、`趴在窗口上`、`藏在任务栏`、`攀附边缘`
- **屏幕边缘**：检测靠近左/右/上边缘（20 像素）和任务栏（10 像素）
- **窗口追踪**：当爱弥斯停靠的窗口被关闭时，她会做出反应（掉落或飞走）
- **适用于**：桌面上任何可见的非隐藏窗口

---

### 时间感知

爱弥斯知道现在几点，并据此调整行为。

| 时间段 | 时间 | 效果 |
|--------|------|------|
| **早晨** | 6:00–11:59 | 启动时显示早安问候 |
| **白天** | 12:00–16:59 | 正常行为 |
| **傍晚** | 17:00–20:59 | 正常行为 |
| **夜晚** | 21:00–23:59 | 睡觉状态可用，困倦问候 |
| **深夜** | 0:00–5:59 | 睡觉状态可用，关心的"你还没睡？"台词 |

- **问候选择**：启动问候匹配当前时间段
- **睡觉行为**：仅在夜晚/深夜触发，或体力低于 30 时
- **闲聊内容**：对话与当前时间段相关

---

### 全屏检测

爱弥斯知道你在看视频还是玩游戏。

- **自动隐藏**：检测到全屏应用时爱弥斯（和黑猫）自动隐藏
- **自动显示**：退出全屏后重新出现
- **TTS 静音**：启用"全屏自动静音"时，全屏应用期间 TTS 被静音
- **检测方式**：检查前台窗口是否覆盖整个屏幕（排除 Windows Shell/桌面）

---

### 鼠标穿透模式

使爱弥斯变成纯视觉效果——鼠标点击穿透她到达下方的窗口。

- **切换**：右键**系统托盘图标** > "切换鼠标穿透"
- **效果**：爱弥斯和黑猫窗口都变为不可交互
- **视觉提示**：出现幽灵般的半透明覆盖层作为提醒
- **托盘提示**：气泡提示提醒你如何切换回来
- **实现方式**：使用 Win32 `WS_EX_TRANSPARENT` 窗口样式

> **提示**：要恢复交互，右键**系统托盘图标**关闭鼠标穿透。

---

### 系统托盘

爱弥斯常驻系统托盘，方便随时访问。

- **最小化到托盘**：启用"关闭到托盘"时（默认开启），关闭窗口会将爱弥斯隐藏到托盘而不是退出
- **双击托盘图标**：显示/隐藏宠物
- **右键托盘图标**：菜单包含显示、切换鼠标穿透、设置、退出
- **随时可用**：即使隐藏了，爱弥斯只需一次点击即可唤回

---

### 番茄钟 / 待办清单联动

爱弥斯通过 Windows 命名管道对配套的**待办清单 / 番茄钟计时器**（Electron 应用）的事件做出反应。

#### LLM 驱动的回复

当配置了 AI 服务商（Claude 或 Gemini）时，番茄钟事件消息由 **LLM 实时生成** — 爱弥斯每次都会说出独特且有上下文关联的内容，而非重复预编写的台词。如果未配置 API 密钥或 LLM 调用失败，系统会优雅回退到预编写的离线回复。

- LLM 调用使用空聊天历史（独立反应，不属于正在进行的对话）
- 回复不会保存到聊天记录
- 提示词包含事件上下文（任务标题、时长、休息类型）
- **提示词模板完全可自定义**，在设置 > 常规 > LLM 提示词模板中修改
- 模板支持 `{taskTitle}`、`{duration}`、`{breakType}` 占位符
- 提供"恢复默认"按钮

#### 事件反应

| 事件 | 宠物反应 |
|------|----------|
| **工作时段开始** | LLM 生成的鼓励（或离线回退）+ 开心动画 |
| **工作时段结束** | LLM 生成的庆祝（或离线回退）+ 闪光粒子 + 心情提升（+3）+ TTS 朗读 |
| **休息开始** | LLM 生成的聊天（或离线回退）+ TTS 朗读，闲聊变得更频繁 |
| **休息结束** | LLM 生成的激励（或离线回退） |
| **添加任务** | LLM 生成的反应，提及任务标题（或离线回退） |
| **工作期间** | 闲聊完全静默（安静专注模式） |

#### 配置

默认启用。两个应用自动检测对方——只需同时启动即可。

- **开关**：设置 > 常规 > 集成 > "连接到待办清单 / 番茄钟计时器"
- **需要重启**：更改此设置需要重启桌面宠物
- **无需配置**：管道名称固定为 `AemeathDesktopPet`

#### 工作原理

- **协议**：单向命名管道（`\\.\pipe\AemeathDesktopPet`），换行分隔的 JSON
- **桌面宠物**：运行管道服务器（始终监听）
- **待办清单**：作为客户端连接，自动重连（5 秒重试）
- **方向**：单向（待办清单 → 桌面宠物）

---

### 活动监控联动

爱弥斯可以读取**电脑与浏览器活动监控**应用的 SQLite 数据库中的近期活动数据，使她的闲聊和番茄钟反应能够关联你实际在做的事情。

#### 工作原理

- 以只读方式读取监控数据库中的 `window_sessions` 和 `chrome_sessions` 表
- 按应用/域名分组，按时长排序
- 生成简洁的摘要，如：*"你花了 12 分钟在 VS Code，8 分钟在 github.com，5 分钟在 stackoverflow.com"*
- **摄像头状态感知**：同时读取 `attention_sessions` 表获取人脸检测、情绪识别、注意力评分和走神检测数据——生成用户状态摘要，如：*"主要情绪：开心。注意力：0.72。注视屏幕：85%。2 次走神事件。"*
- 活动摘要和用户状态均包含在 AI 提示词中，使爱弥斯能够评论你的活动和身体状态

#### 联动场景

| 场景 | 行为 |
|------|------|
| **闲聊** | 当 AI 可用时，闲聊气泡会引用你的活动和身体状态（情绪、注意力等） |
| **番茄钟工作结束** | AI 提示词包含整个工作时段的活动内容和身体状态 |
| **其他番茄钟事件** | AI 提示词包含最近 5 分钟的活动和摄像头数据作为上下文 |
| **无数据 / 数据库不可用** | 优雅回退到正常的离线回复 |

#### 配置

1. 安装并运行电脑与浏览器活动监控应用
2. 打开 **设置** > **常规** > **活动监控**
3. 勾选"在爱弥斯的对话中包含近期活动"
4. 设置数据库路径（默认：`D:\Study\Project\Computer_and_Chrome_Monitor_with_AI_Analysis\data\monitor.db`）
5. 确保在 AI 标签页中配置了 AI 服务商（Claude 或 Gemini）

> **注意：** 数据库以只读模式打开——桌面宠物永远不会修改监控数据。

---

### 配套应用自动启动

桌面宠物可以在启动时自动启动两个配套程序，无需每次手动打开。

#### 支持的配套应用

| 程序 | 说明 | 默认路径 |
|------|------|----------|
| **电脑与浏览器活动监控** | 活动跟踪（窗口/浏览器会话、摄像头注意力数据） | `...\run.bat` |
| **待办清单 / 番茄钟计时器** | 任务管理和番茄钟，与宠物联动 | `...\run.bat` |

#### 配置

1. 打开 **设置** > **常规** > **配套应用**
2. 勾选想要自动启动的程序
3. 确认或浏览到正确的可执行文件/批处理文件路径
4. 保存——下次宠物启动时配套应用会自动启动

#### 行为

- **防重复启动**（exe 文件）：如果配套应用已在运行，不会启动第二个实例
- **批处理文件支持**：`.bat` 文件通过 `UseShellExecute` 启动（支持 `run.bat` → `npm start` 链式调用）
- **静默失败**：如果配套应用启动失败（路径错误、文件缺失），宠物正常继续运行
- **启动顺序**：配套应用在主宠物窗口之前启动，给它们初始化的时间

---

### 随 Windows 启动

在 **设置** > **常规** 中启用"随 Windows 启动"，让桌面宠物在登录时自动启动。

- 使用 Windows 注册表（`HKCU\Software\Microsoft\Windows\CurrentVersion\Run`）——无需管理员权限
- 保存时立即生效
- 与配套应用自动启动配合使用，三个应用可以在登录时一起启动

---

## 设置面板

通过右键 > **设置** 或系统托盘菜单打开。按类别分为六个标签页：

### 标签页 1：常规

| 设置 | 默认值 | 说明 |
|------|--------|------|
| 随 Windows 启动 | 关闭 | 开机自动启动（保存时写入注册表） |
| 关闭到系统托盘 | 开启 | 关闭窗口时隐藏到托盘而非退出 |
| 启动时启动监控 | 关闭 | 宠物启动时自动启动电脑与浏览器活动监控 |
| 监控路径 | （默认） | run.bat（或 ComputerMonitor.exe）的路径 |
| 启动时启动待办清单 | 关闭 | 宠物启动时自动启动待办清单 / 番茄钟计时器 |
| 待办清单路径 | （默认） | 待办清单的 run.bat 或可执行文件路径 |
| 行为频率 | 正常 | 爱弥斯的活跃程度：安静、正常或活跃 |
| 番茄钟集成 | 开启 | 连接到待办清单 / 番茄钟计时器（需重启） |
| LLM 提示词模板 | （默认） | 自定义 5 个番茄钟事件提示词模板（启用集成时可见）。支持 `{taskTitle}`、`{duration}`、`{breakType}` 占位符 |
| 活动监控 | 关闭 | 在爱弥斯的 AI 生成对话中包含近期电脑活动 |
| 活动监控数据库路径 | （默认路径） | 电脑与浏览器活动监控的 SQLite 数据库路径 |
| 说话频率 | （按场景默认） | 配置爱弥斯在 6 种活动场景下的说话频率：番茄钟工作（静默）、番茄钟休息（频繁）、游戏（偶尔）、视频（偶尔）、学习/编程（正常）、默认（正常） |

### 标签页 2：外观

| 设置 | 默认值 | 说明 |
|------|--------|------|
| 宠物大小 | 正常（200px） | 小（150px）、正常（200px）或大（250px） |
| 透明度 | 100% | 宠物透明度（30–100%） |
| 启用数字故障效果 | 开启 | 随机 RGB 分离/闪烁效果 |
| 启用黑猫伙伴 | 开启 | 显示猫咪伙伴 |
| 猫咪名字 | "Kuro" | 猫咪的显示名称 |
| 启用环境纸飞机 | 开启 | 纸飞机从屏幕边缘飘入 |
| 纸飞机频率 | 5 分钟 | 环境纸飞机出现频率（3、5、8 或 10 分钟） |

### 标签页 3：音乐

| 设置 | 默认值 | 说明 |
|------|--------|------|
| 音乐文件夹 | （空） | 歌曲文件夹路径。爱弥斯唱歌时随机播放 |
| 歌曲数量 | 自动 | 显示在文件夹中找到的歌曲数量 |

浏览选择文件夹。爱弥斯会扫描其中的音频文件，在唱歌状态时随机播放。

### 标签页 4：AI

| 设置 | 默认值 | 说明 |
|------|--------|------|
| AI 服务商 | Claude | 在 Claude（Anthropic）和 Gemini（Google）之间选择 |
| Claude API 密钥 | （空） | 你的 Anthropic API 密钥 |
| Gemini API 密钥 | （空） | 你的 Google AI Studio API 密钥 |

API 密钥保存在本地 `config.json` 中。没有密钥时聊天回退到离线脚本回复。

### 标签页 5：语音

**语音输入（STT）：**

| 设置 | 默认值 | 说明 |
|------|--------|------|
| 启用语音输入 | 关闭 | 激活按键说话功能 |
| STT 服务商 | Whisper | Whisper（OpenAI）或 Gemini（Google） |
| Whisper API 密钥 | （空） | OpenAI API 密钥（仅选择 Whisper 时显示） |
| 语言 | 英语 | 识别语言（en、zh、ja、ko、es、fr、de） |
| 包含截图 | 关闭 | 每条语音消息附带截图 |
| 按键说话快捷键 | Ctrl+F2 | 点击输入框后按下你想要的组合键 |

**语音合成：**

| 设置 | 默认值 | 说明 |
|------|--------|------|
| 启用 TTS | 关闭 | 激活语音合成 |
| 服务商 | Edge TTS | Edge TTS（免费）、GPT-SoVITS（本地）或 ElevenLabs（云端） |
| Edge TTS 语音 | en-US-AvaMultilingualNeural | 语音名称（300+ 可选） |
| GPT-SoVITS 地址 | http://localhost:9880 | 本地服务器地址 |
| GPT-SoVITS 配置文件 | — | 管理模型配置文件（添加/删除，含权重/音频/语言） |
| ElevenLabs API 密钥 | （空） | ElevenLabs API 密钥 |
| ElevenLabs 音色 ID | 21m00Tcm4TlvDq8ikWAM | 使用的音色 |
| 音量 | 70% | 播放音量（0–100%） |
| 朗读聊天回复 | 开启 | 大声朗读 AI 回复 |
| 朗读闲聊 | 关闭 | 大声朗读气泡对话 |
| 全屏自动静音 | 开启 | 全屏应用期间静音 TTS |

### 标签页 6：屏幕感知

| 设置 | 默认值 | 说明 |
|------|--------|------|
| 启用屏幕感知 | 关闭 | 定期截图分析以生成上下文评论 |
| 显示指示器 | 开启 | 激活时显示“👁 Aemeath can see”徽章 |
| 视觉服务商 | Gemini Flash | Gemini Flash（便宜）或 Claude（更高质量） |
| 视觉 API 密钥 | （空） | 视觉服务商的 API 密钥 |
| 检查间隔 | 60 秒 | 截取频率（30/60/120 秒） |
| 每月预算上限 | $5.00 | 云端视觉 API 调用的花费限制 |
| 分析提示词 | （默认） | 可自定义视觉 AI 提示词，提供重置按钮 |
| 黑名单应用 | （4 个默认） | 阻止截图的应用/标题模式（每行一个） |

---

## 动画素材

9 个手工制作的 Q 版 GIF 动画：

| 动画 | 文件 | 尺寸 | 帧率 | 使用场景 |
|------|------|------|------|----------|
| 待机 | `normal.gif` | 200x200 | ~9 | 默认站立姿势 |
| 飞行 | `normal_flying.gif` | 200x200 | ~9 | 飞行移动（左飞时镜像） |
| 挥手 | `happy_hand_waving.gif` | 200x200 | ~9 | 点击时打招呼 |
| 开心 | `happy_jumping.gif` | 200x200 | ~9 | 悬停时跳跃 |
| 大笑 | `laugh.gif` | 200x200 | ~9 | 随机闲置大笑 |
| 大笑（飞行） | `laugh_flying.gif` | 200x200 | ~9 | 飞行中大笑 |
| 叹气 | `sign.gif` | 200x200 | ~9 | 忧郁时刻 |
| 唱歌 | `listening_music.gif` | 1000x1000 | 25 | 高品质唱歌动画 |
| 海豹 | `seal.gif` | 200x200 | ~9 | 海豹变身 |

素材位于 `src/AemeathDesktopPet/Resources/Sprites/Aemeath/` 和 `.../Seal/`。

没有专属素材的状态会回退到最接近的匹配动画（如大多数待机类状态使用 `normal.gif`）。

---

## 配置与数据文件

所有数据存储在 `%LOCALAPPDATA%\AemeathDesktopPet\`：

| 文件 | 用途 |
|------|------|
| `config.json` | 所有用户偏好和设置 |
| `stats.json` | 心情、体力、好感度值 + 累计计数器 |
| `messages.json` | 聊天对话历史（最多 200 条消息） |

### config.json 示例

```json
{
  "petSize": 200,
  "opacity": 1.0,
  "closeToTray": true,
  "behaviorFrequency": "normal",
  "enableGlitchEffect": true,
  "enableSinging": true,
  "enableBlackCat": true,
  "catName": "Kuro",
  "enableAmbientPaperPlanes": true,
  "ambientPlaneFrequency": "normal",
  "musicFolder": "",
  "aiProvider": "claude",
  "claudeApiKey": "",
  "geminiApiKey": "",
  "tts": {
    "enabled": false,
    "provider": "edgetts",
    "edgeTtsVoice": "en-US-AvaMultilingualNeural",
    "gptsovitsUrl": "http://localhost:9880",
    "gptsovitsProfiles": [],
    "gptsovitsActiveProfile": "",
    "elevenLabsApiKey": "",
    "elevenLabsVoiceId": "21m00Tcm4TlvDq8ikWAM",
    "elevenLabsModelId": "eleven_multilingual_v2",
    "volume": 0.7,
    "speakChatResponses": true,
    "speakIdleChatter": false,
    "autoMuteFullscreen": true
  },
  "voiceInput": {
    "enabled": false,
    "sttProvider": "whisper",
    "sttApiKey": "",
    "language": "en",
    "includeScreenshot": false,
    "hotkey": "Ctrl+F2"
  },
  "pomodoroIntegration": {
    "enabled": true,
    "pipeName": "AemeathDesktopPet",
    "workStartedPrompt": "[Pomodoro Timer] I just started a {duration}-minute work session on \"{taskTitle}\". Say something short (1-2 sentences) to encourage me and remind me to focus.",
    "workFinishedPrompt": "[Pomodoro Timer] I just finished my pomodoro work session on \"{taskTitle}\"! Say something short (1-2 sentences) to celebrate and congratulate me.",
    "breakStartedPrompt": "[Pomodoro Timer] I'm starting a {breakType} break ({duration} minutes). Say something short (1-2 sentences) to help me relax or chat with me.",
    "breakFinishedPrompt": "[Pomodoro Timer] My break is over, time to get back to work. Say something short (1-2 sentences) to motivate me.",
    "taskAddedPrompt": "[Pomodoro Timer] I just added a new task to my to-do list: \"{taskTitle}\". React briefly (1 sentence)."
  },
  "activityMonitor": {
    "enabled": false,
    "databasePath": "D:\\Study\\Project\\Computer_and_Chrome_Monitor_with_AI_Analysis\\data\\monitor.db"
  },
  "companionApps": {
    "launchMonitor": false,
    "monitorPath": "D:\\Study\\Project\\Computer_and_Chrome_Monitor_with_AI_Analysis\\run.bat",
    "launchTodoList": false,
    "todoListPath": "D:\\Study\\Project\\To_Do_List\\run.bat"
  }
}
```

---

## 项目结构

```
AemeathDesktopPet/
├── AemeathDesktopPet.sln           # 解决方案文件
├── run.bat / run.sh                # 启动脚本
├── REQUIREMENTS.md                 # 完整需求文档
├── CHECKLIST.md                    # 实现检查清单
├── aemeath_desktop_pet_design.md   # 详细设计文档
│
├── src/AemeathDesktopPet/
│   ├── AemeathDesktopPet.csproj
│   ├── App.xaml / App.xaml.cs
│   ├── app.manifest                # DPI 感知（PerMonitorV2）
│   │
│   ├── Models/
│   │   ├── PetState.cs             # 26 状态枚举 + 动画信息
│   │   ├── AppConfig.cs            # 配置模式（TTS、STT、屏幕感知、番茄钟）
│   │   ├── AemeathStats.cs         # 心情/体力/好感度 + 离线衰减
│   │   ├── ChatMessage.cs          # 聊天消息模型
│   │   ├── CatState.cs             # 12 状态猫咪枚举
│   │   ├── PomodoroEvent.cs        # 番茄钟管道消息模型
│   │   └── OfflineResponses.cs     # 100+ 角色脚本台词
│   │
│   ├── Engine/
│   │   ├── AnimationEngine.cs      # GIF 帧解码与播放
│   │   ├── BehaviorEngine.cs       # 26 状态 FSM，条件权重
│   │   ├── PhysicsEngine.cs        # 重力、碰撞、拖拽/抛掷
│   │   ├── EnvironmentDetector.cs  # 屏幕范围与全屏检测
│   │   ├── GlitchEffect.cs         # 数字幽灵视觉效果
│   │   ├── ParticleSystem.cs       # 6 种粒子类型，Canvas 渲染
│   │   ├── PaperPlaneSystem.cs     # 抛出 + 环境纸飞机
│   │   ├── CatBehaviorEngine.cs    # 独立猫咪 FSM
│   │   ├── WindowEdgeManager.cs    # 窗口标题栏检测与停靠
│   │   └── TimeAwareness.cs        # 时间段与条件
│   │
│   ├── Services/
│   │   ├── ConfigService.cs        # JSON 配置加载/保存
│   │   ├── MusicService.cs         # 音频文件夹扫描与播放
│   │   ├── StatsService.cs         # 属性追踪与交互效果
│   │   ├── MemoryService.cs        # 聊天历史持久化
│   │   ├── JsonPersistenceService.cs  # 属性 + 消息 JSON 存储
│   │   ├── ClaudeApiService.cs     # Claude API（SSE 流式）
│   │   ├── GeminiApiService.cs     # Gemini API（流式）
│   │   ├── ChatPromptBuilder.cs    # AI 聊天共享系统提示词
│   │   ├── IChatService.cs         # 聊天服务商接口
│   │   ├── ITtsService.cs          # TTS 服务接口
│   │   ├── ITtsProvider.cs         # 内部 TTS 提供者接口
│   │   ├── TtsVoiceService.cs      # 主 TTS 服务（NAudio 播放，队列）
│   │   ├── EdgeTtsProvider.cs      # Edge TTS（免费，无需 API 密钥）
│   │   ├── GptSovitsTtsProvider.cs # GPT-SoVITS（本地服务器）
│   │   ├── ElevenLabsTtsProvider.cs # ElevenLabs（云端 API）
│   │   ├── VoiceInputService.cs    # NAudio 麦克风录音
│   │   ├── GlobalHotkeyService.cs  # 底层键盘钩子（PTT）
│   │   ├── WhisperSttService.cs    # OpenAI Whisper STT
│   │   ├── GeminiSttService.cs     # Gemini STT
│   │   ├── ISpeechToTextService.cs # STT 提供者接口
│   │   ├── ScreenCaptureService.cs # 截图捕获 + JPEG 缩放
│   │   ├── IScreenAwarenessService.cs # 屏幕感知接口
│   │   ├── ScreenAwarenessService.cs # 屏幕感知（视觉 AI + 隐私管线）
│   │   ├── PomodoroIntegrationService.cs # 待办清单命名管道服务器
│   │   ├── ActivityMonitorService.cs # 活动数据只读 SQLite 访问
│   │   ├── CompanionLauncherService.cs # 配套应用自动启动
│   │   └── StartupService.cs         # 随 Windows 启动注册表管理
│   │
│   ├── ViewModels/
│   │   ├── PetViewModel.cs         # 主协调器
│   │   └── ChatViewModel.cs        # 聊天窗口逻辑 + 流式 + TTS
│   │
│   ├── Views/
│   │   ├── PetWindow.xaml/.cs      # 主透明宠物窗口
│   │   ├── ChatWindow.xaml/.cs     # AI 聊天窗口（暗色主题）
│   │   ├── SettingsWindow.xaml/.cs # 6 标签页设置面板
│   │   ├── StatsPopup.xaml/.cs     # 属性显示（渐变进度条）
│   │   ├── SpeechBubble.xaml/.cs   # 主题气泡对话
│   │   └── CatWindow.xaml/.cs      # 猫咪伙伴窗口
│   │
│   ├── Interop/
│   │   └── Win32Api.cs             # P/Invoke（GetWindowLong、SetWindowPos、鼠标穿透）
│   │
│   ├── Themes/
│   │   └── AemeathTheme.xaml       # 色彩方案（11 种命名颜色）
│   │
│   └── Resources/Sprites/
│       ├── Aemeath/                # 8 个角色 GIF 动画
│       └── Seal/                   # 海豹变身素材
│
├── tests/AemeathDesktopPet.Tests/  # 532 个测试，37 个测试类
│   ├── Models/                    # 8 个测试类
│   ├── Engine/                    # 8 个测试类
│   ├── Services/                  # 15 个测试类
│   ├── ViewModels/                # 2 个测试类
│   └── Interop/                   # 1 个测试类
│
└── tests/TtsIntegrationTest/      # TTS 实时测试控制台应用
```

---

## 依赖项

| 包 | 版本 | 用途 |
|----|------|------|
| [Hardcodet.NotifyIcon.Wpf](https://github.com/hardcodet/wpf-notifyicon) | 1.1.0 | 系统托盘图标 |
| [System.Drawing.Common](https://www.nuget.org/packages/System.Drawing.Common) | 8.0.0 | GIF 帧提取 |
| [NAudio](https://github.com/naudio/NAudio) | 2.2.1 | 音频录制（语音输入）和 TTS 播放 |
| [Edge_tts_sharp](https://www.nuget.org/packages/Edge_tts_sharp) | 1.1.7 | 免费 Edge TTS（WebSocket） |
| [Microsoft.Data.Sqlite](https://www.nuget.org/packages/Microsoft.Data.Sqlite) | 8.0.0 | 活动监控的只读 SQLite 访问 |
| [xUnit](https://xunit.net/) | 2.6.6 | 单元测试（仅测试项目） |

---

## 缺失素材与未实现功能

### 缺失素材

| 素材 | 当前替代方案 | 需要什么 |
|------|-------------|----------|
| 黑猫 GIF | Unicode 表情符号占位 | ~80x80px 素材集（12 种状态）匹配画风 |
| 纸飞机素材 | Unicode 飞机（✈） | ~32x32px PNG 或小 GIF |
| 托盘图标 | 编译警告 | `.ico` 多分辨率（16–256px） |
| 应用图标 | 无 | `.ico` 用于窗口标题栏/任务栏 |

---

## 技术栈

- **C# / .NET 8** — WPF 配合 `AllowsTransparency`
- **Win32 互操作** — `SetWindowLong`、`SetWindowPos`、`DwmGetWindowAttribute`、`EnumWindows`、`SetWinEventHook`
- **Hardcodet.NotifyIcon.Wpf** — 系统托盘集成
- **NAudio** — 音频录制和 TTS 播放
- **Edge_tts_sharp** — 免费 Edge TTS 合成
- **Microsoft.Data.Sqlite** — 活动监控联动的只读 SQLite 访问
- **System.Text.Json** — 配置和持久化
- **xUnit** — 532 个单元测试，37 个测试类（5 个类别）

---

## 关于爱弥斯

爱弥斯（Aemeath）是《鸣潮》中的角色。一个失去了肉身的数字幽灵，她以虚拟偶像"漂雪绒"（@fltsnflf）的身份存在。表面上活泼乐观，内心却有着难以言说的忧伤，凝结在她的标志性台词中：*"你看到我了吗？"*

本项目为粉丝自制桌面伴侣。所有角色版权归库洛游戏所有。
