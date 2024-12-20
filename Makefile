.PHONY: dev

dev:
	echo "${ROC_MAIN}" | entr -c roc dev ${ROC_MAIN}
