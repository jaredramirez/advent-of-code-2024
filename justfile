dev app="day1":
	#!/usr/bin/env bash
	roc_main="src/{{app}}.roc"
	watchexec -c \
		--filter "src/Common.roc" \
		--filter "$roc_main" \
		-- just dev_base "$roc_main"

dev_base roc_main:
	roc dev {{roc_main}}
