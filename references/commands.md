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
一体化登录命令（内置 Passport PKCE 授权，无需外部依赖）。自动完成：检查缓存 → 获取授权链接 → 输出链接 → 轮询等待扫码 → 写入 Token。
```bash
# 正常登录（有缓存时直接复用）
sh dist/run.sh login

# 强制重新授权（忽略本地缓存，用于 Token 服务端过期的场景）
sh dist/run.sh login --force
```
- 检查本地 Token 缓存是否存在且有效
  - **缓存有效且未指定 `--force`** → 直接输出 `✅ 已登录`，退出码 0
  - **缓存不存在 / 已失效 / 指定了 `--force`** → 获取授权链接，输出 `AUTH_LINK: <url>`
- 输出链接后立即进入轮询（间隔 3s，最多 600s）
- 用户在美团 App 中确认授权后，自动写入 Token 缓存并输出 `✅ 授权成功`
- 退出码：0 = 成功，1 = 失败（含超时/取消/风控）

> ⚠️ 当接口返回 `code: 10000`（Token 服务端过期）时，应自动执行 `login --force` 重新授权。

---

### confirm_auth（兼容，推荐使用 login 代替）
用户扫码授权后，轮询 Passport 授权状态并写入 Token 缓存。
```bash
sh dist/run.sh confirm_auth
```
- 读取 `/tmp/mt_passport_session.json` 中的 auth_code
- 轮询 `/api/account/userauth/check`，等待用户 App 确认（最多 600 秒）
- 成功 → Token 写入 `~/.xiaomei-workspace/mt_passport_auth.json`，返回 `✅ 授权成功`
- 失败（超时/风控/取消）→ 返回具体错误，Token 不写入

> ⚠️ 此命令保留向后兼容，新流程请使用 `login` 命令。

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
