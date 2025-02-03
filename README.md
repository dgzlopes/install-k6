# 📦 install-k6
*A simple, polite way to install [k6](https://github.com/grafana/k6) – performance testing made easy!*  

## 🛠 Installation
To install `k6`, run:  
```sh
curl https://install-k6.com/please.sh | sh
```

### What does this script do?
- Detects your OS & architecture
- Downloads the latest k6 release and installs it in `~/.k6/bin`
- Shows how to add `~/.k6/bin` to your `PATH`

### Can I pick a specific version?

Yes! You can pass the version as an environment variable:
```sh
K6_VERSION=0.54.0 sh -c "$(curl -fsSL https://install-k6.com/please.sh)"
```

