# DesktopCommander-SPK

Synology DSM 原生 Desktop Commander 套件，目标平台为 DSM 6.2.3 Bromolow x86_64。

## 项目状态

项目处于正式版开发阶段，**1.0.0 尚未发布**。正式发布必须先通过目标 NAS 实机安装、MCP 授权与工具调用验收。GitHub Actions 构建成功不能代替 NAS 验收。

## 设计

- 复用 MIT 授权的 [Desktop Commander MCP](https://github.com/wonderwhy-er/DesktopCommanderMCP)，CI 按 `vendor/upstream.lock` 锁定提交获取源码。
- NAS 运行本地 MCP 服务和官方 Remote Device Agent；授权和远程转发使用 Desktop Commander 官方 Remote MCP 服务。
- 安装包自带 Node.js 运行时和依赖。
- 文件访问须配置非空授权目录；服务以套件专用账户运行。
- 未经实测不宣称设备授权、ChatGPT 连接或远程工具调用成功。

开发和验收记录见 `docs/`。