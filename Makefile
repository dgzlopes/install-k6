update-version:
	@echo "Fetching the latest k6 version from GitHub..."
	@latest_version=$$(curl -sSL https://api.github.com/repos/grafana/k6/releases/latest \
	| grep '"tag_name":' \
	| awk -F '"' '{print $$4}'); \
	echo "$$latest_version" > latest-version.txt; \
	echo "Latest version: $$latest_version"; \
	echo "Latest version saved to latest-version.txt"
