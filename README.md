# pi-ds4

Pi provider extension for running [antirez/ds4](https://github.com/antirez/ds4)
as a local DeepSeek V4 Flash model.  The goal here is to see how good the UX
and behavior can be around local models.

The extension registers `ds4/deepseek-v4-flash` and
`ds4/deepseek-v4-flash-q2-imatrix` as models for `/model`, starts `ds4-server`
on demand, downloads/builds the runtime if needed, keeps a per-pi-process lease,
and stops the server via a bundled watchdog when no clients are left.

## Requirements and Behavior

You will need a mac with at least 128GB of RAM.  The default
`ds4/deepseek-v4-flash` model installs the 2-bit quantized model if you have
128GB of RAM and picks the 4-bit quantized model if you have 256GB or more.
Select `ds4/deepseek-v4-flash-q2-imatrix` to use the imatrix-tuned q2 model.

If you are signed into huggingface then your token is used for faster downloads.
The server is compiled/started and models are downloaded automatically on first
use.

## Install

```sh
pi install https://github.com/mitsuhiko/pi-ds4
```

For local development from this checkout, pass the path to an existing ds4 server checkout:

```sh
./install-pi-extension-local.sh /path/to/antirez-ds4-checkout
```

If `~/.pi/ds4/support` already exists and points elsewhere, use `--force` to
move it aside and install a symlink to the checkout you passed. Any existing
`gguf/*.gguf` model files (and resumable `.gguf.part` downloads) are preserved
into the new checkout first, using APFS clone-on-write copies on macOS when
available.

Then restart pi or run `/reload`.

## Runtime layout

Runtime state is kept under `~/.pi/ds4`:

- `support/` — shallow checkout of `https://github.com/antirez/ds4` (`main` by default)
- `kv/` — on-disk KV cache for the default model choice
- `kv-q2-imatrix/` — on-disk KV cache for the q2-imatrix model choice
- `clients/` — active pi process leases
- `settings.json` — optional extension configuration overrides
- `log` — build/download/server/watchdog log

The watchdog is bundled in this package (`ds4-watchdog.sh`), not expected to
exist in the ds4 runtime checkout.

## Configuration

Environment overrides can also be placed in `~/.pi/ds4/settings.json`.  In the
JSON file, use the env var name (for example `"DS4_READY_TIMEOUT_MS"`), the
camel-case key without `DS4_` (for example `"readyTimeoutMs"`), or the lower
snake-case key without `DS4_` (for example `"ready_timeout_ms"`). Environment
variables win over the settings file.

- `DS4_PROTOCOL`: Pi wire protocol. Supported values are `openai` (default,
  OpenAI Chat Completions), `openai-responses`, and `anthropic`.
- `DS4_SUPPORT_REPO`: runtime repo URL (default `https://github.com/antirez/ds4`)
- `DS4_SUPPORT_BRANCH`: runtime branch (default `main`)
- `DS4_RUNTIME_DIR`: use an existing ds4 checkout instead of `~/.pi/ds4/support`
- `DS4_MODEL_QUANT`: force `q2`, `q2-imatrix`, or `q4` for the default model
  choice (otherwise picked from system memory)
- `DS4_READY_TIMEOUT_MS`: server startup timeout
- `DS4_SERVER_BINARY`: custom `ds4-server` binary path
- `DS4_WATCHDOG_SCRIPT`: custom watchdog script path
- `DS4_API_KEY`: provider API key/token sent by Pi (default `dsv4-local`)

See `settings.example.json` for a complete example with a JSON schema reference.
A minimal `~/.pi/ds4/settings.json` can look like this:

```json
{
  "$schema": "https://raw.githubusercontent.com/mitsuhiko/pi-ds4/main/settings.schema.json",
  "protocol": "openai-responses",
  "modelQuant": "q2-imatrix",
  "readyTimeoutMs": 900000
}
```

Use `/ds4` inside pi to show the live ds4 log.
