#!/usr/bin/env bash
#
# steamplay 安裝程式
# 用法：curl -fsSL https://raw.githubusercontent.com/6ng5j8cyyd-netizen/1/main/install.sh | bash
# 或在 repo 目錄內直接執行：./install.sh
#
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/6ng5j8cyyd-netizen/1/main"
BIN_DIR="${STEAMPLAY_BIN_DIR:-/usr/local/bin}"

[[ "$(uname -s)" == "Darwin" ]] || { echo "steamplay 只能在 macOS 上執行。" >&2; exit 1; }

if [[ ! -w "$BIN_DIR" ]]; then
    BIN_DIR="$HOME/.local/bin"
    mkdir -p "$BIN_DIR"
fi

src_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [[ -n "$src_dir" && -f "$src_dir/steamplay" ]]; then
    install -m 0755 "$src_dir/steamplay" "$BIN_DIR/steamplay"
else
    curl -fsSL "$REPO_RAW/steamplay" -o "$BIN_DIR/steamplay"
    chmod +x "$BIN_DIR/steamplay"
fi

echo "steamplay 已安裝到 $BIN_DIR/steamplay"
case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) echo "請將 $BIN_DIR 加入 PATH，例如：echo 'export PATH=\"$BIN_DIR:\$PATH\"' >> ~/.zshrc" ;;
esac
echo
echo "下一步："
echo "  steamplay setup           # 安裝 Wine 引擎"
echo "  steamplay install-steam   # 安裝 Windows 版 Steam"
echo "  steamplay steam           # 開始玩！"
