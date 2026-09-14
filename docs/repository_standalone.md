# 仓库独立化处理说明

本仓库当前的代码、README 与 App 关于页已按 GXU 独立维护线整理。

## 当前状态（已完成）

仓库独立化与新仓库迁移已经完成，**`main` 是唯一的工作分支和默认分支**：

- `main`：当前唯一分支，所有开发和发布都提交到这里
- `legacy/main-before-standalone`：旧历史备份分支（pre-standalone 的更早提交，保留备查）
- `legacy-history-before-standalone`：旧历史标签，与上面的备份分支同源

2026-09-14 收尾：原先临时用于承载独立历史的 `standalone-main` 已并入 `main` 并删除（本地 + 远端），避免两个分支长期并行造成混淆。旧历史没有丢失，仍在 `legacy/main-before-standalone` 上。

## 复现/重跑独立化脚本

如果需要重新生成一份干净历史（例如给另一个 fork 用），在工作区干净的前提下运行：

```powershell
pwsh ./tool/create_standalone_history.ps1
```

脚本默认产出的分支名由参数 `-StandaloneBranch` 控制，默认 `standalone-main`。注意：本仓库已不再使用该分支名，重跑后请按需改名再推送，不要重新引入并行的长期分支。

## 独立仓库约定

1. 仓库是普通仓库，不是 GitHub fork，避免首页显示上游 fork 关系。
2. 向仓库推送使用 `main`，并保持它是默认分支。
3. README、关于页里的维护者/上游说明随代码一起维护。
4. 保留 `LICENSE` 与源码文件中的版权头。
