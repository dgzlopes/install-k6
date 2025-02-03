# 📦 install-k6
*A simple, polite way to install [k6](https://github.com/grafana/k6) – performance testing made easy!*  

## 🛠 Installation
To install `k6`, run:  
```sh
curl -o- https://raw.githubusercontent.com/dgzlopes/install-k6/main/please.sh | sh
```

### What does this script do?
- Detects your OS & architecture
- Downloads the latest k6 release and installs it in `~/.k6/bin`
- Shows how to add `~/.k6/bin` to your `PATH`

### Can I pick a specific version?

Yes! Just pass the version as an environment variable:
```sh
K6_VERSION=v0.54.0 curl -o- https://raw.githubusercontent.com/dgzlopes/install-k6/main/please.sh | sh
```

