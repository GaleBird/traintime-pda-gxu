# GXU 研课表 · 文档

面向广西大学研究生的非官方开源校园信息查询应用（代码库名 `watermeter`）。

当前版本：**v1.0.7+51**（版本号以 `pubspec.yaml` 与 [Releases](https://github.com/GaleBird/traintime-pda-gxu/releases) 为准）

> [!IMPORTANT]
> 非官方应用，不代表广西大学官方立场，也不由学校任何部门维护或背书。数据来自学校各信息系统的公开接口，教务口径一律以学校官方系统为准。

## 下载

| 渠道 | 说明 |
| :--- | :--- |
| [官网 gxu.app/downloads](https://gxu.app/downloads/) | **推荐**。国内直链，自动匹配版本与架构 |
| [GitHub Releases](https://github.com/GaleBird/traintime-pda-gxu/releases) | 备用渠道，附发布说明与历史版本 |

预编译包目前**只有 Android**（`arm64-v8a` / `armeabi-v7a` / `x86_64`）。iOS、Linux、Windows 需自行从源码构建，见仓库根目录 [`README.md`](../README.md#构建)。

## 功能概览

- **课表与日程** —— GXU 原生日程表，含上课提醒与通知
- **成绩查询** —— 含学分绩点计算
- **选课情况** —— 选课结果与学位课状态
- **空闲教室** —— 各教学楼栋空闲教室检索
- **校园网用量** —— 网费余额、已用流量与套餐状态
- **工具箱** —— 常用校园入口聚合

上游的 XDU 专有功能（XDU Planet、物理实验、体育系统等）**未接入** GXU 数据源，应用内不提供入口。

## 文档索引

- [常见问题](faq.md) —— 安装、登录、更新、各功能使用与排错
- [涉及到的数据结构](data_structure.md) —— 数据模型说明（部分内容承自上游）
- [仓库独立化处理说明](repository_standalone.md) —— 本仓库与上游的关系、分支与历史约定
- [贡献者名单](contributors.md) —— 上游与历届贡献者致谢
- [XDYou 软件授权协议（上游存档）](xdyou_eula.md) —— **上游 XDYou 的原始协议，非本项目协议**，仅作来源说明保留

## 其他相关链接

- [本项目仓库](https://github.com/GaleBird/traintime-pda-gxu)
- [本项目官网](https://gxu.app)
- [上游项目 Traintime PDA / XDYou](https://github.com/BenderBlog/traintime_pda)
- [问题反馈](https://github.com/GaleBird/traintime-pda-gxu/issues)

## 授权

本项目源代码以 `MPL-2.0` 为主，部分文件带有 `MIT` 或 `Apache-2.0` 授权；具体以文件头部的 `SPDX-License-Identifier` 为准。详见仓库根目录 [`LICENSE`](../LICENSE)。
