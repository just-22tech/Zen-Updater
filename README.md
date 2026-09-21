# Zen Browser (.deb) Auto-Packager (Smart Version)

This repository automates the packaging of [Zen Browser](https://github.com/zen-browser/desktop) into a native Debian (`.deb`) package using GitHub Actions and Docker Compose. 

## 🧠 Smart Update Logic
This workflow is fully optimized and "smart":
1. **Checks for Updates First:** Before spinning up Docker, the GitHub Action checks the official Zen repository for the latest release tag.
2. **Skips if Unchanged:** It compares the fetched tag against `.github/latest_version.txt`. If they match, it prints `"No update available"` and exits peacefully gracefully.
3. **Builds & Commits:** If a new update is found, it automatically builds the `.deb` package, uploads it, and then auto-commits the updated tracker back to this repository.

## 📦 How to Download & Install
Let GitHub do the building. To grab your package:
1. Go to the **Actions** tab of this repository on GitHub.
2. Click on the latest successful workflow run.
3. Scroll down to the **Artifacts** section at the bottom of the page.
4. Download the `zen-browser-deb` zip file, extract it, and you will find your `.deb` package inside.

To install the downloaded package on your local system, run:
```bash
sudo dpkg -i zen-browser_*.deb
sudo apt-get install -f  # (Fetches any missing dependencies like GTK or ALSA automatically)
```

## 💻 Local Testing
You can run this locally using Docker. Note: A temporary `build_artifacts/` directory will automatically be created in your root folder during the build to drop the `.deb` file.

```bash
docker compose up --build
```

---
**Core Dependencies Note:** 
The `DEBIAN/control` strictly references libraries like `libgtk-3-0`, `libasound2` so that your system's package manager properly maps the Zen executable requirements.
