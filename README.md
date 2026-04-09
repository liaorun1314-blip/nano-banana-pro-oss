# Nano Banana Pro OSS

`Nano Banana Pro OSS` is an open-source prompt library and local web app for organizing, searching, and reusing high-quality visual prompts.

This project is an independent community edition built for local use and open collaboration.

## Features

- Prompt library with categories and sources
- Fast keyword search and category filtering
- One-click prompt copy
- Local-first: run with built-in Python HTTP server
- Script to extract prompt blocks from markdown collections

## Quick Start

```bash
cd /path/to/nano-banana-pro-oss
python3 -m http.server 8787
```

Then open:

- `http://localhost:8787/app/`

## Install As Local Service (macOS)

Install service + CLI command in one step:

```bash
cd /path/to/nano-banana-pro-oss
bash scripts/install_service.sh
```

By default, the installer syncs runtime files to `~/nano-banana-pro-oss` and runs the service from there.
You can override install location with `NANO_BANANA_INSTALL_ROOT`.

If `nano-banana-pro` is not found, add user bin path:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

Then:

- `nano-banana-pro open` to launch in browser
- `nano-banana-pro status` to check service status
- `nano-banana-pro stop` to stop the service
- `nano-banana-pro start` to start the service

## Import Prompts From Markdown

You can extract prompt blocks from a markdown collection into JSON:

```bash
cd /path/to/nano-banana-pro-oss
python3 scripts/extract_awesome_prompts.py \
  --input /Users/kunding/Downloads/awesome-nanobanana-pro-main/README.md \
  --output prompts/prompts.generated.json
```

## Project Structure

```text
nano-banana-pro-oss/
├── app/
│   ├── index.html
│   ├── main.js
│   └── style.css
├── prompts/
│   └── prompts.json
├── scripts/
│   ├── install_service.sh
│   └── extract_awesome_prompts.py
├── LICENSE
└── README.md
```

## License

MIT
