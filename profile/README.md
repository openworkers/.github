# OpenWorkers

OpenWorkers is an open-source serverless platform for running JavaScript, TypeScript and Rust (WebAssembly) workers, with built-in bindings for databases, key-value storage, and object storage.

## Repositories

### Core Runtime

| Repository                                                                            | Description                                            | Language |
| ------------------------------------------------------------------------------------- | ------------------------------------------------------ | -------- |
| [openworkers-runner](https://github.com/openworkers/openworkers-runner)               | Worker execution engine, serves JavaScript and wasm    | Rust     |
| [openworkers-task-executor](https://github.com/openworkers/openworkers-task-executor) | Standalone executor (fetch only)                       | Rust     |
| [openworkers-core](https://github.com/openworkers/openworkers-core)                   | Shared types and traits                                | Rust     |

### Runtimes

| Repository                                                                          | Description                                          | Language |
| ----------------------------------------------------------------------------------- | ---------------------------------------------------- | -------- |
| [openworkers-runtime-v8](https://github.com/openworkers/openworkers-runtime-v8)     | V8 JavaScript runtime (production)                   | Rust     |
| [openworkers-runtime-wasm](https://github.com/openworkers/openworkers-runtime-wasm) | WebAssembly components on wasmtime (`wasi:http`)     | Rust     |
| [openworkers-runtime-jsc](https://github.com/openworkers/openworkers-runtime-jsc)   | JavaScriptCore runtime                               | Rust     |
| [openworkers-runtime-quickjs](https://github.com/openworkers/openworkers-runtime-quickjs) | QuickJS runtime                               | Rust     |
| [openworkers-runtime-boa](https://github.com/openworkers/openworkers-runtime-boa)   | Boa runtime                                          | Rust     |
| [openworkers-runtime-nova](https://github.com/openworkers/openworkers-runtime-nova) | Nova runtime (experimental)                          | Rust     |
| [openworkers-conformance](https://github.com/openworkers/openworkers-conformance)   | Cross-engine conformance suite, one recorded oracle  | Rust     |

### Worker SDKs & Adapters

| Repository                                                                  | Description                                            | Language   |
| --------------------------------------------------------------------------- | ------------------------------------------------------ | ---------- |
| [openworkers-worker](https://github.com/openworkers/openworkers-worker)     | Rust guest SDK, API-compatible with `worker` 0.8       | Rust       |
| [workers-types](https://github.com/openworkers/workers-types)               | TypeScript types for the worker runtime                | TypeScript |
| [adapter-sveltekit](https://github.com/openworkers/adapter-sveltekit)       | Deploy SvelteKit apps as workers (SSR)                 | TypeScript |
| [adapter-static](https://github.com/openworkers/adapter-static)             | Deploy static sites as workers                         | TypeScript |

### V8 Libraries

| Repository                                          | Description                                | Language |
| --------------------------------------------------- | ------------------------------------------ | -------- |
| [rusty-v8](https://github.com/openworkers/rusty-v8) | V8 bindings and prebuilt binaries          | Rust     |
| [serde-v8](https://github.com/openworkers/serde-v8) | Serde integration for V8 values            | Rust     |
| [glue-v8](https://github.com/openworkers/glue-v8)   | Rust to V8 binding macros                  | Rust     |

### Platform Services

| Repository                                                                    | Description                            | Language       |
| ----------------------------------------------------------------------------- | -------------------------------------- | -------------- |
| [openworkers-api](https://github.com/openworkers/openworkers-api)             | User-facing REST API                   | TypeScript/Bun |
| [openworkers-scheduler](https://github.com/openworkers/openworkers-scheduler) | Cron job scheduler                     | Rust           |
| [openworkers-logs](https://github.com/openworkers/openworkers-logs)           | Log ingestion (NATS) + SSE streaming   | Rust           |
| [openworkers-cli](https://github.com/openworkers/openworkers-cli)             | Admin/infra tool                       | Rust           |
| [postgate](https://github.com/openworkers/postgate)                           | Multi-tenant HTTP proxy for PostgreSQL | Rust           |
| [openworkers-infra](https://github.com/openworkers/openworkers-infra)         | Docker Compose deployment              | -              |

### Frontend

| Repository                                                                | Description             | Language  |
| ------------------------------------------------------------------------- | ----------------------- | --------- |
| [openworkers-dash](https://github.com/openworkers/openworkers-dash)       | User dashboard          | Angular   |
| [openworkers-website](https://github.com/openworkers/openworkers-website) | Documentation & website | SvelteKit |

## Standalone V8 Runtime

Don't need the full platform? Use `openworkers-runtime-v8` as a standalone JavaScript runtime in your Rust application:

```rust
use openworkers_core::{Event, HttpRequest, Script};
use openworkers_runtime_v8::Worker;

#[tokio::main]
async fn main() {
    let code = r#"
        addEventListener('fetch', (event) => {
            event.respondWith(new Response('Hello from V8!'));
        });
    "#;

    let script = Script::new(code);
    let mut worker = Worker::new(script, None).await.unwrap();

    let (event, rx) = Event::fetch(HttpRequest::get("http://localhost/"));
    worker.exec(event).await.unwrap();

    let response = rx.await.unwrap();
    println!("Status: {}", response.status);
}
```

Add to your `Cargo.toml`:

```toml
[dependencies]
openworkers-runtime-v8 = { git = "https://github.com/openworkers/openworkers-runtime-v8", tag = "v0.15.0" }
openworkers-core = { git = "https://github.com/openworkers/openworkers-core", tag = "v0.15.0" }
tokio = { version = "1", features = ["full"] }
```

See [openworkers-runtime-v8](https://github.com/openworkers/openworkers-runtime-v8) for full documentation.
See [openworkers-task-executor](https://github.com/openworkers/openworkers-task-executor) for a complete implementation example.

## Architecture

```
                     ┌─────────────────┐
                     │  nginx (proxy)  │
                     └────────┬────────┘
                              │
               ┌──────────────┴──────────────┐
               │                             │
      ┌────────┴────────┐          ┌─────────┴─────────┐
      │  runner (x3) *  │          │      logs *       │
      │                 │          │                   │
      │  every worker,  │          │  SSE log stream   │
      │  api included   │          │                   │
      └────────┬────────┘          └─────────┬─────────┘
               │                             │
               └──────────────┬──────────────┘
                              │
                    ┌─────────┴─────────┐
                    │       nats        │
                    └─────────┬─────────┘
                              │
                    ┌─────────┴─────────┐
                    │    scheduler *    │
                    └───────────────────┘
```

Single database. Components marked with `*` read and write PostgreSQL.

The `dashboard` and `api` run as workers on the platform itself (dogfooding); `postgate` is then optional, since the workerized api reaches the database through its runtime binding.

Services `logs` and `scheduler` are not required for the core runtime but provide additional functionality (log streaming and cron jobs).

## Features

### Worker Runtime

- **JavaScript/TypeScript** execution via V8
- **Rust workers** as native WebAssembly components (`wasm32-wasip2`), with a workers-rs-compatible SDK
- **Web-standard APIs**: `fetch()`, `Request`, `Response`, `Headers`, `crypto`, `TextEncoder/Decoder`
- **Streaming support**: ReadableStream, WritableStream
- **Console logging** with structured output

### Bindings

Workers can access platform resources through bindings:

```javascript
export default {
  async fetch(request, env) {
    // Key-Value Storage (native JSON support)
    await env.KV.put("session", { userId: 123 }, { expiresIn: 3600 });
    const session = await env.KV.get("session");

    // Database (PostgreSQL)
    const users = await env.DB.query("SELECT * FROM users WHERE id = $1", [
      session.userId,
    ]);

    // Static Assets (S3/R2)
    const asset = await env.ASSETS.fetch("/images/logo.png");

    return new Response("Hello World");
  },
};
```

### Database

- **Multi-tenant isolation** via PostgreSQL schemas
- **SQL validation** blocks dangerous operations (system tables, schema escapes)
- **BYOD support**: Bring Your Own Database with direct connection strings

### Scheduled Events (Cron)

```javascript
export default {
  async scheduled(event, env) {
    // Runs on schedule
    console.log(`Cron triggered at ${event.scheduledTime}`);
  },
};
```

## Security

- **V8 Isolates**: Each worker runs in an isolated V8 context
- **No credential exposure**: Workers only see binding names, never secrets
- **SQL validation**: Queries are parsed and validated before execution
- **Schema isolation**: Multi-tenant databases use `SET search_path` for isolation
- **Path sanitization**: Object storage paths are sanitized to prevent traversal attacks

## Getting Started

### Prerequisites

- Rust 1.85+
- Bun 1.0+
- PostgreSQL 15+
- NATS Server

### Quick Start

```bash
# Clone repositories
git clone https://github.com/openworkers/openworkers-runner.git
git clone https://github.com/openworkers/openworkers-api.git

# Start the runner
cd openworkers-runner && cargo run --features v8

# Start the API dev loop (in another terminal)
cd openworkers-api && bun install && bun run dev
```

For a full self-hosted platform, follow
[openworkers-infra](https://github.com/openworkers/openworkers-infra)'s GETTING_STARTED.

## Design Principles

1. **Database is the single source of truth**: All components read from/write to PostgreSQL. No local state.

2. **API is userland**: The API is designed to run as a worker on the platform itself (dogfooding).

3. **CLI is the infra tool**: All infrastructure operations (migrations, setup) go through the CLI.

4. **Security by design**: Credentials never reach the JavaScript sandbox.

5. **Cloudflare Workers compatible**: API compatibility with Cloudflare Workers where possible.

## License

MIT, across the organization.

## Contributing

Contributions are welcome - open an issue or a pull request on the relevant repository.

---

Built with Rust, TypeScript, Claude Code, and a lot of love.
