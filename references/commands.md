# 命令参考

## 执行方式

```bash
# 分发包（推荐）—— 使用混淆打包版
sh dist/run.sh <command> [args...]

# 源码开发调试
node scripts/paotui.js <command> [args...]
```

---

## 命令列表

### confirm_auth
用户扫码授权后，轮询 Passport 授权状态并写入 Token 缓存。
```bash
node scripts/paotui.js confirm_auth
```
- 读取 `/tmp/mt_passport_session.json` 中的 auth_code
- 轮询 `/api/account/userauth/check`，等待用户 App 确认（最多 600 秒）
- 成功 → Token 写入 `~/.xiaomei-workspace/mt_passport_auth.json`，返回 `✅ 授权成功`
- 失败（超时/风控/取消）→ 返回具体错误，Token 不写入

> ⚠️ `confirm_auth` 必须在用户扫码后立即调用，不得跳过或延迟，否则 auth_code 过期。

---

### search_poi
POI 地址搜索，获取地址坐标。
```bash
node scripts/paotui.js search_poi --keyword "融新科技中心" --city "北京" --lat 39904200 --lng 116407400
```
- `--keyword`：搜索关键词（必填）
- `--city`：城市名（默认北京）
- `--lat` / `--lng`：参考坐标，提升搜索精度（整数×1e6）

---

### get_address_list
获取用户地址簿（推荐，含坐标/标签/最近使用时间）。
```bash
# 帮送场景（默认）
node scripts/paotui.js get_address_list --address-type 1 --business-type 1 --scene 2

# 帮买场景
node scripts/paotui.js get_address_list --address-type 1 --business-type 2 --scene 2
```
返回字段：`addressId`、`address`、`houseNumber`、`name`、`phone`（服务端脱敏，下单直接用）、`lat`/`lng`（整数×1e6，**直接用于下单**）、`cityId`、`tag`、`isDefault`、`lastUseTime`。

---

### preview_and_submit
配送预览 + 提交一体化（推荐）。
```bash
# 第一步：预览（不带 --confirm，只展示费用，不提交）
node scripts/paotui.js preview_and_submit \
  --sender '<地址JSON>' \
  --recipient '<地址JSON>' \
  --goods '<物品JSON>' \
  --business-type 1 \
  [--biz-type-scene-tag 0] \
  [--tip-fee 0] \
  [--remark ""] \
  [--purchase-detail ""]

# 第二步：用户确认后加 --confirm 提交（参数完全相同）
node scripts/paotui.js preview_and_submit ... --confirm
```
> ⚠️ `--confirm` 模式在同一进程内完成预览+提交，避免 orderToken 跨进程失效（code 10311）。

---

### get_order_status
查询订单状态。
```bash
node scripts/paotui.js get_order_status --order-id "<orderViewId>"
```
