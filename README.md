# 美团跑腿下单助手

通过直接调用美团跑腿接口完成下单全流程，支持帮取送、帮忙、帮买三大类场景。

## 功能特性

- **帮取送**：A 地取件送到 B 地，支持多种物品类型
- **帮忙**：取号（餐厅/医院/其他）、帮搬装、帮扔杂物等
- **帮买**：代购商品，支持指定购买地址或就近购买
- **地址簿搜索**：自动拉取用户历史地址，按最近使用时间排序展示
- **POI 地址搜索**：地址簿匹配不到时，通过关键词搜索补全坐标
- **两步确认**：先预览费用，用户确认后再正式提交，防止误单
- **订单查询**：实时查看订单状态

## 触发词

跑腿、下跑腿单、美团跑腿、同城配送、取号、挂号、排号、排队、帮搬、帮买、帮扔、帮忙、扔垃圾、寄文件、叫骑手、骑手帮忙、送东西、帮取、配送、帮送、买东西。

---

## 目录结构

```
MT-Paotui-For-Client/
├── SKILL.md              # 核心技能说明（Agent 指令）
├── README.md             # 本文件
├── dist/
│   ├── paotui.js         # 核心下单脚本
│   └── run.sh            # 启动脚本（推荐使用）
├── references/
│   ├── commands.md       # 所有命令及参数说明
│   ├── params.md         # 地址/物品/城市参数规范
│   └── errors.md         # 错误码与异常处理
```

> ⚠️ 本 Skill 使用 **Node.js** 运行，需要 Node.js 18+ 环境。

## 风险提示与免责声明：

本 Skill 运行在用户自行选择的独立AI 助手环境中，由用户自行选择的大模型驱动。美团仅提供跑腿相关接口和 Skill 定义，不对 AI 助手的运行环境、大模型安全合规性承担任何责任。

• 用户应确保所使用的 AI 助手已在中国大陆完成安全备案，并符合相关法律法规要求

• 用户应审慎评估 AI 对需求的理解偏差风险，使用本人账号授权操作，确认订单预览后再提交

• 如发现异常订单或 AI 行为异常，请立即联系美团客服处理

---

## 场景零：授权

### 执行流程

1. 调用业务命令时自动检测是否登录，未登录则返回授权链接
2. 根据使用环境完成授权：

📱 **手机端**：直接点击授权链接，跳转美团 App 完成授权

💻 **电脑端**：将授权链接复制到手机浏览器打开，再用美团 App 完成授权（链接 5 分钟内有效）

---

## 场景一：拉取地址簿

### 触发条件

需要获取用户历史地址，或用户在地址选择阶段提供关键词筛选。

### 命令

```bash
# 帮取送 / 帮忙场景
sh dist/run.sh get_address_list --address-type 1 --business-type 1 --scene 2

# 帮买场景
sh dist/run.sh get_address_list --address-type 1 --business-type 2 --scene 2
```

### 返回字段

| 字段 | 说明 |
|---|---|
| addressId | 地址 ID |
| address | 完整地址（楼号已含在此字段） |
| phone | 联系电话（服务端脱敏，下单直接用） |
| lat / lng | 坐标（整数×1e6），**直接用于下单，无需转换** |
| cityId | 城市 ID |
| lastUseTime | 最近使用时间戳（用于排序） |

---

## 场景二：POI 地址搜索

### 触发条件

用户提供新地址，但地址簿中匹配不到时，调用 POI 搜索获取坐标。

### 命令

```bash
sh dist/run.sh search_poi --keyword "奥林匹克森林公园南门" --city "北京" --lat 39904200 --lng 116407400
```

### 参数说明

| 参数 | 说明 | 默认值 |
|---|---|---|
| --keyword | 搜索关键词（必填） | — |
| --city | 城市名 | 北京 |
| --lat / --lng | 参考坐标（整数×1e6），提升搜索精度 | 北京中心 |

---

## 场景三：订单预览与提交

### 执行流程

**第一步：预览（不带 `--confirm`）** — 只展示费用，不提交

**第二步：用户回复"确认"后加 `--confirm` 提交** — 参数必须与预览完全一致

> ⚠️ 预览和提交在同一进程内完成，分开调用会导致 orderToken 失效（code 10311）。

### 命令

```bash
# 预览
sh dist/run.sh preview_and_submit \
  --sender '{"address":"奥林匹克森林公园南门","houseNumber":"","lat":40011253,"lng":116508883,"name":"","phone":"123****4567","cityId":110100}' \
  --recipient '{"address":"望京soho","houseNumber":"","lat":40020135,"lng":116469935,"name":"","phone":"123****6789","cityId":110100}' \
  --goods '{"goodsName":"文件","goodsWeight":1,"goodTypes":[4],"goodTypeNames":["文件"]}' \
  --business-type 1

# 确认提交（参数完全相同，仅加 --confirm）
sh dist/run.sh preview_and_submit ... --confirm
```

### 服务类型参数

| 场景 | --business-type | --biz-type-scene-tag |
|---|---|---|
| 帮取送 | 1 | 0（默认） |
| 餐厅取号 | 1 | 1 |
| 医院帮忙 | 1 | 2 |
| 其他取号 | 1 | 3 |
| 帮搬装 | 1 | 4 |
| 其他帮忙 | 1 | 5 |
| 帮扔杂物 | 1 | 6 |
| 帮买 | 2 | 0 |

> ⚠️ `--business-type` 只有 1 和 2 两个合法值，严禁传 3/4/5/6。

---

## 场景四：查询订单状态

```bash
sh dist/run.sh get_order_status --order-id "<orderViewId>"
```

---

## 安全门控

- **两步确认**：先预览展示费用，等用户回复"确认"后才加 `--confirm` 提交
- **金额拦截**：费用超过 100 元需额外向用户确认
- **地址完整性**：取件地址、收件地址、联系电话缺一不可
---

## 相关文档

- [references/commands.md](references/commands.md) — 所有命令及参数
- [references/params.md](references/params.md) — 地址/物品/城市规范
- [references/errors.md](references/errors.md) — 错误码与处理方式
