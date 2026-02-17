#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$HOME/.start-claude.env"
SETTINGS_FILE="$HOME/.claude/settings.json"

# ==============================================================================
# Create env file if not exists
# ==============================================================================
if [ ! -f "$ENV_FILE" ]; then
    echo "📝 Creating ~/.start-claude.env from template..."
    cp "$PROJECT_DIR/start-claude.env.example" "$ENV_FILE"
    echo "✅ Created $ENV_FILE"
    echo ""
    echo "⚠️  Please edit ~/.start-claude.env and fill in your API keys:"
    echo "   vim ~/.start-claude.env"
    echo ""
    echo "Then run ./install.sh again to apply the configuration."
    exit 0
fi

# Load env file
source "$ENV_FILE"

# ==============================================================================
# Validate required variables
# ==============================================================================
required_vars=(
    "CLAUDE_CLI"
    "MINIMAX_API_KEY" "MINIMAX_BASE_URL"
    "GLM_API_KEY" "GLM_BASE_URL"
    "DEEPSEEK_API_KEY" "DEEPSEEK_BASE_URL"
    "MOONSHOT_API_KEY" "MOONSHOT_BASE_URL"
    "AICODEWITH_ANTHROPIC_API_KEY" "AICODEWITH_ANTHROPIC_BASE_URL"
)

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Error: Required variable $var is not set in $ENV_FILE"
        echo "   Please edit ~/.start-claude.env and fill in all required values."
        exit 1
    fi
done

# ==============================================================================
# Validate Claude CLI Path
# ==============================================================================
echo "🔍 Validating Claude CLI path..."

if [ -x "$CLAUDE_CLI" ]; then
    echo "✅ Claude CLI found at: $CLAUDE_CLI"
elif command -v "$CLAUDE_CLI" &> /dev/null; then
    # CLAUDE_CLI is a command name (like "claude"), not a full path
    actual_path=$(command -v "$CLAUDE_CLI")
    echo "✅ Claude CLI found at: $actual_path"
else
    echo "⚠️  Warning: Claude CLI not found at configured path: $CLAUDE_CLI"
    echo ""
    echo "Attempting to auto-detect Claude CLI..."

    # Try to find Claude CLI
    detected_path=""
    if command -v claude &> /dev/null; then
        detected_path=$(command -v claude)
    elif [ -x "$HOME/.local/bin/claude" ]; then
        detected_path="$HOME/.local/bin/claude"
    elif [ -x "/usr/local/bin/claude" ]; then
        detected_path="/usr/local/bin/claude"
    fi

    if [ -n "$detected_path" ]; then
        echo "✅ Found Claude CLI at: $detected_path"
        echo ""
        echo "To fix this permanently, update ~/.start-claude.env:"
        echo "   CLAUDE_CLI=\"$detected_path\""
        echo ""
        read -p "Press Enter to continue with current configuration... " -r
    else
        echo "❌ Error: Claude CLI not found"
        echo ""
        echo "Please install Claude CLI first:"
        echo "   npm install -g @anthropic-ai/claude-code"
        echo ""
        echo "Then update ~/.start-claude.env with the correct path:"
        echo "   CLAUDE_CLI=\"\$(which claude)\""
        exit 1
    fi
fi

# ==============================================================================
# Create symlink for main script
# ==============================================================================
echo "🔗 Creating symlink ~/start-claude.sh -> $PROJECT_DIR/start-claude.sh"
ln -sf "$PROJECT_DIR/start-claude.sh" ~/start-claude.sh
chmod +x "$PROJECT_DIR/start-claude.sh"
chmod +x ~/start-claude.sh

# ==============================================================================
# Initialize .claude directory and settings.json
# ==============================================================================
if [ ! -d ~/.claude ]; then
    mkdir -p ~/.claude
    echo "✅ Created ~/.claude directory"
fi

if [ ! -f "$SETTINGS_FILE" ]; then
    cat > "$SETTINGS_FILE" << 'EOF'
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "",
    "ANTHROPIC_BASE_URL": "",
    "ANTHROPIC_MODEL": "",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "",
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": 1
  }
}
EOF
    echo "✅ Created default settings.json"
fi

# ==============================================================================
# Install jq if not available
# ==============================================================================
if ! command -v jq &> /dev/null; then
    echo "📦 Installing jq (required for JSON manipulation)..."
    if command -v brew &> /dev/null; then
        brew install jq
    else
        echo "⚠️  Warning: jq not found and brew not available."
        echo "   Please install jq manually: https://stedolan.github.io/jq/download/"
    fi
fi

# ==============================================================================
# Initialize .claude.json (required by some providers)
# ==============================================================================
CLAUDE_JSON_FILE="$HOME/.claude.json"
if [ ! -f "$CLAUDE_JSON_FILE" ]; then
    cat > "$CLAUDE_JSON_FILE" << 'EOF'
{
    "hasCompletedOnboarding": true
}
EOF
    echo "✅ Created ~/.claude.json"
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "📁 Configuration file: $ENV_FILE"
echo "🔗 Main script: ~/start-claude.sh"
echo ""
echo "To change API keys or models:"
echo "  1. Edit ~/.start-claude.env"
echo "  2. Run ./install.sh to apply changes"
echo ""
echo "To start Claude Code:"
echo "  ~/start-claude.sh"
