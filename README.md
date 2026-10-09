# Zen Browser `.deb` Auto-Packager

Automated pipeline that watches for new [Zen Browser](https://zen-browser.app) releases and packages them into native Debian (`.deb`) packages.

## How It Works

1. An external webhook fires a `repository_dispatch` event whenever a new Zen Browser tag is published.
2. The GitHub Actions workflow validates the tag and checks for duplicate releases.
3. If the release is new, it builds the `.deb` package inside a Docker container and publishes it as a GitHub Release.

## Installation

Head to the [Releases](../../releases) page, download the latest `.deb`, and install:

```bash
sudo dpkg -i zen-browser_*.deb
sudo apt-get install -f
```

## Local Build

Requires Docker and Docker Compose.

```bash
ZEN_VERSION="1.0.0" docker compose up --build
```

The `.deb` file will be placed in `build_artifacts/`.
