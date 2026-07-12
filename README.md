# steamplay

在 macOS 上玩 **Steam 的 Windows 版遊戲** — 一個類似 CrossOver / Whisky 的開源相容層管理工具。

以 [Wine](https://www.winehq.org)（Gcenx CrossOver 建置）為核心，整合 Apple **Game Porting Toolkit（D3DMetal）**、**DXVK/MoltenVK** 圖形轉譯與 **MSYNC/ESYNC** 同步機制，並針對 Apple Silicon Mac（含 Mac mini M 系列）做效能調校。

> **重要觀念**：你在 Mac 上已安裝的是 *macOS 原生版* Steam，它只能玩有 Mac 版的遊戲。Windows 專屬遊戲需要在 Wine 相容層裡執行 *Windows 版* Steam——這正是本工具（以及 CrossOver）做的事。兩者可並存、共用同一個帳號，互不干擾。

## 系統需求

| 項目 | 需求 |
|---|---|
| macOS | 14 Sonoma 以上（**建議 15 Sequoia+**，才有 Rosetta AVX 支援） |
| 硬體 | Apple Silicon（M1–M4，含 Mac mini）或 Intel Mac |
| 磁碟 | 至少 50 GB 可用空間（Wine 環境約 2 GB + 遊戲本體） |
| 其他 | [Homebrew](https://brew.sh) |

## 安裝

```bash
git clone https://github.com/6ng5j8cyyd-netizen/1.git steamplay && cd steamplay
./install.sh
```

## 快速開始（三步驟）

```bash
steamplay setup            # 1. 安裝 Rosetta 2、Wine 引擎、winetricks，建立 Wine prefix
steamplay install-steam    # 2. 下載並安裝 Windows 版 Steam 到相容層中
steamplay steam            # 3. 啟動 Windows 版 Steam，登入帳號後即可下載 Windows 遊戲
```

之後日常使用只需要 `steamplay steam`，在 Steam 介面裡照常下載、啟動遊戲即可。也可以跳過 Steam 介面直接啟動某款遊戲：

```bash
steamplay launch 1091500   # 用 AppID 直接啟動（AppID 可在 steamdb.info 查詢）
```

## 運作原理

```
你的遊戲 (Windows .exe)
   │  Win32 API 呼叫
   ▼
Wine（CrossOver 建置，含 MSYNC）─── Windows API → macOS API 轉譯
   │  DirectX 呼叫
   ▼
圖形轉譯層（三選一，可切換）
   ├─ D3DMetal（Apple GPTK）  DX11/DX12 → Metal   ← DX12 遊戲效能最佳
   ├─ DXVK + MoltenVK         DX9–11 → Vulkan → Metal
   └─ WineD3D                 DX → OpenGL（相容性後備）
   ▼
Metal（Apple GPU 原生 API）
```

x86 指令由 **Rosetta 2** 轉譯到 Apple Silicon；macOS 15 起可透過 `ROSETTA_ADVERTISE_AVX` 支援需要 AVX/AVX2 指令集的新遊戲（本工具預設開啟）。

## 效能調校

### 引擎選擇

| 引擎 | 適合 | 說明 |
|---|---|---|
| `crossover`（預設） | 大多數遊戲 | Gcenx wine-crossover 建置，安裝快、相容性好、含 MSYNC |
| `gptk` | DX12 大作 | Apple Game Porting Toolkit 的 D3DMetal，DX11/12 效能最佳 |

```bash
steamplay setup --engine gptk        # 切換到 GPTK（需 Apple Silicon）
steamplay gptk-libs "/Volumes/Game Porting Toolkit-2.1"   # 安裝 Apple D3DMetal 函式庫
```

（D3DMetal 函式庫因授權限制需自行到 [developer.apple.com](https://developer.apple.com/games/game-porting-toolkit/) 下載 GPTK dmg。）

### 全域設定

```bash
steamplay config show                # 檢視所有設定
steamplay config set HUD 1           # 顯示 Metal 效能 HUD（FPS / GPU 使用率）
steamplay config set SYNC esync      # msync 不穩時改用 esync
steamplay config set RETINA 1        # Retina 原生解析度（畫質優先；預設關閉以提升 FPS）
```

內建的效能預設值：`WINEMSYNC=1`（大幅降低同步開銷）、`WINEDEBUG=-all`（關閉除錯輸出）、`DXVK_ASYNC=1`（非同步 shader 編譯減少卡頓）、Retina 關閉（以較低內部解析度換取 FPS）。

### 每遊戲設定

不同遊戲需要不同調校時，不必動全域設定：

```bash
steamplay game edit 1091500          # 編輯 Cyberpunk 2077 專屬設定
steamplay game list                  # 列出所有已建立的遊戲設定
```

設定檔是簡單的環境變數清單（見 [examples/1091500.env](examples/1091500.env)），啟動該遊戲時自動套用。工具也內建了常見遊戲的已知調校（如 Cyberpunk 2077 自動開 AVX、GTA V 自動改用 esync），並會在啟動已知不相容的反作弊遊戲（PUBG 的 BattlEye 等）時提前警告。

## 相容性修正

遊戲跑不起來時的常用修法：

```bash
steamplay doctor                     # 先做系統診斷
steamplay tweak dxvk                 # DX9–11 遊戲改走 Vulkan/MoltenVK，常可解決畫面問題
steamplay tweak vcrun2022            # 缺 MSVCP/VCRUNTIME DLL
steamplay tweak dotnet48             # 遊戲啟動器需要 .NET
steamplay tweak cjkfonts             # 中文顯示成方塊
steamplay logs                       # 查看最新一次啟動的錯誤記錄
steamplay kill                       # 遊戲卡死時強制關閉所有 Windows 程式
```

## 疑難排解

**Steam 開啟後黑畫面 / 網頁介面空白** — Steam 自我更新中，等 1–2 分鐘；仍不行就 `steamplay kill` 後重開。Steam 預設以 `-noreactlogin -nofriendsui` 啟動以避開已知的 WebView 問題，可用 `steamplay config set STEAM_FLAGS "..."` 調整。

**遊戲啟動即閃退** — 先查 `steamplay logs`。看到 `avx` / `Illegal instruction` 表示需要 AVX：確認 macOS ≥ 15 且 `AVX=1`。看到缺 DLL 就用對應的 `steamplay tweak`。

**FPS 偏低** — 依序嘗試：確認 `RETINA=0`；DX12 遊戲改用 `--engine gptk`；DX9–11 遊戲試 `steamplay tweak dxvk`；遊戲內解析度設為非 HiDPI 的 1920×1080；用 `HUD 1` 觀察瓶頸在 GPU 還是 CPU。

**多人遊戲進不去** — 內含核心層反作弊（EAC/BattlEye）的遊戲在任何 Wine 類工具（含 CrossOver）上都無法上線，屬平台限制而非設定問題。

**環境壞掉想重來** — `steamplay prefix reset`（重要資料先 `steamplay prefix backup`）。

## 指令總覽

執行 `steamplay help` 查看完整指令清單：`setup`、`install-steam`、`steam`、`launch`、`run`、`game`、`tweak`、`gptk-libs`、`config`、`prefix`、`kill`、`logs`、`doctor`。

## 授權

MIT License，見 [LICENSE](LICENSE)。本工具不包含也不散布任何 Valve、Apple 或 CodeWeavers 的專有元件；Wine 依 LGPL 授權由 Homebrew 安裝，D3DMetal 需使用者自行向 Apple 取得。
