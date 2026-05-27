# 命令参考

## 执行方式

```bash
# 分发包（推荐）—— 使用混淆打包版
sh dist/run.sh <command> [args...]

# 源码开发调试
node dist/paotui.js <command> [args...]
```

---

## 命令列表

### login
检查登录状态 / 获取授权链接（快速返回，不轮询）。
```bash
# 检查是否已登录（有缓存 → "已登录"退出；无缓存 → 输出授权链接后退出）
sh dist/run.sh login

# 强制重新获取授权链接（忽略本地缓存，用于 Token 服务端过期的场景）
sh dist/run.sh login --force
```
- 检查本地 Token 缓存是否存在
  - **缓存存在且未指定 `--force`** → 直接输出 `✅ 已登录`，退出码 0（耗时 ~100ms）
  - **缓存不存在 / 指定了 `--force`** → 获取授权链接，输出 `AUTH_LINK: <url>`，退出码 0（耗时 ~800ms）
- **不进入轮询**，立即返回。Agent 展示链接给用户后，等用户完成授权，再调用 `confirm_auth`
- 退出码：0 = 检查通过/链接已生成，1 = 获取链接失败

> ⚠️ 当接口返回 `code: 10000`（Token 服务端过期）时，应自动执行 `login --force` 重新授权。

---

### confirm_auth
用户扫码后调用，轮询 Passport 授权状态并写入 Token 缓存。
```bash
sh dist/run.sh confirm_auth
```
- 读取 `/tmp/mt_passport_session.json` 中的 auth_code（由 login 命令写入）
- 轮询 `/api/account/userauth/check`，等待用户 App 确认（最多 600 秒）
- 成功 → Token 写入 `~/.xiaomei-workspace/mt_passport_auth.json`，返回 `✅ 授权成功`
- 失败（超时/风控/取消）→ 返回具体错误，Token 不写入

> 标准授权流程：`login` → 展示授权链接给用户 → 用户完成授权 → `confirm_auth`

---

### search_poi
POI 地址搜索，获取地址坐标。
```bash
sh dist/run.sh search_poi --keyword "融新科技中心" --city "北京" --lat 39904200 --lng 116407400
```
- `--keyword`：搜索关键词（必填）
- `--city`：城市名（默认北京）
- `--lat` / `--lng`：参考坐标，提升搜索精度（整数×1e6）

---

### get_address_list
获取用户地址簿（推荐，含坐标/标签/最近使用时间）。
```bash
# 帮送场景（默认）
sh dist/run.sh get_address_list --address-type 1 --business-type 1 --scene 2

# 帮买场景
sh dist/run.sh get_address_list --address-type 1 --business-type 2 --scene 2
```
返回字段：`addressId`、`address`、`houseNumber`、`name`、`phone`（服务端脱敏，下单直接用）、`lat`/`lng`（整数×1e6，**直接用于下单**）、`cityId`、`tag`、`isDefault`、`lastUseTime`。

---

### preview_and_submit
配送预览 + 提交一体化（推荐）。
```bash
# 第一步：预览（不带 --confirm，只展示费用，不提交）
sh dist/run.sh preview_and_submit \
  --sender '<地址JSON>' \
  --recipient '<地址JSON>' \
  --goods '<物品JSON>' \
  --business-type 1 \
  [--biz-type-scene-tag 0] \
  [--tip-fee 0] \
  [--remark ""] \
  [--purchase-detail ""]

# 第二步：用户确认后加 --confirm 提交（参数完全相同）
sh dist/run.sh preview_and_submit ... --confirm
```
> ⚠️ `--confirm` 模式在同一进程内完成预览+提交，避免 orderToken 跨进程失效（code 10311）。

---

### get_order_status
查询订单状态。
```bash
sh dist/run.sh get_order_status --order-id "<orderViewId>"
```
