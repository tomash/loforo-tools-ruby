# AGENTS.md

## Cursor Cloud specific instructions

### What this repo is

Ruby CLI/library for uploading photos and videos to [Loforo](https://loforo.com) via `https://loforo.com/api/post/create`. Entry points: `file-to-loforo.rb` (single file), `dir-to-loforo.rb` (batch queue with `uploaded/` and `uploaded.json`). There is no local web server or database.

### System dependencies (not in the update script)

The VM image must provide Ruby 3.2+ and native extension build tools. On Ubuntu:

```bash
sudo apt-get install -y ruby ruby-dev bundler build-essential
```

### Dependency refresh (update script)

Bundler installs gems under `vendor/bundle` (see `.bundle/config`). From the repo root:

```bash
bundle install
bundle exec rake
```

Always prefix Ruby commands with `bundle exec` so gems resolve from the bundle (plain `ruby` will not see the `http` gem).

### Running and testing

| Task | Command |
|------|---------|
| Unit tests | `bundle exec rake` or `bundle exec rake test` |
| Single upload | `LOFORO_API_KEY=... bundle exec ruby file-to-loforo.rb /path/to/media.jpg` |
| Batch upload | `LOFORO_API_KEY=... bundle exec ruby dir-to-loforo.rb /path/to/queue-dir` |

Tests mock HTTP; no external services are required for `rake`. Live uploads need `LOFORO_API_KEY` and network access to loforo.com.

### Gotchas

- **No linter** is configured in this repo; `bundle exec rake` is the primary quality gate.
- **`bundle install` without `--path` / `.bundle/config`** may try to write to system gem paths and fail with permission errors; use project-local `vendor/bundle`.
- **Batch uploader** moves successful files into `<queue>/uploaded/` and appends metadata to `<queue>/uploaded.json`.
- **Invalid API keys** still reach the API (e.g. HTTP 401); that confirms connectivity but not a successful post.
