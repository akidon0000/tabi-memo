.PHONY: xcode-open clean

SHELL := /bin/bash

# 開く対象（ワークスペースを優先、なければプロジェクト）を自動検出
TARGET := $(firstword $(wildcard *.xcworkspace) $(wildcard *.xcodeproj))

## xcode-open : Mac内のXcode一覧から矢印キーで選んで開く
xcode-open:
	@if [ -z "$(TARGET)" ]; then echo "開く対象(.xcworkspace/.xcodeproj)が見つかりません"; exit 1; fi; \
	apps=(); \
	while IFS= read -r line; do apps+=("$$line"); done < <(ls -d /Applications/Xcode*.app 2>/dev/null); \
	if [ $${#apps[@]} -eq 0 ]; then echo "Xcodeが見つかりません"; exit 1; fi; \
	if [ $${#apps[@]} -eq 1 ]; then \
		echo "$${apps[0]} で開きます..."; \
		open -a "$${apps[0]}" "$(TARGET)"; \
		exit 0; \
	fi; \
	labels=(); \
	for x in "$${apps[@]}"; do \
		labels+=("$$(basename "$$x")"); \
	done; \
	labels+=("キャンセル"); \
	sel=0; n=$${#labels[@]}; \
	printf "開く対象: $(TARGET)\n"; \
	tput civis 2>/dev/null; \
	draw() { for ((i=0;i<n;i++)); do \
		if [ $$i -eq $$sel ]; then printf "\033[7m> %s\033[0m\n" "$${labels[$$i]}"; \
		else printf "  %s\n" "$${labels[$$i]}"; fi; done; }; \
	draw; \
	while true; do \
		IFS= read -rsn1 key; \
		if [ "$$key" = $$'\033' ]; then read -rsn2 rest; key+="$$rest"; fi; \
		case "$$key" in \
			$$'\033[A') sel=$$(( (sel-1+n)%n ));; \
			$$'\033[B') sel=$$(( (sel+1)%n ));; \
			q|Q) tput cnorm 2>/dev/null; echo "キャンセルしました"; exit 0;; \
			"") break;; \
		esac; \
		printf "\033[%dA" "$$n"; draw; \
	done; \
	tput cnorm 2>/dev/null; \
	if [ $$sel -eq $${#apps[@]} ]; then echo "キャンセルしました"; exit 0; fi; \
	app="$${apps[$$sel]}"; \
	echo "$$app で開きます..."; \
	open -a "$$app" "$(TARGET)"

# プロジェクト名（DerivedData絞り込み用）
PROJECT := $(basename $(TARGET))

## clean : Xcodeを終了し、DerivedData / SPMキャッシュ / ビルド成果物を削除
clean:
	@echo "Xcodeを終了します..."; \
	osascript -e 'tell application "Xcode" to quit' 2>/dev/null || true; \
	sleep 1; \
	echo "DerivedData を削除します..."; \
	rm -rf ~/Library/Developer/Xcode/DerivedData/$(PROJECT)-* 2>/dev/null || true; \
	echo "SPMキャッシュを削除します..."; \
	rm -rf ~/Library/Caches/org.swift.swiftpm 2>/dev/null || true; \
	rm -rf ~/Library/org.swift.swiftpm 2>/dev/null || true; \
	echo "プロジェクト内のビルド成果物を削除します..."; \
	rm -rf .build .swiftpm 2>/dev/null || true; \
	find . -name "*.xcodeproj" -prune -o -name ".build" -type d -exec rm -rf {} + 2>/dev/null || true; \
	echo "完了しました"
