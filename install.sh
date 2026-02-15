#!/usr/bin/env bash
# ============================================================
# Amenti Installer — One-liner install via curl
# Usage: curl -sSL https://raw.githubusercontent.com/raulvidis/amenti/main/install.sh | bash
# ============================================================

set -euo pipefail

REPO="https://github.com/raulvidis/amenti.git"
INSTALL_DIR="${AMENTI_INSTALL_DIR:-$HOME/.amenti}"
BIN_LINK="/usr/local/bin/amenti"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔═════════════════════════════════════════╗"
echo "║         Amenti Installer 🏛️             ║"
echo "║   Persistent memory for AI agents       ║"
echo "╚═════════════════════════════════════════╝"
echo -e "${NC}"

# Check dependencies
echo -e "${CYAN}Checking dependencies...${NC}"

if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: git is required but not installed.${NC}"
    exit 1
fi

if ! command -v sqlite3 &> /dev/null; then
    echo -e "${RED}Error: sqlite3 is required but not installed.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ git${NC}"
echo -e "${GREEN}✓ sqlite3${NC}"

# Clone or update
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${CYAN}Updating existing installation...${NC}"
    cd "$INSTALL_DIR"
    git pull origin main
else
    echo -e "${CYAN}Cloning Amenti to $INSTALL_DIR...${NC}"
    git clone "$REPO" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

# Create bin symlink
echo -e "${CYAN}Linking CLI...${NC}"
if [ -w "/usr/local/bin" ]; then
    ln -sf "$INSTALL_DIR/bin/amenti" "$BIN_LINK"
    echo -e "${GREEN}✓ Linked to $BIN_LINK${NC}"
else
    echo -e "${CYAN}sudo required for /usr/local/bin${NC}"
    sudo ln -sf "$INSTALL_DIR/bin/amenti" "$BIN_LINK"
    echo -e "${GREEN}✓ Linked to $BIN_LINK${NC}"
fi

# Set up config
CONFIG_DIR="$HOME/.config/amenti"
mkdir -p "$CONFIG_DIR"

echo -e "${CYAN}Setting up config...${NC}"
cat > "$CONFIG_DIR/config" << EOF
AMENTI_DB=$HOME/.amenti/amenti.db
AMENTI_AGENT=default
EOF
echo -e "${GREEN}✓ Config created at $CONFIG_DIR/config${NC}"

# Initialize database
echo -e "${CYAN}Initializing database...${NC}"
export AMENTI_DB="$HOME/.amenti/amenti.db"
export AMENTI_AGENT="default"
"$INSTALL_DIR/scripts/init-db.sh"
echo -e "${GREEN}✓ Database initialized${NC}"

# Done
echo ""
echo -e "${GREEN}╔═════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║       Amenti installed! 🏛️              ║${NC}"
echo -e "${GREEN}╚═════════════════════════════════════════╝${NC}"
echo ""
echo -e "Add to your shell profile:"
echo -e "  ${CYAN}export AMENTI_DB=$HOME/.amenti/amenti.db${NC}"
echo -e "  ${CYAN}export AMENTI_AGENT=your_agent_name${NC}"
echo ""
echo -e "Quick start:"
echo -e "  ${CYAN}amenti store --type fact --content \"Hello!\" --confidence 0.95 --tags test${NC}"
echo -e "  ${CYAN}amenti search \"hello\"${NC}"
echo ""
echo -e "For vector embeddings (optional):"
echo -e "  ${CYAN}pip3 install sentence-transformers${NC}"
echo -e "  ${CYAN}pm2 start $INSTALL_DIR/src/embed_server.py --name amenti-embed --interpreter python3${NC}"
echo ""
