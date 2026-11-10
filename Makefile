.PHONY: check verify doc-links-check tree-id

# この設定の検証は短いため、反復時にも検査を省かない。
check: verify

verify:
	bash scripts/verify.sh

doc-links-check:
	nvim --clean --headless -l scripts/doc-links.lua

# 作業木の内容のID（未コミット・未追跡を含む）。MakerとCheckerが同じ版を照合する。
tree-id:
	@sh scripts/tree-id.sh -v
