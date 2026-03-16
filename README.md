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
                "context": 262144,
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
| context size | 262144 (256K, full native max) |
| KV cache type | q8_0 (halves KV memory vs f16) |
| parallel slots | 1 |
| thinking mode | enabled |
| idle TTL | 300s |

These values come from the [Qwen3.5 model card](https://huggingface.co/Qwen/Qwen3.5-9B). The model is ~5.3GB (Q4_K_M quantization). Qwen3.5 is a hybrid DeltaNet/Attention architecture where only 8 of 32 layers use KV cache, making the cache very efficient. At 262K context with q8_0 KV cache, total GPU memory usage is ~10GB, leaving ~8GB free on 24GB unified memory.

## Adding more models

Edit `.llama/config.yaml` and add another entry under `models:`. See [llama-swap docs](https://github.com/mostlygeek/llama-swap) for configuration options. After editing, restart the service:

```bash
launchctl unload ~/Library/LaunchAgents/com.llama-swap.plist
launchctl load ~/Library/LaunchAgents/com.llama-swap.plist
```
