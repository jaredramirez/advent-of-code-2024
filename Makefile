.PHONY: dev

dev:
	echo -e "${ROC_MAIN}\nsrc/Common.roc" | entr -c roc dev ${ROC_MAIN}
