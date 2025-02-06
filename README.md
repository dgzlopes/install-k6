# 📦 install-k6
*A simple and polite way to setup [Grafana k6](https://github.com/grafana/k6) on Linux, macOS, and WSL*

You run:  
```sh
curl -fsSL  https://install-k6.com/please.sh | bash
```

And... that's it ✨

https://github.com/user-attachments/assets/28256741-405a-4027-a206-430e3eb708e9

## F.A.Q

### What does this script do?
- Detects your OS & architecture
- Downloads the latest k6 release and installs it in `~/.k6/bin`
- Tries to add `~/.k6/bin` to your PATH. If it fails, it will suggest you do it manually.
- Checks if there are new k6 versions available and prompts you to update from time to time.

### How do I update k6?

Just run the installation script again! It will download the latest version and replace the existing one.

### Can I pick a specific version?

Yes! You can pass the version as an environment variable:
```sh
curl -fsSL https://install-k6.com/please.sh | bash -s v0.54.0
```

### Can I disable the updates check?

Yes! You can pass the `--no-update-check` flag:
```sh
curl -fsSL https://install-k6.com/please.sh | bash -s -- --no-update-check
```

## Credits 

To the [bun](https://bun.sh) team - this script is **heavily** inspired by their [bun installer](https://bun.sh/docs/installation).