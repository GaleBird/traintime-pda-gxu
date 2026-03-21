# Repository Guidelines

## Project Structure & Module Organization
This repository is a multi-platform Flutter app (Android, iOS, Linux, Windows) with feature-first organization.

- `lib/page/`: UI pages by feature (for example `classtable`, `score`, `library`, `setting`).
- `lib/repository/`: data/session layer for campus services and API integration.
- `lib/model/`: typed data models (`xidian_ids`, `xdu_planet`, etc.).
- `lib/controller/`: state and interaction controllers.
- `lib/generated/` and `lib/bridge/*.g.dart`: generated code; do not hand-edit.
- `assets/`: images, i18n YAML files, and ML model files (`*.tflite`).
- `tool/generators/`: custom `build_runner` generators.
- `test/`: Flutter tests.
- Platform folders: `android/`, `ios/`, `linux/`, `windows/`.

## Build, Test, and Development Commands
Prefer the repo-pinned Flutter SDK in `.flutter/` (initialized as a submodule):

```bash
git submodule update --init --recursive
.flutter/bin/flutter pub get
.flutter/bin/flutter analyze
.flutter/bin/flutter test
dart run build_runner build --delete-conflicting-outputs
.flutter/bin/flutter run -d windows   # or android/ios/linux
```

Build examples:

```bash
.flutter/bin/flutter build apk --split-per-abi
.flutter/bin/flutter build linux --release
.flutter/bin/flutter build windows --release
```

## Coding Style & Naming Conventions
- Lint baseline: `analysis_options.yaml` (`flutter_lints`).
- Use 2-space indentation and run `dart format lib test tool` before commit.
- File names: `snake_case.dart`; classes/types: `PascalCase`; members: `lowerCamelCase`.
- Keep feature logic close to its module (`page` + corresponding `repository`/`model`).

## Testing Guidelines
- Primary framework: `flutter_test`.
- Place tests in `test/` and name files `*_test.dart`.
- Prefer focused widget/unit tests for parsing, state transitions, and failure paths.
- Run locally with `.flutter/bin/flutter test` before opening a PR.

## Commit & Pull Request Guidelines
- Follow existing commit style seen in history: `feat:`, `fix:`, `chore:`.
- Keep subject lines short and specific (English or Chinese is acceptable).
- PRs should include:
  - clear change summary,
  - affected modules/paths,
  - screenshots or recordings for UI changes,
  - verification steps/commands executed.

## Security & Configuration Tips
- Never commit signing keys, `android/key.properties`, or any secrets.
- Use CI secrets/env vars for credentials and release tokens.
- If generated files are stale, regenerate with `build_runner` instead of manual edits.

## Session Handoff
- After each completed code change, update this `AGENTS.md` with durable behavior changes, local build/install caveats, and any project-specific routing decisions that a new Codex session must inherit.
- Do not write transient investigation notes here; only keep facts that affect future edits, builds, debugging, or user-visible behavior.

## Current Project Notes
- This repository is now treated as a GXU-only fork. When user-facing behavior still reflects XDU defaults, replace them with GXU behavior instead of keeping dual-school branches or XDU reference templates, unless the user explicitly asks to preserve XDU behavior for a specific path.
- Historical XDU logic may still exist in code, but future edits should prefer direct GXU replacement over compatibility layers. Earlier notes about keeping XDU reference entries or a shared dual-school login flow are obsolete.
- App startup now forces `Preference.isGxuMode = true`; do not reintroduce user-facing XDU/GXU mode switching unless the user explicitly asks for multi-school support again.
- `LoginWindow` is GXU-only again and should log in through `GxuCASession` directly; the temporary school-mode selector and XDU login branch have been removed.
- `LoginWindow` 现支持“账号密码 / 短信验证码”两种统一认证登录：短信登录会把手机号缓存到 `Preference.gxuCaPhone`，但不会覆盖 `Preference.idsAccount`；当 Cookie 过期且缺少账号/密码时，`GxuCASession.ensureYjsxtLoggedIn` 会显式报错提示重新登录。
- 短信登录里的短信验证码输入框保持明文显示，不再用密码样式隐藏数字。
- Login branding is GXU-only now: the login page header no longer shows the old app icon or text header, and instead uses the transparent SVG asset `assets/gxu_name.svg` derived from the repo-root `name.svg`. Keep the login page background plain and avoid reintroducing the rejected gradient/glow treatment.
- The login page should use a fixed non-scroll layout, keep the whole content block slightly higher on the screen instead of vertically centering it, and still subtract `viewInsets.bottom` from the portrait visible height so short screens keep the login button reachable above the keyboard. Password login uses explicit focus-node handoff from account to password so the keyboard `下一项` button does not dismiss the keyboard, password/SMS-code fields trigger login from the keyboard action button, and password login keeps the original GXU behavior of always persisting `idsAccount` and `idsPassword` after a successful login.
- The SMS login row should stay on one line with an approximately `2:1` width split between the verification-code field and the `获取短信` button; do not switch it back to a stacked layout unless the user asks again.
- App 启动首页入口现在走 `StartupGate`：有缓存账号密码时直接进首页；若仅缓存了短信登录手机号，则先校验 `GxuCASession.isYjsxtLoggedIn()` 再决定进首页还是登录页，避免会话仍有效时先闪出登录页。
- `ToolBoxPage` should keep the GXU `网络查询` entry first with the Wi-Fi icon. Remaining GXU-unadapted toolbox items should be shown as `（未完成）` placeholders that open the in-app unfinished page instead of any XDU website. The old XDU `网络查询`, `移动门户`, `物理计算`, and `睿思导航` toolbox entries are removed.
- GXU homepage bottom navigation keeps four tabs in order: 首页 / 工具箱 / 猪图鉴赏 / 设置. `PigPage` remains a real page backed by `pighub.top`; do not remove the pig tab again unless the user explicitly asks to drop it.
- The `订水系统` / `后勤报修` / `空间预约` unfinished toolbox placeholders now each have their own teaser copy instead of sharing the generic unfinished message; `缴费系统` keeps the generic unfinished copy.
- GXU mode now also exposes a native homepage schoolnet card and a native single-page network detail screen; do not hide the schoolnet card on the GXU homepage anymore.
- GXU native network query uses `Preference.idsAccount` as the account and `Preference.schoolNetQueryPassword` as the standalone Dr.COM self-service password. Login flow must try password-only submission first, and only fall back to captcha login when the server still rejects the session; captcha OCR should remain a fallback path instead of the default path.
- GXU network query is cache-first: app startup and homepage refresh must preload/show the last successful cached `GxuNetworkUsage` instead of auto-refreshing `self.gxu.edu.cn`, and users refresh manually from the GXU network detail page when they want live data.
- GXU homepage schoolnet card now summarizes used traffic in `GB` and shows relative cache age; the GXU detail page should keep showing cached data plus refresh-status hints even if a later refresh fails.
- GXU network detail refresh must release `gxuNetworkRefreshing` even on early exits such as missing query password or missing account, otherwise the refresh button stays disabled until app restart after the user fixes the input.
- GXU dashboard parsing is label-based around `下次结算 / 已用流量 / 免费流量 / 可用流量 / 消费保护 / 账户余额`; if those labels disappear, surface an explicit page-structure error instead of silently faking data.
- GXU homepage current/next-course logic must not switch to "tomorrow" before 22:05, because GXU晚课会持续到第 13 节结束。
- GXU classtable top week row ("第x周") uses compact height (56) on tall screens to avoid squeezing period time labels.
- GXU classtable now uses a segmented block layout with `午休/晚休` separators; `晚休` maps to periods 9-10, and the evening section shows periods 11-13 after it.
- GXU classtable does not use vertical scrolling; the left period column shows start time on top and end time at bottom for each period.
- GXU classtable left period column adds subtle row dividers, with start time emphasized and end time deemphasized to improve boundary readability.
- GXU homepage pull-to-refresh is a user-requested remote sync: it must call `ClassTableController.updateClassTable(isForce: true)` instead of reusing the 2-day cache window, and the success toast may only appear when `ClassTableController.error == null`; cached fallback after a refresh failure must surface the failure message instead of pretending refresh succeeded.
- `Preference.classTableCacheMode` exists to prevent reuse of stale XDU cache while the codebase is still being cleaned into a GXU-only fork.
- When GXU class-table refresh falls back to same-mode cache after a login/refresh error, `ClassTableController.state` remains `fetched` but `error` preserves the refresh failure so startup flow can avoid showing a false "已加载" toast.
- GXU semester switching must read the real graduate-system `select[name="xqdm"]` options instead of synthesizing year/term wheels. `GxuClasstableSession.getClassTable()` must honor `Preference.currentSemester` whenever `Preference.isUserDefinedSemester` is true.
- Historical GXU semesters currently estimate `termStartDay` from the semester code only: autumn uses the first Monday of September in the start year, spring uses the first Monday of February in the end year. Course filtering is real, but historical date labels are approximate unless a future change finds an official term-start source.
- GXU class-table course loading must paginate `/yjs/py/xkgl/xkmdcx/findXkmdByXsPage`; the graduate system can split cross-semester course rows across multiple pages, so a single request is incomplete.
- GXU now has a native score page again. Keep `ScoreCard` visible on the GXU homepage, route `ScoreWindow` to the GXU-specific page in GXU mode, and use `GxuScoreSession.isCacheExist` for offline gating instead of XDU `ScoreSession`.
- GXU homepage `ScoreCard` must not block entry with the old XDU `offline` flag from `ids_session.dart`; GXU users should be allowed into the score page even when that XDU login state is not `success/manual`, and the score page itself should surface the real GXU fetch/login error.
- GXU homepage toolbox now shows `成绩查询` and `选课情况` side by side; `选课情况` routes to `GxuCourseSelectionWindow` and pulls the selected-course list from `/yjs/py/xkgl/xkmdcx/findXkmdByXsPage` (includes courses without grades, grouped by semester, with degree/non-degree filters). It caches to `gxu_course_selection.json`, which settings cache-clearing must also delete.
- GXU degree-course classification must treat `非学位*` as non-degree (do not use naive `contains("学位")`), with `englishCourseType == "D"` as fallback when Chinese type text is empty.
- The GXU score archive card should stay compact: keep the identity block compressed to a few lines, place summary metrics in a tight right-side/two-row panel, and avoid reintroducing a tall hero card that pushes the course list below the fold on phone screens.
- GXU native score page should preserve the old "selected courses for calculation" workflow: use a calculate FAB to enter selection mode, let score cards toggle selection in that mode, and show the selected-course credit/average/GPA summary in a bottom bar instead of dropping that capability from the GXU implementation.
- GXU native score data comes from the transcript-preview flow, not the generic template list. The fetch order is `/yjs/py/kcpj/loadJxzlpj` -> `/yjs/py/cjgl/cjdpldy/checkdDycjd` -> `/yjs/py/cjgl/cjdpldy/getCjddyyl`, and the cache file name is `gxu_scores.json`, which settings cache-clearing must also delete.
- App startup bootstrap should stay minimal: keep support-path / preferences / forced GXU mode / package info before `runApp`, but defer cache warmup and notification-service initialization until after the first frame so the native splash is not stretched by non-critical async work.
- Android local size comparisons must use `release` artifacts, ideally `.flutter/bin/flutter build apk --release --split-per-abi`; `build/app/outputs/flutter-apk/app-debug.apk` is a fat debug package and can be around 242 MB because it includes `kernel_blob.bin`, all ABIs, and debug native libraries.
- `pubspec.yaml` 的 `version` 可保持 GXU 品牌语义版本（如 `1.0.0`），但 `+build` 必须单调递增（当前基线至少 `+41`），否则同包名安装会因 versionCode/build number 回退而覆盖失败。
- `StartupGate` still validates SMS-login sessions remotely when a phone number is cached, but `GxuCASession.isYjsxtLoggedIn()` should return `false` immediately when the local GXU cookie jar is empty instead of waiting on a network probe.
- On this Windows machine, Android SDK should use `D:\Android\Sdk`.
- The repository has been moved to the ASCII path `D:\c++\cliProxyApi\CLIProxyAPI_6.6.58_windows_amd64\course_schedule\traintime_pda`; use this real path directly for Flutter and Android commands.
- The old `D:\ttascii` junction and temporary `X:` drive workaround are obsolete after the path rename; if they exist and no process is using them, they can be removed.
- For app-facing code changes, default to rebuilding a debug APK and installing it to the connected phone `3B1F56E9B8L7YW34` with `D:\Android\Sdk\platform-tools\adb.exe` unless the user explicitly says not to.
- `flutter_launcher_icons` is currently only configured for Android and iOS. Before regenerating Android launcher icons, remove stale `android/app/src/main/res/mipmap-*/ic_launcher.webp` and `android/app/src/main/res/mipmap-*/ic_launcher_round.webp` (otherwise Gradle can fail with duplicate launcher-icon resources). Keep only one `ic_launcher_background` color definition (prefer `android/app/src/main/res/values/colors.xml` and delete legacy `android/app/src/main/res/values/ic_launcher_background.xml` if it exists).
- iOS widget build must keep real colorset names: in `ios/Runner.xcodeproj/project.pbxproj`, the `ClasstableWidget` target settings `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME` and `ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME` must be `AccentColor` / `WidgetBackground` (not `AppIcon`), otherwise asset-catalog compilation will fail.
- On this Windows machine, Android debug builds can hit Kotlin incremental-cache path-root crashes between the `D:` repo and the `C:` pub cache; keep `kotlin.incremental=false` and `kotlin.compiler.execution.strategy=in-process` in `android/gradle.properties`.
- On this Windows machine, `flutter build windows` currently fails with `Unable to find suitable Visual Studio toolchain`; Windows icon resources can still be updated in source, but a new desktop executable cannot be produced until the Visual Studio C++ toolchain is installed.
- Catcher2 error reporting now uses `EmailManualHandler(["2484895358@qq.com"])` and also appends every report to `${supportPath}/logs/catcher_reports.log` via `FileHandler(handleWhenRejected: true)`, so local crash logs are kept even when the user cancels the mail send flow.
- For iterative Android UI debugging on the connected phone, prefer a persistent `flutter run` session from the real ASCII repo path so Dart-only changes can use hot reload/hot restart instead of reinstalling the APK every time.
- `codex resume` filters sessions by `session_meta.payload.cwd`; after any repo path rename, historical session `.jsonl` files under `C:\Users\彭于晏\.codex\sessions\` may need their stored path prefix updated from the old repo path to the new one, otherwise they will only appear with `codex resume --all`.
- 设置/关于页的 fork 信息（维护者/仓库/上游）统一维护在 `lib/repository/fork_info.dart`；改品牌或仓库地址优先改这里。
- App 检查更新现在直接读取当前仓库的 GitHub `latest release`，实现位于 `lib/repository/pda_service_session.dart`；不要再接回旧的 `legacy.superbart.top/traintime_pda_backend` 版本接口。
- 更新版本比较现在同时比较 `pubspec.yaml` 的语义版本和 `+build`；发布 tag 应与 `pubspec.yaml` 版本完全一致，格式优先使用 `v1.0.1+41` 这类带 build 号的 tag，否则应用内更新提示可能无法正确判断新旧版本。
- Android 更新弹窗优先打开与设备 ABI 匹配的 GitHub Release APK 资产，若 release 中没有 APK 资产才回退到 release 页面；维护下载来源时不要恢复 F-Droid 旧链接逻辑。
- GitHub Android 发版工作流现在由 tag push 自动触发，配置文件是 `.github/workflows/release_for_android.yaml`，触发规则为 `v*`；常规发版流程应是：先更新 `pubspec.yaml` 版本、提交并推送 `main`，再创建并推送同版本 tag，让 GitHub Actions 构建并上传 split-per-ABI APK 到 Release。
- Android 发版工作流已切到 `actions/checkout@v4` / `actions/setup-java@v4`，并显式启用 Node 24；若 GitHub Actions 再次在 `Build APK` 失败，优先下载失败时自动上传的 artifact `android-release-build-log` 看完整构建日志，不要只看 annotations 里的摘要。
- 当前 Android Release CI 的真实坑点不是 Node 警告，而是 release 签名：若日志出现 `KeytoolException` / `Tag number over 30 is not supported`，多数是 keystore 类型或内容不匹配导致解析失败。工作流会在 `JKS` / `PKCS12` 间自动探测 `storeType` 并写入 `android/key.properties`；若两种类型都无法通过 `keytool -list` 校验，则优先检查 `SIGNING_KEY` 是否为 keystore 文件二进制的 base64（只能编码一次），以及 `SIGNING_PASSWORD` / `SIGNING_ALIAS` 是否正确。
- Android 发版工作流会在签名步骤前创建并持续追加 `build_apk.log`；失败时 artifact 上传不会再出现 “No files were found with the provided path: build_apk.log” 的噪音警告。注意 GitHub 上的 “Re-run jobs” 会复用旧 commit 的 workflow 文件，不会应用后来提交的工作流修复；需要重新推 tag 或用 `workflow_dispatch` 对最新 commit 触发一次新运行。
- 这台机器当前没有 `gh` 命令；若用户要“上传 APK 到 GitHub”，优先走“push tag 触发 GitHub Actions release”而不是依赖本地 GitHub CLI 直传。
- `tool/generators/generate_gxu_launcher_icon.py` 现在用于把任意源图标准化为实际打包使用的 `assets/gxu.png`；需要替换品牌图时，优先运行该脚本并通过 `--source` 指向新图片，再执行 `flutter_launcher_icons` / `flutter_native_splash`。
- 当前 launcher/splash 图标源图已切到 `assets/Gemini_Generated_Image_2dp0k82dp0k82dp0.png`，并通过 `tool/generators/generate_gxu_launcher_icon.py --source assets/Gemini_Generated_Image_2dp0k82dp0k82dp0.png` 生成 `assets/gxu.png`；后续若重跑图标生成流程，默认以该源图为基准。
- 设计上下文已写入仓库根目录 `.impeccable.md`，后续界面/品牌类改动遵循“校园自然系：西大绿 + 米白 + 金色点缀”。
- `PigPage` 仍是首页底部导航的正式入口；不要再移除“猪图鉴赏”，除非用户明确要求。
- GXU 选课情况页的学期筛选改为显式下拉框，入口文案要让用户直接看出“这里可以选学期”；选课概览保持信息优先的卡片式汇总。
- GXU 选课情况页顶部概览和筛选区保持紧凑，避免“选课概览”和搜索区占据过高首屏；搜索框提示文案用简短表达即可。
- GXU 选课卡片不展示上课时间文本，课程标题下方优先展示老师姓名；若接口返回多个老师，只显示第一个老师名称。
- GXU 选课情况页的概览统计默认使用紧凑标签式汇总，不再保留手机端大号统计块；筛选区里的课程类型筛选直接平铺在面板内，不要再额外套一层大容器。
- GXU 选课情况页的课程类型筛选使用单行分段按钮（全部/学位课/非学位课），不要再做成两行标题 + Chip 的大块布局。
- GXU 选课情况缓存策略不再固定 15 分钟：自动进入页面时需读取研究生系统首页 `/yjsjbxx/init/index/page` 的 `xuankeDate.STATUS`。`进行中/未开始` 自动缓存 24 小时，`已结束` 则持续使用本地缓存直到用户手动刷新；页面刷新按钮必须继续强制拉取远端最新数据。
- GXU 课表卡片现在要优先保证上课地点能完整看清：地点文本改为多行自适应并在极端长度时压缩显示，老师信息只在卡片高度足够时再追加展示；若老师字段包含多人，只展示第一个老师名称。
- GXU 课表卡片里的上课地点继续保持强调显示：地点区域使用更强的字重和浅色底块标签样式，视觉层级要明显高于老师信息。
- GXU 日程表不再显示“非本周 / 回到本周”状态入口；周次切换只保留顶部周次条与左右滑动。日期行需保持紧凑，当前日期高亮时也不能出现 RenderFlex 溢出。
- 关于页不再展示“应用图标”概念入口；旧概念资源 `assets/icon_gxu_concept.svg` 仍可留作品牌素材，但默认不出现在设置页。
- “知道更多”页采用“维护者优先，但明确标注上游开源来源”的结构：首屏先展示当前维护者，再展示当前版本贡献、项目/仓库入口和开源许可；不要把它做成纯法律说明页或只强调个人品牌。
- 关于页致谢区改为纯文字表达，使用“感谢原开发团队与贡献者”这类文案即可；不要再恢复贡献者头像墙或把这块写成“当前 GXU 版本全部由这些人共同维护”的表述。
- README 首屏与 App 关于页统一按“GXU 独立维护线”对外呈现：明确当前版本面向广西大学研究生、当前维护者优先展示、明确标注上游项目名 `Traintime PDA / XDYou`，同时保留 LICENSE 与源码版权头说明；仓库独立化历史处理使用 `tool/create_standalone_history.ps1`，不要在脏工作区直接手改主分支历史。
