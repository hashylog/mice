EMACS ?= emacs
BATCH = $(EMACS) -Q --batch -L .

SOURCES = mice-indent.el mice-modes.el mice-motion.el mice-edit.el \
	mice-search.el mice-commands.el mice-keys.el mice.el

.PHONY: all compile test clean

all: compile test

compile:
	$(BATCH) --eval '(setq byte-compile-error-on-warn t)' -f batch-byte-compile $(SOURCES)

TESTS = $(wildcard test/*-test.el)

test:
	$(BATCH) -L test $(addprefix -l ,$(TESTS)) -f ert-run-tests-batch-and-exit

clean:
	rm -f *.elc test/*.elc
