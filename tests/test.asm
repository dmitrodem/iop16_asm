xxx:
	lri r1, #ab
	xri r1, #cd
tgt:	iow r1, #00
	jmp xxx
