#!/bin/bash

# Claude Code Multi-API Provider Launcher
# This script allows you to switch between different AI API providers
# when starting Claude Code CLI.
#
# Configuration is loaded from ~/.start-claude.env
# To update configuration: Edit ~/.start-claude.env and run ./install.sh

set -euo pipefail

# ==============================================================================
# Load Configuration
# ==============================================================================
ENV_FILE="$HOME/.start-claude.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: Configuration file not found at $ENV_FILE"
    echo ""
    echo "Please run install.sh to set up your configuration:"
    echo "  cd <project-directory>"
    echo "  ./install.sh"
    exit 1
fi

source "$ENV_FILE"

# ==============================================================================
# Validate Required Variables
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
# Resolve Claude CLI Path
# ==============================================================================
resolve_claude_cli_path() {
    # Tier 1: Validate configured path
    if [ -n "$CLAUDE_CLI" ] && [ -x "$CLAUDE_CLI" ]; then
        # Configured path is valid and executable
        return 0
    fi

    # Tier 2: Auto-detect Claude CLI
    local detected_path=""

    # Method 1: Check if 'claude' is in PATH
    if command -v claude &> /dev/null; then
        detected_path=$(command -v claude)
    fi

    # Method 2: Check common installation locations
    if [ -z "$detected_path" ]; then
        local common_paths=(
            "$HOME/.local/bin/claude"
            "/usr/local/bin/claude"
            "$HOME/.npm-global/bin/claude"
            "/opt/homebrew/bin/claude"
        )

        for path in "${common_paths[@]}"; do
            if [ -x "$path" ]; then
                detected_path="$path"
                break
            fi
        done
    fi

    # Method 3: Search nvm directories (if nvm exists)
    if [ -z "$detected_path" ] && [ -d "$HOME/.nvm/versions/node" ]; then
        for nvm_path in "$HOME/.nvm/versions/node"/*/bin/claude; do
            if [ -x "$nvm_path" ]; then
                detected_path="$nvm_path"
                break
            fi
        done
    fi

    # If detected, use it with a warning
    if [ -n "$detected_path" ]; then
        echo "⚠️  Warning: Configured CLAUDE_CLI path is invalid: $CLAUDE_CLI"
        echo "   Auto-detected Claude CLI at: $detected_path"
        echo "   Using detected path for this session."
        echo ""
        echo "   To fix permanently, update ~/.start-claude.env:"
        echo "   CLAUDE_CLI=\"$detected_path\""
        echo ""
        CLAUDE_CLI="$detected_path"
        return 0
    fi

    # Tier 3: Error with guidance
    echo "❌ Error: Claude CLI not found"
    echo ""
    echo "Configured path is invalid: $CLAUDE_CLI"
    echo ""
    echo "Troubleshooting steps:"
    echo "1. Check if Claude CLI is installed:"
    echo "   which claude"
    echo ""
    echo "2. If installed, update ~/.start-claude.env with the correct path:"
    echo "   CLAUDE_CLI=\"\$(which claude)\""
    echo ""
    echo "3. If not installed, install Claude CLI:"
    echo "   npm install -g @anthropic-ai/claude-code"
    echo ""
    echo "4. Then run ./install.sh to validate the configuration"
    exit 1
}

# Resolve Claude CLI path before proceeding
resolve_claude_cli_path

# ==============================================================================
# Configuration Paths
# ==============================================================================
SETTINGS_FILE="$HOME/.claude/settings.json"
BACKUP_FILE="$HOME/.claude/settings.json.bak"
CLAUDE_JSON_FILE="$HOME/.claude.json"

# ==============================================================================
# Backup and Initialize Configuration Files
# ==============================================================================
if [ ! -d ~/.claude ]; then
    mkdir -p ~/.claude
    echo "✅ Created .claude folder in ~/"
fi

# Backup current settings
if [ -f "$SETTINGS_FILE" ]; then
    cp "$SETTINGS_FILE" "$BACKUP_FILE"
    echo "✅ Backed up current settings to $BACKUP_FILE"
else
    # Create default settings.json with model mapping variables
    cat > "$SETTINGS_FILE" << EOF
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
    echo "✅ Created default settings.json in ~/.claude"
fi

# Initialize .claude.json file (required by some providers)
if [ ! -f "$CLAUDE_JSON_FILE" ]; then
    cat > "$CLAUDE_JSON_FILE" << EOF
{
    "hasCompletedOnboarding": true
}
EOF
    echo "✅ Created .claude.json in ~/"
fi

# ==============================================================================
# MENU DISPLAY
# ==============================================================================
clear
echo "╔════════════════════════════════════════════════════════════╗"
echo "║        Claude Code - API Provider Selection Menu          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Select an API provider:"
echo ""
echo "  1) Zhipu (智谱) API (GLM-4.5-Air/GLM-4.7/GLM-5)"
echo "  2) MiniMax API (abab6-chat/abab5.5-chat)"
echo "  3) Moonshot (Kimi) API (moonshot-v1-128k/32k/8k)"
echo "  4) DeepSeek API (deepseek-coder-v2/v1.5/light)"
echo "  5) Default (Anthropic) (claude-3-opus/sonnet/haiku)"
echo ""
read -p "Enter your choice (1-5): " choice

# ==============================================================================
# PROVIDER SELECTION
# ==============================================================================
SELECTED_API_KEY=""
SELECTED_BASE_URL=""
SELECTED_OPUS_MODEL=""
SELECTED_SONNET_MODEL=""
SELECTED_HAIKU_MODEL=""
PROVIDER_NAME=""

case $choice in
    1)
        SELECTED_API_KEY="$GLM_API_KEY"
        SELECTED_BASE_URL="$GLM_BASE_URL"
        SELECTED_OPUS_MODEL="$GLM_OPUS_MODEL"
        SELECTED_SONNET_MODEL="$GLM_SONNET_MODEL"
        SELECTED_HAIKU_MODEL="$GLM_HAIKU_MODEL"
        PROVIDER_NAME="Zhipu (智谱)"
        ;;
    2)
        SELECTED_API_KEY="$MINIMAX_API_KEY"
        SELECTED_BASE_URL="$MINIMAX_BASE_URL"
        SELECTED_OPUS_MODEL="$MINIMAX_OPUS_MODEL"
        SELECTED_SONNET_MODEL="$MINIMAX_SONNET_MODEL"
        SELECTED_HAIKU_MODEL="$MINIMAX_HAIKU_MODEL"
        PROVIDER_NAME="MiniMax"
        ;;
    3)
        SELECTED_API_KEY="$MOONSHOT_API_KEY"
        SELECTED_BASE_URL="$MOONSHOT_BASE_URL"
        SELECTED_OPUS_MODEL="$MOONSHOT_OPUS_MODEL"
        SELECTED_SONNET_MODEL="$MOONSHOT_SONNET_MODEL"
        SELECTED_HAIKU_MODEL="$MOONSHOT_HAIKU_MODEL"
        PROVIDER_NAME="Moonshot (Kimi)"
        ;;
    4)
        SELECTED_API_KEY="$DEEPSEEK_API_KEY"
        SELECTED_BASE_URL="$DEEPSEEK_BASE_URL"
        SELECTED_OPUS_MODEL="$DEEPSEEK_OPUS_MODEL"
        SELECTED_SONNET_MODEL="$DEEPSEEK_SONNET_MODEL"
        SELECTED_HAIKU_MODEL="$DEEPSEEK_HAIKU_MODEL"
        PROVIDER_NAME="DeepSeek"
        ;;
    5)
        SELECTED_API_KEY="$AICODEWITH_ANTHROPIC_API_KEY"
        SELECTED_BASE_URL="$AICODEWITH_ANTHROPIC_BASE_URL"
        SELECTED_OPUS_MODEL="$ANTHROPIC_OPUS_MODEL"
        SELECTED_SONNET_MODEL="$ANTHROPIC_SONNET_MODEL"
        SELECTED_HAIKU_MODEL="$ANTHROPIC_HAIKU_MODEL"
        PROVIDER_NAME="Default (Anthropic)"
        ;;
    *)
        echo "❌ Invalid choice! Please enter a number between 1-5."
        exit 1
        ;;
esac

echo "🔧 Configured for $PROVIDER_NAME"

# ==============================================================================
# Update settings.json Configuration
# ==============================================================================
# Install jq if not available
if ! command -v jq &> /dev/null; then
    echo "⚠️ jq is not installed. Installing jq first..."
    if command -v brew &> /dev/null; then
        brew install jq
    else
        echo "❌ Error: jq is required but not found and brew is not available."
        echo "   Please install jq manually: https://stedolan.github.io/jq/download/"
        exit 1
    fi
fi

# Update settings.json with selected provider configuration
jq --arg token "$SELECTED_API_KEY" \
   --arg url "$SELECTED_BASE_URL" \
   --arg opus "$SELECTED_OPUS_MODEL" \
   --arg sonnet "$SELECTED_SONNET_MODEL" \
   --arg haiku "$SELECTED_HAIKU_MODEL" \
   '.env.ANTHROPIC_AUTH_TOKEN = $token |
    .env.ANTHROPIC_BASE_URL = $url |
    .env.ANTHROPIC_DEFAULT_OPUS_MODEL = $opus |
    .env.ANTHROPIC_DEFAULT_SONNET_MODEL = $sonnet |
    .env.ANTHROPIC_DEFAULT_HAIKU_MODEL = $haiku' \
   "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"

# ==============================================================================
# Confirmation & Launch
# ==============================================================================
echo ""
echo "📋 Updated settings.json configuration:"
echo "   ANTHROPIC_AUTH_TOKEN=${SELECTED_API_KEY:0:8}******** (masked for security)"
echo "   ANTHROPIC_BASE_URL=$SELECTED_BASE_URL"
echo "   ANTHROPIC_DEFAULT_OPUS_MODEL=$SELECTED_OPUS_MODEL"
echo "   ANTHROPIC_DEFAULT_SONNET_MODEL=$SELECTED_SONNET_MODEL"
echo "   ANTHROPIC_DEFAULT_HAIKU_MODEL=$SELECTED_HAIKU_MODEL"
echo ""
read -p "Press Enter to start Claude Code (or Ctrl+C to cancel)... " -r

# Launch Claude CLI
echo "🚀 Starting Claude Code with $PROVIDER_NAME..."
"$CLAUDE_CLI"

echo ""
echo "✅ Claude Code exited. Your settings.json remains configured for $PROVIDER_NAME."
echo "🔙 To restore original settings: cp $BACKUP_FILE $SETTINGS_FILE"
