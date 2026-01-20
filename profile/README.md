# OpenWorkers

OpenWorkers is an open-source serverless platform for running JavaScript/TypeScript workers. Deploy functions that scale automatically (soon™), with built-in bindings for databases, key-value storage, and object storage.

## Repositories

### Core Runtime

| Repository                                                                            | Description                      | Language |
| ------------------------------------------------------------------------------------- | -------------------------------- | -------- |
| [openworkers-runner](https://github.com/openworkers/openworkers-runner)               | Core worker execution engine     | Rust     |
| [openworkers-task-executor](https://github.com/openworkers/openworkers-task-executor) | Standalone executor (fetch only) | Rust     |
| [openworkers-runtime-v8](https://github.com/openworkers/openworkers-runtime-v8)       | V8 JavaScript runtime            | Rust     |
| [openworkers-core](https://github.com/openworkers/openworkers-core)                   | Shared types and traits          | Rust     |

### V8 Libraries

| Repository                                          | Description                            | Language |
| --------------------------------------------------- | -------------------------------------- | -------- |
| [rusty-v8](https://github.com/openworkers/rusty-v8) | V8 bindings (fork with Locker support) | Rust     |
| [serde-v8](https://github.com/openworkers/serde-v8) | Serde integration for V8 values        | Rust     |
| [glue-v8](https://github.com/openworkers/glue-v8)   | Rust to V8 binding macros              | Rust     |

### Platform Services

| Repository                                                                    | Description                            | Language       |
| ----------------------------------------------------------------------------- | -------------------------------------- | -------------- |
| [openworkers-api](https://github.com/openworkers/openworkers-api)             | User-facing REST API                   | TypeScript/Bun |
| [openworkers-scheduler](https://github.com/openworkers/openworkers-scheduler) | Cron job scheduler                     | Rust           |
| [openworkers-logs](https://github.com/openworkers/openworkers-logs)           | Log ingestion (NATS) + SSE streaming   | Rust           |
| [openworkers-cli](https://github.com/openworkers/openworkers-cli)             | Admin/infra tool                       | Rust           |
| [postgate](https://github.com/openworkers/postgate)                           | Multi-tenant HTTP proxy for PostgreSQL | Rust           |

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
openworkers-runtime-v8 = "0.8"
openworkers-core = "0.8"
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
         ┌───────────────┬────────┴──┬───────────────┐
         │               │           │               │
         │               │           │               │
┌────────┸────────┐ ┌────┸────┐ ┌────┸────┐ ┌────────┸────────┐
│   dashboard     │ │  api    │ │ logs *  │ │  runner (x3) *  │
└─────────────────┘ └────┬────┘ └────┰────┘ └────────┰────────┘
                         │           │               │
                         │           │               │
                ┌────────┸────────┐  │      ┌────────┸────────┐
                │   postgate *    │  └──────┥      nats       │
                └─────────────────┘         └────────┰────────┘
                                                     │
                                                     │
                ┌─────────────────┐           ┌──────┴───────┐
         * ─────┥   PostgreSQL    │           │ scheduler *  │
                └─────────────────┘           └──────────────┘
```

Single database. Components marked with `*` connect to PostgreSQL.

> **Note:** `api` and `dashboard` are intended to become userland services (served as regular workers).

## Features

### Worker Runtime

- **JavaScript/TypeScript** execution via V8
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

- Rust 1.75+
- Bun 1.0+
- PostgreSQL 15+
- NATS Server

### Quick Start

```bash
# Clone repositories
git clone https://github.com/openworkers/openworkers-runner.git
git clone https://github.com/openworkers/openworkers-api.git

# Start the runner
cd openworkers-runner && cargo run

# Start the API (in another terminal)
cd openworkers-api && bun install && bun run dev
```

See individual repository READMEs for detailed setup instructions.

## Design Principles

1. **Database is the single source of truth**: All components read from/write to PostgreSQL. No local state.

2. **API is userland**: The API is designed to run as a worker on the platform itself (dogfooding).

3. **CLI is the infra tool**: All infrastructure operations (migrations, setup) go through the CLI.

4. **Security by design**: Credentials never reach the JavaScript sandbox.

5. **Cloudflare Workers compatible**: API compatibility with Cloudflare Workers where possible.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) before submitting a PR.

---

Built with Rust, TypeScript, Claude Code, and a lot of love.
