# DesktopCommander-SPK

Synology DSM 原生 Desktop Commander 套件，目标设备为 DS3615xs-j / DSM 6.2.3-25426（Bromolow x86_64）。

## 项目状态

仓库目前处于正式版开发与目标设备验收阶段。**尚未发布 1.0.0，也没有正式 SPK。** 自动构建、源码审查及目标 NAS 实机验收完成后，才会创建正式 Release。

## 设计路线

- 复用上游 [Desktop Commander MCP](https://github.com/wonderwhy-er/DesktopCommanderMCP) 的 MIT 授权本地 MCP 服务和 Remote Device Agent，固定到 `vendor/upstream.lock` 指定的源代码提交。
- NAS 运行本地 MCP 服务和设备代理；设备代理使用 Desktop Commander 官方 Remote MCP 服务完成实际设备授权、工具转发及重连。这里不仿造 OAuth、不自建上游专有服务，也不把 NAS 本地状态冒充为 ChatGPT 连接状态。
- 安装包须携带 Node.js 运行时和生产依赖。用户无需另外安装 Node.js、Docker 或 Windows 常驻进程。
- MCP 文件访问从一个受限的专用工作目录开始；只把用户明确授权的共享目录加入 Desktop Commander 的 `allowedDirectories`。该列表不能为空，因为上游将空列表定义为不限制目录。
- 关闭上游遥测；设备授权凭据和工具配置存放在 DSM 持久套件变量目录，升级保留，卸载按用户选择处理。
- 服务按 DSM 套件专用账户运行，不以 root 执行用户命令。

## 目标环境与发布门槛

目标设备：DS3615xs-j，DSM 6.2.3-25426，Bromolow / x86_64。

GitHub Actions 能验证源码、许可证、元数据、脚本语法和 SPK 结构；它不能证明 DSM 已安装套件，也不能证明设备授权、ChatGPT 工具调用或开机自启成功。没有 DS3615xs-j 上的实测证据，不会将这些项目标记为通过，也不会发布正式版。

## 开发说明

见 [开发与验收记录](docs/开发与验收.md)、[安全设计](docs/安全设计.md) 和 [覆盖升级指南](docs/覆盖升级.md)。

上游源码及许可证由 CI 按锁定提交获取，不直接把上游闭源 Remote MCP 服务代码复制进本仓库。第三方依赖的许可证清单将在 SPK 构建时随安装包附带。

