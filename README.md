# Claude Code Launcher - Secure Multi-API Provider Script

A secure shell script for launching Claude Code with different API providers. All configuration is stored in a local environment file that is excluded from version control.

## Features

- **Secure Configuration**: API keys and model settings stored in a local `.env` file (gitignored)
- **Multiple API Providers**: Support for Zhipu (GLM), MiniMax, Moonshot (Kimi), DeepSeek, and Anthropic
- **Easy Configuration Management**: Edit settings in one place and apply with `install.sh`
- **Automatic Setup**: `install.sh` handles symlinking, validation, and initialization

## Project Structure

```
start-claude-script/
├── start-claude.sh              # Main script (loads from env file)
├── start-claude.env.example     # Template file (committed to git)
├── install.sh                   # Setup/update script
├── .gitignore                   # Ignore sensitive files
└── README.md                    # This file
```

## Installation

### Initial Setup (one-time)

1. Navigate to the project directory:
   ```bash
   cd /path/to/start-claude-script
   ```

2. Run the install script:
   ```bash
   ./install.sh
   ```

3. Edit the configuration file with your actual API keys:
   ```bash
   vim ~/.start-claude.env
   ```

4. Run install again to apply your configuration:
   ```bash
   ./install.sh
   ```

## Usage

### Start Claude Code

Run the launcher from anywhere:
```bash
~/start-claude.sh
```

Select a provider from the menu and press Enter to launch.

### Update Configuration

1. Edit your configuration file:
   ```bash
   vim ~/.start-claude.env
   ```

2. Apply changes:
   ```bash
   cd /path/to/start-claude-script
   ./install.sh
   ```

## Configuration Reference

Edit `~/.start-claude.env` to configure your settings:

### Required Variables

| Variable | Description |
|----------|-------------|
| `CLAUDE_CLI` | Path to Claude CLI binary |
| `*_API_KEY` | API key for each provider |
| `*_BASE_URL` | Base URL for each provider |
| `*_OPUS_MODEL` | Model name for Opus tier |
| `*_SONNET_MODEL` | Model name for Sonnet tier |
| `*_HAIKU_MODEL` | Model name for Haiku tier |

### Supported Providers

1. **Zhipu (智谱)** - GLM-5, GLM-4.7, GLM-4.5-Air
2. **MiniMax** - abab6-chat, abab5.5-chat
3. **Moonshot (Kimi)** - moonshot-v1-128k, 32k, 8k
4. **DeepSeek** - deepseek-coder-v2, v1.5, light
5. **Anthropic (Default)** - claude-3-opus, sonnet, haiku

## Security Notes

- `~/.start-claude.env` is automatically gitignored
- Never commit `~/.start-claude.env` to version control
- API keys are masked in console output for security
- The `.gitignore` file protects against accidental commits

## Troubleshooting

### "Configuration file not found"
Run `./install.sh` to create the configuration file.

### "Required variable X is not set"
Edit `~/.start-claude.env` and fill in all required API keys and URLs.

### "jq is not installed"
The install script will attempt to install `jq` via Homebrew. If Homebrew is not available, install `jq` manually from https://stedolan.github.io/jq/download/

## Development

### Updating the Main Script

1. Make changes to `start-claude.sh` in the project directory
2. Run `./install.sh` to update the symlink
3. Test with `~/start-claude.sh`
4. Commit changes: `git add . && git commit -m "update: description"`

### Adding a New Provider

1. Add configuration variables to `start-claude.env.example`
2. Update the validation in `install.sh` if needed
3. Add provider to the menu in `start-claude.sh`
4. Add case in the provider selection section

## License

MIT
