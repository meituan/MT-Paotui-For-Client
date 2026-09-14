# 命令与参数

## 命令总览

| 命令 | 说明 | 必填参数 |
|------|------|---------|
| `login` | 检查鉴权状态 | 无（可选 `--force`） |
| `logout` | 登出（清除本地 Token） | 无 |
| `confirm_auth` | 检查鉴权有效性 | 无 |
| `search_poi` | POI 地址搜索 | `--keyword` |
| `get_address_list` | 获取用户地址簿 | 无 |
| `get_address_info` | 根据地址 ID 获取真实手机号 | `--address-id` |
| `delivery_preview` | 配送预览（查询费用/时效） | `--sender --recipient --goods` |
| `submit_order` | 提交订单 | `--order-token --sender --recipient --goods --delivery-fee` |
| `get_order_status` | 查询订单状态 | `--order-id` |
| `get_last_preview` | 查看上一次预览结果（缓存） | 无 |

## 详细参数

### search_poi
```
--keyword <string>     搜索关键词（必填）
--city <string>        城市名（默认"北京"）
--lat <number>         纬度（E6整数或小数）
--lng <number>         经度（E6整数或小数）
```

### get_address_list
```
--address-type <int>   地址类型（默认 1）
--business-type <int>  业务类型（默认 1）
--scene <int>          场景（默认 2）
```
返回字段：`addressId`、`address`、`houseNumber`、`name`、`phone`（服务端脱敏）、`lat`/`lng`、`cityId`、`tag`、`isDefault`、`lastUseTime`。

> ⚠️ `phone` 是脱敏号码（如 `187****0436`），仅供展示，**不能直接用于下单**。需通过 `get_address_info` 获取真实号码。

---

### get_address_info
根据地址 ID 获取真实手机号。`get_address_list` 返回的 phone 是脱敏号码，不能直接用于下单，**必须通过此命令获取真实号码**。其余地址信息（address、houseNumber、name、坐标等）仍使用 `get_address_list` 返回的。
```
--address-id <string>  地址 ID（必填，来自 get_address_list 返回的 addressId）
```
返回字段：`addressId`、`phone`（**真实号码**）。

---

### delivery_preview
配送预览命令，返回费用、时效、orderToken 等信息，不提交订单。结果会自动缓存，可通过 `get_last_preview` 查看。
```
--sender <JSON>              发件人地址对象（必填）
--recipient <JSON>           收件人地址对象（必填）
--goods <JSON>               物品信息对象（必填）
--business-type <string>     业务类型: 1=帮取送/帮忙, 2=帮买（默认 1）
--biz-type-scene-tag <string> 场景标签（默认 0，仅帮取送体系使用，详见 params.md；帮买不传，帮买用 --business-type-tag）
--service-type <string>       服务类型，仅帮取送/帮忙使用（帮取送 1003=普通送/4033=1v1急送，帮忙固定 4033）；帮买不传
--tip-fee <int>              小费（分，默认 0）
--purchase-detail <string>   帮买物品明细（businessType=2 时使用）
```

返回字段中需要关注的：`orderToken`（提交订单时必传）、`_deliveryFee`（提交订单时必传配送费原价）、`_couponViewId`（有优惠券时传入提交）。

**帮买场景参数组合**（businessType=2，与帮取送/帮忙的关键差异）：

> ⚠️ `--business-type-tag` **未列入 CLI usage 帮助文本**（工具方遗漏），功能正常，照常传。另注意与 `--biz-type-scene-tag` 严禁互串：帮买用 `--business-type-tag`，帮取送体系用 `--biz-type-scene-tag`，误传会静默错单。

- `--business-type 2`
- `--business-type-tag`：指定购买地址传 `0`，就近购买传 `1`
- `--sender`：指定购买地址时传商家地址；就近购买时传收件地址（和 `--recipient` 相同）
- `--purchase-detail`：必传，填写购买物品明细
- 不传 `--service-type`（帮买专用参数组合，与其他场景的关键差异）

就近购买示例：
```
--sender '{"lat":40020135,"lng":116469935,"address":"朝来科技产业园西区-1号楼","name":"j","phone":"13552069166"}' \
--recipient '{"lat":40020135,"lng":116469935,"address":"朝来科技产业园西区-1号楼","name":"j","phone":"13552069166"}' \
--goods '{"goodsName":"猫粮"}' --business-type 2 --business-type-tag 1 --purchase-detail "购买一包猫粮"
```

**帮取送/帮忙场景**：businessType=1，需按场景传 `--service-type`（详见上表），不传 `--business-type-tag`/`--purchase-detail`。

---

### submit_order
提交订单命令。需要先通过 `delivery_preview` 获取 `orderToken` 和 `_deliveryFee`，再传入提交。
```
--order-token <string>       配送令牌（必填，来自预览返回的 orderToken）
--sender <JSON>              发件人地址对象（必填，与预览时一致）
--recipient <JSON>           收件人地址对象（必填，与预览时一致）
--goods <JSON>               物品信息对象（必填，与预览时一致）
--delivery-fee <number>      配送费（必填，来自预览返回的 _deliveryFee）
--business-type <string>     业务类型（默认 1，与预览时一致）
--biz-type-scene-tag <string> 场景标签（与预览时一致）
--service-type <string>       服务类型，与预览时一致（帮取送 1003/4033，帮忙固定 4033，帮买不传）
--tip-fee <int>              小费（分，默认 0）
--remark <string>            备注
--purchase-detail <string>   帮买物品明细
--coupon-view-id <string>    优惠券视图ID（来自预览返回的 _couponViewId）
```

---

### get_order_status
```
--order-id <string>    订单ID（必填）
```

---

### logout
清除本地缓存的 accessToken、环境变量以及 pt-passport CLI 的登录态。不需要任何参数。

---

### get_last_preview
查看上一次 `delivery_preview` 的缓存结果，不会重新发起网络请求。如果已成功提交过订单，会同时返回 `orderId`。不需要任何参数。
