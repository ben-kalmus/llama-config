# llama-swap local LLM setup

Runs [llama-swap](https://github.com/mostlygeek/llama-swap) on port 11435, managing llama.cpp server processes for local model inference.

## Setup Options

| Setup | Use Case | GPU |
|-------|----------|-----|
| Mac native + launchd | Best performance on Mac | Metal |
| Docker `--profile native` | Build from source (any arch: arm64, amd64) | CPU only |
| Docker `--profile cpu` | Pre-built Linux image | CPU only (amd64) |
| Docker `--profile nvidia` | Pre-built Linux image | CUDA (amd64) |
| Docker `--profile vulkan` | Pre-built Linux image | Vulkan (amd64) |
| Docker `--profile intel` | Pre-built Linux image | Intel (amd64) |

---

## Download Model

All setups expect models in `~/.llama/models`:

```bash
hf download unsloth/Qwen3.5-9B-GGUF \
  --local-dir ~/.llama/models/Qwen3.5-9B-GGUF \
  --include "*Q4_K_M.gguf"
```

Alternatively you can find the model on huggingface and download it manually.

---

## Mac Native Setup (Metal GPU)

Runs llama-swap directly on macOS with Metal GPU acceleration.

### Prerequisites

```bash
brew install llama.cpp
brew install llama-swap
```

### Generate and Install Launch Agent

```bash
./bin/generate-plist.sh
```

This reads `./Library/LaunchAgents/com.llama-swap.plist.tmpl`, substitutes `${HOME}` with your actual home directory, and writes the result to `~/Library/LaunchAgents/com.llama-swap.plist`.

### Load the Service

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

## Docker Setup

### Native Build (any architecture)

Compiles both llama.cpp and llama-swap from source for the host architecture. Works on ARM64 (Apple Silicon, Raspberry Pi) and AMD64 (x86_64) alike. Two Dockerfiles produce a layered image:

- `Dockerfile.llama` compiles llama-server from the llama.cpp repo (gcc:15 build stage, debian:trixie-slim runtime)
- `Dockerfile.llama-swap` compiles llama-swap from source (golang:1.26 build stage) and layers it on top of the llama-server image

Build and run:

```bash
# Build base image (llama-server), then llama-swap on top
docker compose build llama-server-native
docker compose --profile native build

# Run
docker compose --profile native up -d
```

First build takes ~10 minutes. Subsequent builds are cached.

#### Version Pinning

Versions are defined in `docker-compose.yml` under each service's `build.args`:

| Service | Arg | Default | Description |
|---------|-----|---------|-------------|
| `llama-server-native` | `LLAMA_CPP_VERSION` | `b8331` | llama.cpp release tag |
| `llama-swap-native` | `LLAMA_SWAP_VERSION` | `v198` | llama-swap release tag |

Override at build time:

```bash
docker compose build --build-arg LLAMA_CPP_VERSION=b8400 llama-server-native
docker compose --profile native build --build-arg LLAMA_SWAP_VERSION=v200
```

#### Rebuild from Scratch

```bash
docker compose build --no-cache llama-server-native
docker compose --profile native build --no-cache
```

**Note:** This is CPU-only inference. On Mac, the native launchd setup with Metal GPU is significantly faster.

### Linux / NVIDIA / AMD / Intel

Uses pre-built images from `ghcr.io/mostlygeek/llama-swap` (amd64 only):

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

### Docker Service Management

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

Both setups share `./config/config.yaml` using environment variable macros for platform-specific paths:

```yaml
macros:
  "llama-server": "${env.LLAMA_SERVER}"
  "models-dir": "${env.LLAMA_MODELS_DIR}"
```

### Environment Variables

| Variable | Mac (launchd) | Docker |
|----------|---------------|--------|
| `LLAMA_SERVER` | `/opt/homebrew/bin/llama-server` | `/app/llama-server` |
| `LLAMA_MODELS_DIR` | `${HOME}/.llama/models` | `/models` (mapped from `~/.llama/models`) |

The launchd plist template sets these in its `EnvironmentVariables` dict. Docker Compose sets them in the `x-base` anchor's `environment` list.

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

| Profile | Image | Architecture |
|---------|-------|--------------|
| `cpu` | `ghcr.io/mostlygeek/llama-swap:cpu` | amd64 |
| `nvidia` | `ghcr.io/mostlygeek/llama-swap:cuda` | amd64 |
| `vulkan` | `ghcr.io/mostlygeek/llama-swap:vulkan` | amd64 |
| `intel` | `ghcr.io/mostlygeek/llama-swap:intel` | amd64 |
| `native` | Built from `Dockerfile.llama` + `Dockerfile.llama-swap` | arm64, amd64 |

---

## Uninstall

### Mac native

```bash
launchctl unload ~/Library/LaunchAgents/com.llama-swap.plist
rm ~/Library/LaunchAgents/com.llama-swap.plist
```

### Docker

```bash
docker compose down
docker rmi llama-server-native:latest
docker image rm $(docker images --filter=reference='llama-llama-swap-native' -q)
```
