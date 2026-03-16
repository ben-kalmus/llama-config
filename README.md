# llama-swap local LLM setup

Runs [llama-swap](https://github.com/mostlygeek/llama-swap) on port 11435, managing llama.cpp server processes for local model inference.

## Two Setup Options

This repo supports both **Mac native** (Metal GPU) and **Docker** (Linux/NVIDIA) deployments using a unified configuration.

| Setup | Use Case |
|-------|----------|
| Mac native + launchd | Metal GPU acceleration (Mac) |
| Docker Compose | Linux, NVIDIA GPU, CPU |

---

## Prerequisites (All Setups)

```bash
brew install llama.cpp
brew install llama-swap
```

---

## Mac Native Setup (Metal GPU)

### 1. Download Model

```bash
hf download unsloth/Qwen3.5-9B-GGUF \
  --local-dir ~/.llama/models/Qwen3.5-9B-GGUF \
  --include "*Q4_K_M.gguf"
```

### 2. Generate and Install Launch Agent

```bash
./bin/generate-plist.sh
```

This generates `~/Library/LaunchAgents/com.llama-swap.plist` with your home directory path.

### 3. Load the Service

```bash
launchctl load ~/Library/LaunchAgents/com.llama-swap.plist
```

### Service Management

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

---

## Docker Setup (Linux/NVIDIA GPU)

### 1. Download Model

Default location for llama.cpp models is `~/.llama/models`:

```bash
hf download unsloth/Qwen3.5-9B-GGUF \
  --local-dir ~/.llama/models/Qwen3.5-9B-GGUF \
  --include "*Q4_K_M.gguf"
```

### 2. Run Container

```bash
# CPU only
docker compose --profile cpu up -d

# NVIDIA GPU (CUDA)
docker compose --profile nvidia up -d

# AMD GPU (Vulkan)
docker compose --profile vulkan up -d

# Intel GPU
docker compose --profile intel up -d
```

### Service Management

```bash
# View logs
docker compose logs -f

# Stop
docker compose down

# Restart
docker compose restart
```

---

## Unified Configuration

Both setups share the same `config/config.yaml` using environment variables for platform-specific paths.

### Environment Variables

| Variable | Mac (launchd) | Docker |
|----------|---------------|-------|
| `LLAMA_SERVER` | `/opt/homebrew/bin/llama-server` | `/app/llama-server` |
| `LLAMA_MODELS_DIR` | `${HOME}/.llama/models` | `~/.llama/models` (host path) |

These are injected by the launchd plist and docker-compose.yml.

---

## API

- Base URL: `http://localhost:11435`
- Web UI: `http://localhost:11435/ui`

### opencode Provider

Add to `~/.config/opencode/opencode.json`:

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
                "context": 200000,
                "output": 16384
            }
        }
    }
}
```

---

## Model Configuration

| Parameter | Value | Notes |
|-----------|-------|-------|
| ttl | 600 | Auto-unload after 10 min idle |
| ctx-size | 200000 | 200K context |
| KV cache | q8_0 | Halves KV memory vs f16 |
| parallel | 1 | Single slot |
| thinking | enabled | Qwen3.5 thinking mode |

---

## Docker Images

| Image | Description |
|-------|-------------|
| `ghcr.io/mostlygeek/llama-swap:cpu` | CPU only |
| `ghcr.io/mostlygeek/llama-swap:cuda` | NVIDIA GPU (CUDA) |
| `ghcr.io/mostlygeek/llama-swap:vulkan` | AMD GPU (Vulkan) |
| `ghcr.io/mostlygeek/llama-swap:intel` | Intel GPU |

---

## Uninstall

### Mac native

```bash
launchctl unload ~/Library/LaunchAgents/com.llama-swap.plist
rm ~/.llama/config.yaml
rm ~/Library/LaunchAgents/com.llama-swap.plist
```

### Docker

```bash
docker compose down
```
