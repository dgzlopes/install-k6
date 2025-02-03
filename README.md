# 📦 install-k6
*A simple, polite way to install [k6](https://github.com/grafana/k6) – performance testing made easy!*  

## 🛠 Installation
To install `k6`, simply run:  
```sh
curl -o- https://raw.githubusercontent.com/dgzlopes/install-k6/main/please.sh | sh
```

### What does this script do?
- Downloads the latest k6 release
- Detects your OS & architecture
- Installs k6 in ~/.k6/bin
- Tells you how to add k6 to your PATH

### Can I pick a specific version?

Yes, just pass the version as an environment variable:
```sh
K6_VERSION=v0.54.0 curl -o- https://raw.githubusercontent.com/dgzlopes/install-k6/main/please.sh | sh
```

