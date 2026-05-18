.PHONY: test lint assets investor bundle xcodegen validate-secrets

test:
	swift test

lint:
	swiftlint lint

xcodegen:
	xcodegen generate

assets:
	pip install -r scripts/requirements.txt
	python3 scripts/generate_distribution_assets.py

investor:
	pip install -r scripts/requirements.txt
	python3 scripts/ethereal_veil_investor_report.py

bundle: assets investor
	./scripts/bundle_distribution.sh dist

validate-secrets:
	./scripts/validate_distribution_secrets.sh
