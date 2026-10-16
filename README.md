# Helium 修改版（daofeidao）

状态栏小部件工具，给 **巨魔（TrollStore）** 设备用。在 **iPhone 13 Pro Max / iOS 15.6.1** 上真机验证过。

**这是非官方修改版。** 代码来自 [leminlimez/Helium](https://github.com/leminlimez/Helium)（原作者，仓库已归档）
和接手更新的 [AsakuraFuuko](https://github.com/AsakuraFuuko)。本仓库在上游最后一个提交的基础上重建，
只加下面写出来的这些改动。

> 有问题请**在本仓库开 issue**，不要去打扰原作者或 Fuuko —— 他们没参与这个修改版，也不知道它改了什么。

## 怎么装

1. 到 [Releases](https://github.com/daofeidao/Helium-Rebuild/releases) 下载最新的 `Helium.tipa`
2. 用 TrollStore 打开安装（**覆盖安装，设置不丢**）
3. **打开一次 App** —— 第一次打开时它会自动把还在跑旧代码的 HUD 进程换掉（见下面「HUD 是独立进程」）

bundle id 一直是 `com.leemin.helium`，所以从上游版本升上来也是覆盖安装。

## 和上游比，改了什么

| 版本 | 改动 |
|---|---|
| V1.0 | 四个偏移滑块的行程从 ±300 收到 **±100**（再远就是跑到屏幕外）；设置页显示装的是哪一版 |
| V2.0 | **文字光晕**：描边（清晰）+ 发光（柔和），各自独立开关 / 宽度 / 颜色 |
| V3.0 | 修掉上游 6 位色板「所有颜色都变成青色」的解析 bug；描边宽度上限 2、光晕上限 6；色板换成 8 个区分度高的颜色；偏移滑块两侧加三角微调（每次 ±0.2，松手即存）；光晕栏加「没效果就重启 HUD 开关」备注 |
| V3.1 | **装了新包自动换 HUD 进程**；**内容没变就不重绘**（省掉每秒重排文字和模糊背景重新采样） |
| V3.2 | **偏移方向修正**：Y 的两个三角接反了（按下反而往上跑）；贴右边的部件 X 方向是反的 —— 现在统一成「正数 = 往右 / 正数 = 往下」，旧数据一次性取反以保住原位置 |
| V3.3 | 设置页版本行改成 `版本 3.2.6（daofeidao修改版V3.3发布）`；补上开源门面（本 README） |

每条改动「为什么这么做」都写在对应的 commit message 里，想看推理过程可以直接翻提交记录。

## 几个要知道的点

- **HUD 是独立进程**：App 用 `posix_spawn` 拉起 `Helium -hud`，用 `Caches/hud.pid` 管它。
  **装新包不会替换已经在跑的那个进程**，所以改了 HUD 侧的代码，得让进程重启才看得到效果。
  从 V3.1 起，App 打开时会自己比对（HUD 启动时记下自己可执行文件的 mtime+size）并自动重启一次，
  首页会写明结果；手动做法是首页 HUD 开关关掉再打开，或者注销手机。
- **版本号**：`CFBundleShortVersionString` 固定在上游的 `3.2.6`。苹果要求这个字段是点分数字，
  往里面塞中文是「能装上但会让系统各处版本比较出错」那种坑，所以修改版标记只写在设置页显示上。
- **构建**：本机没有 Mac / Xcode，编译走 GitHub Actions（`macos-14` + theos）。
  上游的 `./ipabuild.sh` 与 `Makefile` 原样可用；`release.yml` 里有产物自检（bundle id、版本号、
  两个语言的文案、授权项、体积）。
- **设置文件在 App 容器外**：`/var/mobile/Library/Preferences/com.leemin.helium.plist`，
  所以删掉 App 再装回来，设置还在（实测 TrollStore 卸载不会删它）。
- 光晕只向字形**外**发散：它不是画在文字上，而是另开一层同样的文字画在下面，被字形自己盖住内向的那半 ——
  所以「不啃字形」不依赖对 CoreText 描边方向的任何假设。

## 许可

GPL-3.0（与上游一致）。**版权归属**：上游代码归 leminlimez 及各位贡献者所有，
本仓库的改动同样以 GPL-3.0 发布。再分发请保留版权声明与许可全文（见 [LICENSE](LICENSE)）。

## 致谢

- [leminlimez/Helium](https://github.com/leminlimez/Helium) —— 原始项目
- [AsakuraFuuko](https://github.com/AsakuraFuuko) —— 接手更新
- [TrollSpeed](https://github.com/Lessica/TrollSpeed) —— AssistiveTouch 相关逻辑
- [Cowabunga](https://github.com/leminlimez/Cowabunga) —— 部分代码

## English summary

An unofficial mod of **[Helium](https://github.com/leminlimez/Helium)** — status bar widgets for
TrollStore devices — rebuilt from the last upstream commit. It adds a text halo (an outline and a
glow, drawn on a label behind the text so it can only spread outwards and never eats the glyph), a
HUD process that is replaced when a new build is installed, no repaint when nothing about a widget
has changed, and offset sliders that move the widget the way the arrows point, with a one-time
migration so saved values keep their position on screen. It also fixes the six-digit branch of
`Color(hex:)`, which turned every six-digit colour cyan, and the offset range (±100 instead of ±300,
past which a widget is off the screen anyway).

Verified on an iPhone 13 Pro Max on iOS 15.6.1 (TrollStore, no jailbreak). Installs over the
upstream build: the bundle id is unchanged.

Licensed **GPL-3.0**, same as upstream; the copyright of the original code stays with its authors.
Please open issues **here** rather than with the upstream maintainers — they had nothing to do with
this build. Every change carries its reasoning in the commit message it arrived in.
