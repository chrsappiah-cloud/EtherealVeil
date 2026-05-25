.PHONY: test lint assets investor bundle xcodegen validate-secrets

test:
	swift test

lint:
	swiftlint lint

xcodegen:
	xcodegen generate

PY ?= python3

assets:
	$(PY) -m pip install -r scripts/requirements.txt 2>/dev/null || true
	$(PY) scripts/generate_distribution_assets.py

investor: assets
	$(PY) scripts/ethereal_veil_investor_report.py

investor-desktop: investor
	@echo "Desktop: $(HOME)/Desktop/EtherealVeil-Investor"

bundle: assets investor
	./scripts/bundle_distribution.sh dist

validate-secrets:
	./scripts/validate_distribution_secrets.sh
