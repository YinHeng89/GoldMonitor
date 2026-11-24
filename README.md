# Gold Monitor for macOS

原生 SwiftUI 黄金行情监控客户端，同时跟踪**伦敦金现货（XAUUSD）**与**中国工商银行积存金**，支持自动刷新、价格预警、历史走势与本地持仓收益计算。数据全部来自公开行情页面，不连接任何交易账户，无需登录。

## 功能

| 模块 | 说明 |
|---|---|
| 总览 | 持仓盈亏速览、两种行情的交易价横条、近期走势图、数据源诊断状态条 |
| 伦敦金 / 工行积存金 | 单项行情详情：现价、涨跌、最高最低、报价时间、来源 |
| 我的持仓 | 手动录入成本价、克数、品类、买入时间；按实时行情计算市值与盈亏（盈利红、亏损绿） |
| 价格预警 | 设置上下限阈值，触发时发系统通知 |
| 历史记录 | 按日期/品类查看已采集的价格快照与折线走势 |
| 系统设置 | 刷新间隔、自动刷新、系统通知、外观（深/浅/跟随系统）、伦敦金数据源 |
| 菜单栏面板 | 桌面顶部常驻金价，一键打开主窗口、手动刷新、退出 |

## 数据源

| 品类 | 来源 | 说明 |
|---|---|---|
| 工行积存金 | `POST https://mybank.icbc.com.cn/servlet/AsynGetDataServlet`，body `tranCode=A00622` | 官网行情真实接口；`ActivePrice` 为现价，`SellPrice` 为赎回价（持仓市值按赎回价算） |
| 伦敦金 | 新浪财经 `https://hq.sinajs.cn/list=hf_XAU` | 默认且已验证可用；返回 GBK，但行情字段均为 ASCII |
| 伦敦金（备用） | FX168 网页解析 | 规划文档指定来源，当前网络不可达、页面结构易变；设置里可切换，失败时明确报错，不会拿旧数据冒充实时 |

行情抓取失败只写入错误态并显示「获取失败」，不会用缓存价格伪装成实时数据。

## 环境与构建

- macOS 14.0+
- Xcode 16+（Swift 5.10）
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

```bash
# 工程文件已生成；如需从 project.yml 重新生成：
xcodegen generate

# Debug 编译
xcodebuild -project GoldMonitor.xcodeproj -scheme GoldMonitor \
  -configuration Debug -derivedDataPath .build build

# 单元测试（21 项）
xcodebuild test -project GoldMonitor.xcodeproj -scheme GoldMonitor \
  -configuration Debug -derivedDataPath .build

# 交付包在 .build/Build/Products/Debug/GoldMonitor.app
```

工程说明：SwiftData / SwiftUI 宏需要 `-disable-sandbox`（见 `project.yml`）；App 图标通过显式 `Resources/Info.plist` 指定 `CFBundleIconFile`，不依赖 Xcode 自动生成的 Info.plist。图标源文件在 `AppIcon.iconset/`，可用 `scripts/generate_icon.swift` 重新生成 `Resources/AppIcon.icns`。

## 数据存储

| 内容 | 位置 | 说明 |
|---|---|---|
| 价格快照、预警、持仓 | `~/Library/Application Support/default.store`（SwiftData） | 表：`ZPRICESNAPSHOT`、`ZPRICEALERT`、`ZGOLDHOLDING` |
| 设置 | `UserDefaults` 键 `goldmonitor.settings` | 刷新间隔、自动刷新、通知、外观、数据源 |
| 历史策略 | 滚动上限 5000 条 | 两种行情共享额度，超出后按时间从旧到新裁剪 |

**关于历史缺口**：价格快照只在 App 运行时按刷新间隔采集。关闭客户端期间不采集、也不事后回填——例如连续三天不打开，这三天没有数据点，重新打开后只会从当下继续记录。当前设计以「当天真实数据」为准，不做历史补齐。

## 目录结构

```
Sources/GoldMonitor/
  App/        GoldMonitorApp.swift        入口、窗口与菜单栏场景
  Models/     GoldQuote / GoldHolding / PriceSnapshot / PriceAlert
  Services/   MarketStore（调度与持久化）、各行情服务、通知、HTTP 客户端
  Views/      ContentView（侧边栏）、Dashboard、行情详情、持仓、预警、历史、设置、主题
Tests/GoldMonitorTests/
  ParserTests / LiveDataSourceTests / AlertLogicTests / SettingsPersistenceTests / HoldingTests
Resources/  Info.plist、AppIcon.icns
project.yml XcodeGen 配置
```

## 注意事项

- 行情仅供参考，请以交易所与银行官方报价为准。
- 盈亏口径：工行持仓按赎回价（`SellPrice`）计算当前市值，伦敦金按现价；成本 = 成本价 × 克数，盈亏 = 市值 − 成本。
- 克数输入保留至多 6 位小数并去除尾部 0，显示层不四舍五入，避免 `1.394` 被显示成 `1.39`；存储无精度损失。
- 涨跌颜色遵循 A 股习惯：上涨红色、下跌绿色。
