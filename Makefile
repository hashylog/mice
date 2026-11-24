EMACS ?= emacs
BATCH = $(EMACS) -Q --batch -L .

SOURCES = mice.el mice-indent.el mice-modes.el

.PHONY: all compile test clean

all: compile test

compile:
	$(BATCH) --eval '(setq byte-compile-error-on-warn t)' -f batch-byte-compile $(SOURCES)

test:
	$(BATCH) -l test/mice-test.el -f ert-run-tests-batch-and-exit

clean:
	rm -f *.elc test/*.elc
