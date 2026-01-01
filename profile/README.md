# OpenWorkers

OpenWorkers is an open-source serverless platform for running JavaScript/TypeScript workers. Deploy functions that scale automatically (soon™), with built-in bindings for databases, key-value storage, and object storage.

## Repositories

### Core Runtime

| Repository                                                                      | Description                  | Language |
| ------------------------------------------------------------------------------- | ---------------------------- | -------- |
| [openworkers-runner](https://github.com/openworkers/openworkers-runner)         | Core worker execution engine | Rust     |
| [openworkers-runtime-v8](https://github.com/openworkers/openworkers-runtime-v8) | V8 JavaScript runtime        | Rust     |
| [openworkers-core](https://github.com/openworkers/openworkers-core)             | Shared types and traits      | Rust     |

### Platform Services

| Repository                                                                    | Description                          | Language       |
| ----------------------------------------------------------------------------- | ------------------------------------ | -------------- |
| [openworkers-api](https://github.com/openworkers/openworkers-api)             | User-facing REST API                 | TypeScript/Bun |
| [openworkers-scheduler](https://github.com/openworkers/openworkers-scheduler) | Cron job scheduler                   | Rust           |
| [openworkers-logs](https://github.com/openworkers/openworkers-logs)           | Log ingestion (NATS) + SSE streaming | Rust           |
| [openworkers-cli](https://github.com/openworkers/openworkers-cli)             | Admin/infra tool                     | Rust           |

### Frontend

| Repository                                                                | Description             | Language  |
| ------------------------------------------------------------------------- | ----------------------- | --------- |
| [openworkers-dash](https://github.com/openworkers/openworkers-dash)       | User dashboard          | Angular   |
| [openworkers-website](https://github.com/openworkers/openworkers-website) | Documentation & website | SvelteKit |

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
    // Key-Value Storage
    await env.KV.put("key", "value", { expirationTtl: 3600 });
    const value = await env.KV.get("key");

    // Database (PostgreSQL)
    const users = await env.DB.query("SELECT * FROM users WHERE id = $1", [
      userId,
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
