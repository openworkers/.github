# OpenWorkers Development Container

This devcontainer configuration provides a complete development environment for all OpenWorkers repositories.

## Features

- **Multi-repo workspace** - All OpenWorkers repos cloned automatically
- **Persistent caching** - Cargo registry, build artifacts, and rusty_v8 cached across rebuilds
- **Pre-installed tools** - Rust, Bun, Docker, GitHub CLI
- **Fast startup** - ~5 min first time, ~1 min after (thanks to caching)

## Usage

### Option 1: Start Codespace from github.com

1. Go to https://github.com/openworkers
2. Click "Code" → "Codespaces" → "New codespace"
3. Select the repository you want to work on
4. The devcontainer will auto-setup all repos

### Option 2: Start from VS Code

1. Install "GitHub Codespaces" extension
2. Open Command Palette (Cmd+Shift+P)
3. Run "Codespaces: Create New Codespace"
4. Select any OpenWorkers repo

### Option 3: gh CLI

```bash
gh codespace create --repo openworkers/openworkers-runner
```

## What Gets Cached

The following directories are stored in Docker volumes and persist across Codespace rebuilds:

- **Cargo registry** (`~/.cargo/registry`) - ~500MB, saves 2-3 min
- **Build artifacts** (`/workspaces/target`) - ~2GB, saves 10+ min
- **rusty_v8** (`/workspaces/rusty_v8`) - ~3GB with submodules, saves 20+ min

## Post-Create Setup

The `setup-workspace.sh` script automatically:

1. Installs Bun
2. Configures Rust toolchain
3. Installs V8 build dependencies (ninja, clang, etc.)
4. Clones rusty_v8 fork (if not cached)
5. Clones workerd reference (if not cached)
6. Clones all OpenWorkers repos
7. Configures git safe directories

## Workspace Structure

```
/workspaces/
├── openworkers-runner/
├── openworkers-runtime-v8/
├── openworkers-api/
├── openworkers-cli/
├── openworkers-core/
├── openworkers-dash/
├── openworkers-scheduler/
├── openworkers-schema/
├── rusty_v8/          # Cached, with submodules
└── workerd/           # Reference implementation
```

## Quick Commands

```bash
# Build runner
cd /workspaces/openworkers-runner
cargo build --features v8

# Generate snapshot
cargo run --features v8 --bin snapshot

# Run tests
cargo test --features v8

# Start services
docker-compose up -d
```

## Machine Size Recommendations

- **2-core, 4GB RAM** - OK for editing, slow builds
- **4-core, 8GB RAM** - Good for development ✅ (recommended)
- **8-core, 16GB RAM** - Fast builds, can compile rusty_v8

## Cost Optimization

To minimize costs:

1. **Stop Codespace when not using** - Free while stopped
2. **Delete unused Codespaces** - Keeps your 60h/month quota
3. **Use persistent volumes** - Faster restart = less runtime

## Troubleshooting

### Out of disk space

```bash
# Clean cargo cache
cargo clean
rm -rf ~/.cargo/registry/cache

# Clean Docker
docker system prune -a
```

### Rebuild container from scratch

Delete the Codespace and create a new one. Volumes will be recreated.

### rusty_v8 submodules taking forever

The setup script clones to a persistent volume. First time takes ~10-15 min on GitHub's fast network, then it's cached forever.
