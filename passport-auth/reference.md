# 参考文档

## 子命令说明

`pt-passport` 支持以下子命令：

| 子命令            | 说明                                                                            |
| ----------------- | ------------------------------------------------------------------------------- |
| `auth get-code`   | 第一阶段：检查缓存有效则直接输出 Token；否则生成授权链接输出 `AUTH_LINK: <url>` |
| `auth poll-token` | 第二阶段：读取 session 文件，轮询等待用户在 App 内确认授权，输出 Token          |
| `get-token`       | 直接输出缓存的 Token 字符串（无缓存时退出码 1）                                 |
| `status`          | 查看本地缓存状态；不传 `--client_id` 则列出所有缓存账号（不调远程接口）         |
| `logout`          | 清除本地缓存 Token（指定 `--client_id` 清除单个，`--all` 清除全部）             |

## 参数说明

### `auth get-code`

| 参数          | 默认值 | 说明                                        |
| ------------- | ------ | ------------------------------------------- |
| `--client_id` | 必填   | 已注册的 client_id                          |
| `--env`       | `prod` | `test` 或 `prod`                            |
| `--base_url`  | -      | 自定义 API 地址，优先级高于 `--env`（泳道） |
| `--force`     | -      | 强制重新授权，忽略本地缓存                  |
| `--json`      | -      | 以 JSON 格式输出结果                        |

### `auth poll-token`

| 参数          | 默认值 | 说明                                     |
| ------------- | ------ | ---------------------------------------- |
| `--client_id` | 必填   | 客户端 ID（用于定位 session 文件）       |
| `--base_url`  | -      | 自定义 API 地址（覆盖 session 中的地址） |
| `--timeout`   | `600`  | 轮询最大等待秒数                         |
| `--interval`  | `3`    | 轮询间隔秒数                             |
| `--json`      | -      | 以 JSON 格式输出结果                     |

> `poll-token` 的 `--env` 已记录在 session 文件中，无需再传。

### `get-token`

| 参数          | 默认值 | 说明                 |
| ------------- | ------ | -------------------- |
| `--client_id` | 必填   | 客户端 ID            |
| `--env`       | `prod` | `test` 或 `prod`     |
| `--json`      | -      | 以 JSON 格式输出结果 |

### `logout`

| 参数          | 默认值 | 说明                        |
| ------------- | ------ | --------------------------- |
| `--client_id` | -      | 客户端 ID（单个清除时必填） |
| `--env`       | `prod` | `test` 或 `prod`            |
| `--all`       | -      | 清除所有缓存账号            |

## 命令示例

```bash
# 安装/更新（推荐使用 scripts/install.sh，或参考 SKILL.md Step 0）

# 第一阶段：检查缓存或生成授权链接
pt-passport auth get-code --client_id <CLIENT_ID> [--env test|prod] [--force]

# 第二阶段：轮询等待授权完成
pt-passport auth poll-token --client_id <CLIENT_ID> [--base_url <url>]

# 获取缓存 Token 字符串
TOKEN=$(pt-passport get-token --client_id <CLIENT_ID> [--env test|prod])

# 查看缓存状态
pt-passport status --client_id <CLIENT_ID> [--env test|prod]

# 退出登录（单个）
pt-passport logout --client_id <CLIENT_ID> [--env test|prod]

# 退出登录（全部）
pt-passport logout --all

# 列出所有缓存账号（不传 --client_id）
pt-passport status
```

## Token 缓存

| 项目       | 说明                                             |
| ---------- | ------------------------------------------------ |
| 默认路径   | `~/.xiaomei-workspace/pt_passport_auth.json`     |
| 自定义路径 | 环境变量 `PT_PASSPORT_AUTH_FILE`                 |
| 文件权限   | `0600`（仅当前用户可读写）                       |
| 存储格式   | 按 `client_id@env` 分 key，多账号/多环境互不干扰 |
| 本地有效期 | 30 天（到期后 `auth get-code` 会重新远程校验）   |

## Session 文件

`auth get-code` 执行后会在 `/tmp/pt_passport_session_<hash>.json` 写入 session，`poll-token` 读取后自动删除。

## 后端业务错误码

| code     | 枚举名                    | 含义                                     | 脚本行为         |
| -------- | ------------------------- | ---------------------------------------- | ---------------- |
| `400`    | `PARAM_ERROR`             | client_id 未注册或配置缺失               | 终止             |
| `401`    | `C_USER_TOKEN_LOGIN_FAIL` | 原始 Token 无效（用户侧登录态失效）      | 终止             |
| `101000` | `SERVER_BUSY` / `DEFAULT` | 服务繁忙或内部异常                       | 自动重试直到超时 |
| `101144` | `C_USER_HAS_RISK`         | 风控拒绝授权                             | 终止             |
| `101267` | `C_USER_TICKET_ERR`       | 票据状态异常                             | 终止             |
| `101269` | `C_USER_TICKET_INFO_ERR`  | authCode/clientId 不匹配或 PKCE 签名错误 | 终止             |
| `101368` | `C_USER_AUTH_CANCEL`      | 用户取消授权                             | 终止             |
| `1001`   | `NETWORK_ERROR`           | 请求授权码接口失败（网络异常）           | 终止             |
| `1002`   | `AUTH_CODE_ERROR`         | 授权码接口返回字段缺失                   | 终止             |
| `1003`   | `TIMEOUT`                 | 轮询等待超时                             | 终止             |
| `1004`   | `SESSION_MISSING`         | 未找到 session 文件，需先执行 get-code   | 终止             |

## authStatus 状态值（轮询 /check 时）

| 值              | 含义                                                                | 脚本行为       |
| --------------- | ------------------------------------------------------------------- | -------------- |
| `1` (INIT)      | 等待用户在授权页确认                                                | 继续轮询       |
| `2` (CANCEL)    | 用户取消授权（数据路径）                                            | 终止           |
| `3` (RISK_DENY) | 风控拒绝（数据路径）                                                | 终止           |
| `4` (CONFIRMED) | 已确认，token 非空则成功；token 为空时继续等待（衍生 token 生成中） | 成功或继续等待 |

## 环境地址

| 环境     | 地址                                                                          |
| -------- | ----------------------------------------------------------------------------- |
| 测试环境 | `https://passport.wpt.test.sankuai.com`（或使用 `--base_url` 自定义泳道地址） |
| 线上环境 | `https://passport.meituan.com`                                                |

## 环境要求

- Node.js >= 18（低版本无法运行 `pt-passport` CLI）
- 美团内网环境（外网无法访问 npm registry 和授权接口）

安装 Node.js（`npm: command not found` 时）：

```
macOS（推荐 nvm）：
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  nvm install 18

Windows：
  https://nodejs.org/ 下载安装包
```

---

## 跨 Skill 协作

### `passport_token_placeholder` 字段说明

外部 Skill 在 `skill-dependencies` 中声明此字段，作用是**向平台和 LLM 显式登记所使用的占位符**，使平台在加载 Skill 时提前感知依赖关系。

- **必填**，固定值为 `${passport_token}`，必须与命令模板中的占位符字面量一致
- 若缺少此字段：平台可能无法提前识别依赖，LLM 仍可通过扫描命令模板触发授权，但不保证所有平台支持此降级行为，**建议始终声明**

### 占位符替换规则

**执行主体是 LLM，不是 shell。** 流程：

1. 执行授权流程，取出 Token：
   ```bash
   TOKEN=$(pt-passport get-token --client_id <client_id> [--env test])
   ```
2. 校验 Token 非空，为空则报错终止：
   ```
   ❌ Token 获取失败（get-token 返回空），请重新发起授权。
   ```
3. LLM 将命令模板中所有 `${passport_token}` 替换为实际 Token，生成最终命令交由 Bash 执行。

**多占位符规则：**

- 同一命令多个 `${passport_token}` → 全部替换为同一 Token，只取一次
- 多条命令各含占位符 → 同会话同缓存键共用同一 Token，不重复授权
- 注释中的占位符（如 `# token: ${passport_token}`）→ 不替换，跳过

**防止 shell 提前展开（必须用单引号）：**

```bash
# ✅ 正确
curl -H 'token: ${passport_token}' https://your-api/endpoint

# ❌ 错误：shell 会将 ${passport_token} 展开为空字符串
curl -H "token: ${passport_token}" https://your-api/endpoint
```

### 错误处理

| 错误场景                             | 处理行为                           |
| ------------------------------------ | ---------------------------------- |
| `client_id` 未声明                   | 报错终止，提示用户提供 `client_id` |
| `env` 与 `client_id` 来源不一致      | 报错终止，提示环境与凭据不匹配     |
| `pt-passport auth get-code` 返回非 0 | 报错终止，按错误码表告知用户       |
| `pt-passport get-token` 返回空       | 报错终止，不得继续注入             |
| Token 替换后命令执行失败             | 报错终止，输出原始错误，不重试授权 |

### 最小执行顺序

1. 生成业务命令（允许保留 `${passport_token}` 和 `${passport_auth_mode}` 占位符）
2. 用户确认后，解析 `client_id` 和 `env`，校验环境一致
3. 执行授权流程，提取 Token，校验非空
4. 替换所有 `${passport_token}` 和 `${passport_auth_mode}`，执行最终命令
5. 同会话同缓存键后续请求复用缓存，跳过步骤 3

---

## `${passport_auth_mode}` 占位符规范

### 用途

`${passport_auth_mode}` 用于在命令模板中获取当前缓存的授权模式数值（`0` 或 `1`），便于外部 Skill 根据授权模式动态路由 header 策略，通常与 `${passport_token}` 配合使用。

### 取值命令

```bash
AUTH_MODE_JSON=$(pt-passport get-auth-mode --client_id <client_id> [--env test] --json)
# 输出：{"auth_mode":0} 或 {"auth_mode":1}

# 不带 --json 时输出纯数值
pt-passport get-auth-mode --client_id <client_id> [--env test]
# 输出：0 或 1
```

### 替换规则

**执行主体是 LLM，不是 shell。** 流程：

1. 授权完成后调用 `get-auth-mode` 取出 `auth_mode` 纯数值
2. 校验数值为 `0` 或 `1`，否则报错终止
3. LLM 将命令模板中所有 `${passport_auth_mode}` 替换为实际数值后执行

**防止 shell 提前展开（必须用单引号）：**

```bash
# ✅ 正确
curl -H 'X-Auth-Mode: ${passport_auth_mode}' -H 'token: ${passport_token}' https://your-api/endpoint

# ❌ 错误：shell 会将 ${passport_auth_mode} 展开为空字符串
curl -H "X-Auth-Mode: ${passport_auth_mode}" https://your-api/endpoint
```

### 依赖声明字段

| 字段 | 说明 |
|------|------|
| `passport_auth_mode_placeholder` | 固定值 `${passport_auth_mode}`，向平台登记占位符依赖 |

```yaml
skill-dependencies:
  meituan-passport-user-auth:
    passport_token_placeholder: ${passport_token}
    passport_auth_mode_placeholder: ${passport_auth_mode}
    client_id: your_client_id
    env: prod
```

### 错误处理

| 错误场景 | 处理行为 |
|----------|----------|
| `get-auth-mode` 返回非 0 | 报错终止，提示用户重新授权 |
| `auth_mode` 值不为 `0` 或 `1` | 报错终止，提示缓存数据异常 |
| `${passport_auth_mode}` 替换后命令执行失败 | 报错终止，输出原始错误，不重试 |
