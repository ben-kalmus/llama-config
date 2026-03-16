# llama-swap local LLM setup

Runs [llama-swap](https://github.com/mostlygeek/llama-swap) on port 11435, managing llama.cpp server processes for local model inference. Designed for M4 Pro with 24GB unified memory.

Ollama stays on port 11434 alongside this setup.

## Prerequisites

```bash
brew install llama.cpp
brew install llama-swap
brew install stow
```

## Directory layout

This repo is a GNU stow package targeting `$HOME`. The tree mirrors the home directory structure:

```
~/repos/llama/
├── .llama/
│   └── config.yaml              -> ~/.llama/config.yaml
├── Library/
│   └── LaunchAgents/
│       └── com.llama-swap.plist -> ~/Library/LaunchAgents/com.llama-swap.plist
└── README.md
```

Models are stored in `~/.llama/models/` (not managed by stow, too large).

## Setup

### 1. Download model

```bash
hf download unsloth/Qwen3.5-9B-GGUF \
  --local-dir ~/.llama/models/Qwen3.5-9B-GGUF \
  --include "*Q4_K_M.gguf"
```

### 2. Create symlinks

```bash
cd ~/repos && stow llama
```

Verify:

```bash
ls -la ~/.llama/config.yaml
ls -la ~/Library/LaunchAgents/com.llama-swap.plist
```

### 3. Start the service

```bash
launchctl load ~/Library/LaunchAgents/com.llama-swap.plist
```

### 4. Add provider to opencode

Add this block to `~/.config/opencode/opencode.json` under `"provider"`:

```json
"llama-swap": {
    "npm": "@ai-sdk/openai-compatible",
    "name": "llama-swap (local)",
    "options": {
        "baseURL": "http://localhost:11435/v1"
    },
    "models": {
        "qwen3.5-9b": {
            "name": "Qwen 3.5 9B Q4_K_M (thinking)",
            "limit": {
                "context": 32768,
                "output": 16384
            }
        }
    }
}
```

## Service management

```bash
# Start
launchctl load ~/Library/LaunchAgents/com.llama-swap.plist

# Stop
launchctl unload ~/Library/LaunchAgents/com.llama-swap.plist

# View logs
tail -f ~/.llama/llama-swap.log

# Web UI
open http://localhost:11435/ui
```

## Uninstall symlinks

```bash
cd ~/repos && stow -D llama
```

## Model configuration

The Qwen3.5-9B config uses developer-recommended sampling parameters for precise coding:

| Parameter | Value |
|---|---|
| temperature | 0.6 |
| top_p | 0.95 |
| top_k | 20 |
| min_p | 0.0 |
| context size | 32768 |
| thinking mode | enabled |
| idle TTL | 300s |

These values come from the [Qwen3.5 model card](https://huggingface.co/Qwen/Qwen3.5-9B). The model is ~5.7GB (Q4_K_M quantization) and fits comfortably on 24GB with 32k context.

## Adding more models

Edit `.llama/config.yaml` and add another entry under `models:`. See [llama-swap docs](https://github.com/mostlygeek/llama-swap) for configuration options. After editing, restart the service:

```bash
launchctl unload ~/Library/LaunchAgents/com.llama-swap.plist
launchctl load ~/Library/LaunchAgents/com.llama-swap.plist
```
