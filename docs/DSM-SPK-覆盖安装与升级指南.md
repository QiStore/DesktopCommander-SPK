# Synology DSM SPK 覆盖安装与升级指南

这份指南整理 Synology DSM SPK 的覆盖升级原理、数据保护方式和发布前检查流程，供不同套件复用。适用前提是旧版与新版属于同一个套件，且新版 SPK 的目标 DSM、CPU 架构和数据布局兼容。

## 实机验证范围

- NAS：Synology DS3615xs-j
- DSM：6.2.3-25426
- 架构：Bromolow x86_64
- 操作：旧版保持安装，在套件中心选择“手动安装”，直接上传同一套件的递增版本 SPK
- 结果：在该测试环境中，新版成功覆盖旧版；不需要先卸载。

这是一次目标 NAS 上的实测记录，用于说明检查流程确实走过完整覆盖升级。它不代表所有套件、DSM 版本和架构都已经验证。实际排查时应同时核对套件身份、版本元数据、生命周期脚本和持久数据处理，不要把成功归因于某一个脚本。

## 覆盖安装的判断过程

覆盖升级不是简单地把新文件拷到 NAS。DSM 需要先把新版识别为已安装套件的更高版本，然后执行升级生命周期，并处理旧版与新版的文件和持久数据。

### 1. `package` 是套件身份，必须稳定

`INFO` 中的 `package` 是 DSM 使用的套件身份，也决定套件目录 `/var/packages/<package>/`。同一套件的后续版本必须继续使用相同值。更改显示名称 `displayname` 不等于更改身份；不要为了改界面名称而改 `package`。

例如，某套件可以保持：

```ini
package="YourPackageId"
```

### 2. 新版 `version` 必须递增

Synology 的 `INFO` 版本格式由数字段和 `. - _` 分隔符组成，版本构建号应随每次版本递增。不要把 Git 标签里的 `v` 前缀写进 `INFO` 的 `version`。

例如，旧版为 `1.2.0-0001` 时，新版可递增为：

```ini
version="1.2.0-0002"
```

这里的 `0002` 是递增的构建号。发布标签可以写成 `v1.2.0-0002`，打包时再去掉标签的 `v`，写进 SPK 内部的 `INFO`。

### 3. 保持目标平台和套件入口元数据兼容

升级版应继续面向正确的 DSM 版本和架构。若安装包管理页、DSM 桌面入口或端口注册依赖 `adminprotocol`、`adminport`、`adminurl`、`checkport`、`dsmuidir`、`dsmappname` 等字段，除非确实要迁移入口，否则保留原值。

升级版应保持套件身份、`install_type`、旧套件入口字段和 DSM 桌面入口映射兼容。注意：`silent_upgrade="yes"` 只表示允许无向导的后台升级；它不是开启手动覆盖安装的开关。

### 4. 让 DSM 执行升级生命周期

Synology 的升级流程会先停止旧版，然后执行新版 `preupgrade`；随后还会调用旧版 `preuninst`、`postuninst`，再安装新版并执行 `postupgrade`。因此旧版的卸载钩子也可能在**升级期间**运行。

可复用的 `scripts/preupgrade` 示例：

```sh
#!/bin/sh
set -eu

EXPECTED_PACKAGE="YourPackageId"
if [ "${SYNOPKG_PKGNAME:-}" != "$EXPECTED_PACKAGE" ]; then
    echo "Unexpected package identity: ${SYNOPKG_PKGNAME:-unset}" >&2
    exit 1
fi

# 这里只检查升级条件；不要在 preupgrade 中删除或迁移文件。
exit 0
```

可复用的 `scripts/postupgrade` 示例：

```sh
#!/bin/sh
set -eu

VAR="${SYNOPKG_PKGVAR:-/var/packages/YourPackageId/var}"
mkdir -p "$VAR/config" "$VAR/log"
chmod 700 "$VAR/config"

# 只补齐目录和权限；不要用空文件覆盖现有配置、数据库或令牌。
exit 0
```

这两个钩子是生命周期处理点，不会自动让两个不同身份的套件变成可升级关系，也不能代替 `package` 与 `version` 的匹配。

### 5. 升级期间保护持久数据

把用户配置、OAuth 会话、数据库和日志放在 DSM 提供的持久套件变量目录（通常由 `SYNOPKG_PKGVAR` 指向），不要把需要保留的数据只放在随 SPK 替换的程序目录里。

升级期间，旧版 `postuninst` 会运行。若其中存在无条件 `rm -rf "$SYNOPKG_PKGVAR"` 或删除配置目录的代码，升级就可能清掉用户数据。应当在升级状态下跳过卸载清理，或用明确的卸载向导选项区分升级和真正卸载。例如：

```sh
#!/bin/sh
set -eu

if [ "${SYNOPKG_PKG_STATUS:-}" = "UPGRADE" ]; then
    exit 0
fi

# 真正卸载时再根据产品约定和用户选择处理数据。
exit 0
```

应将需要保留的用户状态放在持久变量目录；升级后的脚本只补齐所需目录和权限，不删除或覆盖现有数据。

## 通用检查清单

准备发布 SPK 前，逐项对照旧版和新版：

1. 解包两个 SPK，确认 `INFO` 的 `package` 完全相同。
2. 确认新版 `version` 按 DSM 可识别的格式递增，构建号高于已安装包。
3. 确认新版 `arch`、`os_min_ver` 与目标 NAS/DSM 兼容。
4. 对照套件入口相关字段；不要无意更改 `install_type`、端口、URL 或桌面入口标识。
5. 检查新版 SPK 顶层包含 `INFO`、`package.tgz`、`scripts/`，以及需要的升级脚本。
6. 检查打包脚本复制了 `preupgrade`、`postupgrade` 等脚本，并保留可执行权限。
7. 检查 `postinst`、`postuninst` 和 `postupgrade` 不会在升级时覆盖或删除持久数据。
8. 在目标 DSM 上保留旧版安装，直接通过“手动安装”上传新版 SPK；确认 Package Center 显示升级而不是要求先卸载。
9. 升级后确认套件状态、服务进程、管理入口和配对/配置数据都正常。

CI 可以检查 SPK 结构、元数据和脚本语法，但只有目标 NAS 上保留旧版并实际上传新版，才能验证就地升级。

## 常见误区

| 误区 | 正确理解 |
| --- | --- |
| 把 `silent_upgrade="yes"` 当作手动覆盖升级开关 | 它只控制无向导后台升级行为 |
| 只提高显示版本，不检查 `package` | `package` 才是套件身份，身份变了 DSM 可能无法识别为同一套件 |
| 只加 `preupgrade`/`postupgrade` 就认定能升级 | 钩子处理生命周期；套件身份、版本、平台和入口元数据仍需兼容 |
| `postuninst` 一律清理数据 | DSM 在升级流程中也会运行旧版 `postuninst`，必须避免误删持久数据 |
| 先卸载旧版再装新版来“验证升级” | 这只验证重装，不能证明覆盖升级；并可能丢失保存在套件目录的数据 |
| CI 构建通过就说覆盖升级已解决 | CI 不会运行目标 NAS 的 Package Center，必须实机验证 |

## 应用到其他套件

1. 用套件自己的固定 ID 替换示例中的 `YourPackageId`，不要使用显示名称代替 `package`。
2. 从当前已安装版读取 `INFO`，逐项比较新版字段，并为新版分配更高的版本与构建号。
3. 按套件的数据布局实现 `preupgrade`、`postupgrade` 和 `postuninst`；升级钩子不得误删持久数据。
4. 确认打包过程把脚本放入 SPK 顶层 `scripts/` 并设置可执行权限。
5. 在目标 NAS 保留旧版，通过套件中心“手动安装”直接上传新版，确认实际覆盖升级及数据状态。

## Synology 官方资料

- [INFO 必要字段：`package` 身份与 `version` 格式](https://help.synology.com/developer-guide/synology_package/INFO_necessary_fields.html)
- [套件生命周期脚本及升级执行顺序](https://help.synology.com/developer-guide/synology_package/scripts.html)
- [套件脚本环境变量：`SYNOPKG_PKGVAR`、`SYNOPKG_PKG_STATUS`、升级临时目录等](https://help.synology.com/developer-guide/synology_package/script_env_var.html)
- [`silent_upgrade` 字段说明](https://help.synology.com/developer-guide/synology_package/INFO_optional_fields.html)
