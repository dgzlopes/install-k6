# 📦 install-k6
*A simple and polite way to setup [Grafana k6](https://github.com/grafana/k6) on Linux, macOS, and WSL.*

You run:  
```sh
curl -fsSL  https://install-k6.com/please.sh | bash
```

And... that's it ✨

![demo](https://github.com/user-attachments/assets/43d92050-004a-4b83-a84b-d817e0a6a627)

## F.A.Q

### What does this script do?
- Detects your OS & architecture
- Downloads the latest k6 release and installs it in `~/.k6/bin`
- Tries to add `~/.k6/bin` to your PATH. If it fails, it will suggest you do it manually.

### How do I update k6?

Just run the installation script again! It will download the latest version and replace the existing one.

### Can I pick a specific version?

Yes! You can pass the version as an environment variable:
```sh
curl -fsSL https://install-k6.com/please.sh | bash -s v0.54.0
```

