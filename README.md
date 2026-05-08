# pi-ds4

Pi provider extension for running [antirez/ds4](https://github.com/antirez/ds4)
as a local DeepSeek V4 Flash model.

The extension registers the `ds4/deepseek-v4-flash` model, starts `ds4-server`
on demand, downloads/builds the runtime if needed, keeps a per-pi-process lease,
and stops the server via a bundled watchdog when no clients are left.

## Install

```sh
pi install https://github.com/mitsuhiko/pi-ds4
```

For local development from this checkout, pass the path to an existing ds4 server checkout:

```sh
./install-pi-extension-local.sh /path/to/antirez-ds4-checkout
```

If `~/.pi/ds4/support` already exists and points elsewhere, use `--force` to
move it aside and install a symlink to the checkout you passed.

Then restart pi or run `/reload`.

## Runtime layout

Runtime state is kept under `~/.pi/ds4`:

- `support/` — shallow checkout of `https://github.com/antirez/ds4` (`main` by default)
- `kv/` — on-disk KV cache
- `clients/` — active pi process leases
- `log` — build/download/server/watchdog log

The watchdog is bundled in this package (`ds4-watchdog.sh`), not expected to
exist in the ds4 runtime checkout.

## Configuration

Environment overrides:

- `DS4_SUPPORT_REPO`: runtime repo URL (default `https://github.com/antirez/ds4`)
- `DS4_SUPPORT_BRANCH`: runtime branch (default `main`)
- `DS4_RUNTIME_DIR`: use an existing ds4 checkout instead of `~/.pi/ds4/support`
- `DS4_MODEL_QUANT`: force `q2` or `q4` (otherwise picked from system memory)
- `DS4_READY_TIMEOUT_MS`: server startup timeout
- `DS4_SERVER_BINARY`: custom `ds4-server` binary path

Use `/ds4` inside pi to show the live ds4 log.
