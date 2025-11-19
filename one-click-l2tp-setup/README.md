# L2TP VPN 一键安装脚本

一个用于在 Debian/Ubuntu 系统上快速搭建 L2TP VPN 服务器的 Shell 脚本。

### 系统要求

-   Debian 10+ 或 Ubuntu 18.04+
-   拥有 `root` 或 `sudo` 权限

### 快速安装

只需复制并运行下面的一行命令即可完成安装：

```bash
wget https://raw.githubusercontent.com/fanyuo/one-click-l2tp-setup/main/one-click-l2tp-setup.sh && chmod +x one-click-l2tp-setup.sh && sudo ./one-click-l2tp-setup.sh
```

### ⚠️ 重要：安装后步骤

脚本运行成功后，你 **必须** 手动完成以下两件事才能正常使用：

#### 1. 添加 VPN 用户

编辑文件 `/etc/ppp/chap-secrets`，按以下格式添加用户（每行一个）：

```
# 格式: "用户名" * "密码" *
"testuser" * "your_password" *
```

**注意：** 用户名、密码和星号 `*` 之间 **必须** 有空格。

#### 2. 开放防火墙端口

如果你的服务器在云平台（如阿里云、腾讯云、AWS）或路由器之后，请务必在其管理后台的 **安全组** 或防火墙策略中，**放行 UDP 1701 端口** 的入站流量。

### 如何连接

-   **服务器地址**: 填写你服务器的 **公网 IP 地址**。
-   **预共享密钥 (PSK)**: 无需填写。