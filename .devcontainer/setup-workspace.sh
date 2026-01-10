#!/bin/bash
set -e

echo "🚀 Setting up OpenWorkers multi-repo workspace..."

cd /workspaces

# Install Bun
echo "📦 Installing Bun..."
curl -fsSL https://bun.sh/install | bash
export PATH="$HOME/.bun/bin:$PATH"

# Install Rust toolchain
echo "🦀 Setting up Rust..."
rustup default stable
rustup component add rustfmt clippy

# Install system dependencies for V8 compilation
echo "📚 Installing V8 build dependencies..."
sudo apt-get update
sudo apt-get install -y \
    python3 \
    python3-pip \
    ninja-build \
    pkg-config \
    libssl-dev \
    git \
    cmake \
    clang \
    lld

# Clone rusty_v8 fork to persistent volume (if not exists)
if [ ! -d "/workspaces/rusty_v8/.git" ]; then
    echo "📥 Cloning rusty_v8 fork (this will take a while - ~2GB with submodules)..."
    git clone https://github.com/max-lt/rusty_v8.git /workspaces/rusty_v8
    cd /workspaces/rusty_v8
    git submodule update --init --recursive
    echo "✅ rusty_v8 cloned to persistent volume"
else
    echo "✅ rusty_v8 already exists in persistent volume"
    cd /workspaces/rusty_v8
    git pull origin main || true
fi

# Clone workerd fork to persistent volume (if not exists)
if [ ! -d "/workspaces/workerd/.git" ]; then
    echo "📥 Cloning workerd fork for reference..."
    git clone https://github.com/cloudflare/workerd.git /workspaces/workerd
    echo "✅ workerd cloned"
else
    echo "✅ workerd already exists"
fi

# Clone all OpenWorkers repos
echo "📥 Cloning OpenWorkers repositories..."

REPOS=(
    "openworkers-runner"
    "openworkers-runtime-v8"
    "openworkers-api"
    "openworkers-cli"
    "openworkers-core"
    "openworkers-dash"
    "openworkers-scheduler"
    "openworkers-schema"
)

for repo in "${REPOS[@]}"; do
    if [ ! -d "/workspaces/$repo/.git" ]; then
        echo "  📦 Cloning $repo..."
        git clone "git@github.com:openworkers/$repo.git" "/workspaces/$repo" || \
        git clone "https://github.com/openworkers/$repo.git" "/workspaces/$repo"
    else
        echo "  ✅ $repo already exists"
    fi
done

# Setup git safe directories
echo "⚙️  Configuring git..."
for repo in "${REPOS[@]}"; do
    git config --global --add safe.directory "/workspaces/$repo" 2>/dev/null || true
done
git config --global --add safe.directory "/workspaces/rusty_v8" 2>/dev/null || true
git config --global --add safe.directory "/workspaces/workerd" 2>/dev/null || true

# Create workspace structure info
cat > /workspaces/README.md << 'EOF'
# OpenWorkers Development Workspace

This Codespace contains all OpenWorkers repositories:

## Repositories

- **openworkers-runner** - Core runtime (Rust)
- **openworkers-runtime-v8** - V8 runtime implementation (Rust)
- **openworkers-api** - REST API (TypeScript/Bun)
- **openworkers-cli** - CLI tool (Rust)
- **openworkers-core** - Shared core types (Rust)
- **openworkers-dash** - Dashboard (Angular)
- **openworkers-scheduler** - Cron scheduler (Rust)
- **openworkers-schema** - Database schema (SQL)

## Reference repos (cached)

- **rusty_v8** - V8 bindings with Locker support
- **workerd** - Cloudflare Workers runtime reference

## Quick Start

### Build runner with V8

```bash
cd /workspaces/openworkers-runner
cargo build --features v8
```

### Generate V8 snapshot

```bash
cd /workspaces/openworkers-runner
cargo run --features v8 --bin snapshot
```

### Run tests

```bash
cd /workspaces/openworkers-runner
cargo test --features v8
```

### API Development

```bash
cd /workspaces/openworkers-api
bun install
bun run dev
```

### Dashboard

```bash
cd /workspaces/openworkers-dash
bun install
bun start
```

## Persistent Volumes

- `/usr/local/cargo/registry` - Cargo cache (persists across rebuilds)
- `/workspaces/target` - Build artifacts cache
- `/workspaces/rusty_v8` - rusty_v8 with submodules (huge, cached)

## Services

Use docker-compose for PostgreSQL and NATS:

```bash
docker-compose up -d
```

Ports:
- 3000 - OpenWorkers API
- 5432 - PostgreSQL
- 4222 - NATS
- 8080 - Dashboard
EOF

echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 Workspace structure:"
ls -1 /workspaces | grep -E "^(openworkers|rusty|workerd)" | sed 's/^/  - /'
echo ""
echo "💡 Tips:"
echo "  - All repos are in /workspaces/"
echo "  - Cargo cache is persistent"
echo "  - rusty_v8 stays across rebuilds (saves 20+ min)"
echo "  - See /workspaces/README.md for commands"
echo ""
