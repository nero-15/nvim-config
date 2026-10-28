.PHONY: check verify doc-links-check

# この設定の検証は短いため、反復時にも検査を省かない。
check: verify

verify:
	bash scripts/verify.sh

doc-links-check:
	nvim --clean --headless -l scripts/doc-links.lua
