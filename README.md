# DesktopCommander-SPK

Synology DSM 原生 Desktop Commander 套件，目标设备为 DS3615xs-j / DSM 6.2.3-25426（Bromolow x86_64）。

## 项目状态

Desktop Commander SPK **1.0.0 正式版已发布，DS3615xs-j 目标 NAS 的 14 项实机验收全部通过**。正式 SPK 内部版本为 `1.0.0-0016`，可从目标 NAS 上的 `1.0.0-0015` 候选包直接覆盖升级。

- 正式验收记录：[实机验收证据](evidence/1.0.0-nas-acceptance-notes.md)
- 正式 Release：[Desktop Commander v1.0.0](https://github.com/QiStore/DesktopCommander-SPK/releases/tag/v1.0.0)
- SPK 下载：[DesktopCommanderSPK-1.0.0-0016-bromolow.spk](https://github.com/QiStore/DesktopCommander-SPK/releases/download/v1.0.0/DesktopCommanderSPK-1.0.0-0016-bromolow.spk)
- 自动构建与正式 Release：[GitHub Actions 发布工作流](.github/workflows/release.yml)

## 设计路线

- 复用上游 [Desktop Commander MCP](https://github.com/wonderwhy-er/DesktopCommanderMCP) 的 MIT 授权本地 MCP 服务和 Remote Device Agent，固定到 `vendor/upstream.lock` 指定的源代码提交。
- NAS 运行本地 MCP 服务和设备代理；设备代理使用 Desktop Commander 官方 Remote MCP 服务完成实际设备授权、工具转发及重连。不仿造 OAuth，不自建上游专有服务，也不把 NAS 本地状态冒充为 ChatGPT 连接状态。
- 安装包携带 Node.js 运行时和生产依赖；用户无需另外安装 Node.js、Docker 或 Windows 常驻进程。
- MCP 文件工具默认仅授权套件 workspace；DSM 管理员可在管理页勾选要开放的共享目录。授权目录始终至少包含 workspace，避免空目录列表被上游解释成不限制路径。
- 关闭上游遥测；设备授权凭据和工具配置存放在 DSM 持久套件变量目录，升级保留，卸载按用户选择处理。
- Remote Device Agent 与 MCP 服务由 DSM 套件生命周期脚本以 root 启动。共享目录白名单限制文件工具可见路径；root 权限的 Shell 工具仍可访问 NAS 系统路径。
- 管理页允许管理员设置共享目录与 NAS 开机自启动；supervisor 在服务进程异常退出时自动重启，使用递增退避和日志轮转。
- 管理页展示上游真实设备授权状态；有效授权链接会在 DSM 管理窗口打开官方验证页面。授权码不写入普通服务日志。

## 目标环境与发布

- NAS：Synology DS3615xs-j
- DSM：6.2.3-25426
- 平台 / 架构：Bromolow / x86_64
- GitHub 正式版标签：`v1.0.0`
- SPK 内部升级版本：`1.0.0-0016`

正式发布由 GitHub Actions 完成目标 NAS 验收门槛、源码与许可证检查、SPK 构建及包结构检查。root 运行扩大 Shell 工具的权限范围；共享目录选择仅限制文件工具。

## 文档

- [开发与验收记录](docs/开发与验收.md)
- [实机验收证据](evidence/README.md)
- [安全设计](docs/安全设计.md)
- [覆盖升级指南](docs/覆盖升级.md)

上游源码及许可证由 CI 按锁定提交获取；仓库不复制上游闭源 Remote MCP 服务端代码。第三方依赖许可证清单随 SPK 安装包附带。
