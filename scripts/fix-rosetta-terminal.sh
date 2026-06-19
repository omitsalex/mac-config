#!/usr/bin/env bash
# Fix Terminal/iTerm2 running under Rosetta 2

echo "Fix Terminal/iTerm2 Rosetta Mode"
echo ""

CURRENT_ARCH="$(uname -m)"
REAL_ARCH="$(sysctl -n machdep.cpu.brand_string)"

if [[ "$REAL_ARCH" =~ "Apple" ]]; then
  echo "Detected: Apple Silicon ($REAL_ARCH)"

  if [ "$CURRENT_ARCH" == "arm64" ]; then
    echo "Terminal is running in native ARM64 mode — no action needed."
  else
    echo "WARNING: Terminal is running under Rosetta 2 (x86_64 mode)"
    echo ""
    echo "To fix this:"
    echo ""
    echo "For Terminal.app:"
    echo "  1. Quit Terminal completely"
    echo "  2. Open Finder -> Applications -> Utilities"
    echo "  3. Right-click Terminal.app -> Get Info"
    echo "  4. UNCHECK 'Open using Rosetta'"
    echo "  5. Restart Terminal"
    echo ""
    echo "For iTerm2:"
    echo "  1. Quit iTerm2 completely"
    echo "  2. Open Finder -> Applications"
    echo "  3. Right-click iTerm2.app -> Get Info"
    echo "  4. UNCHECK 'Open using Rosetta'"
    echo "  5. Restart iTerm2"
    echo ""
    echo "Then run this script again to verify."
  fi
else
  echo "Detected: Intel Mac ($CURRENT_ARCH) — no Rosetta issues."
fi
