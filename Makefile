CLI_JS := build/atw.js

.PHONY: cli dingus all
cli: $(CLI_JS)
all: cli dingus
dingus:
	make -C dingus

.PHONY: clean
clean:
	rm -rf parser.js build/ tool/munge.js node_modules typings
	make -C dingus clean

include ts.mk


# Build the parser from the grammar.

parser.js: src/grammar.pegjs $(call npmdep,pegjs)
	$(call npmbin,pegjs) --cache < $< > $@


# The command-line Node tool.

TS_SRC := $(shell find src/ -type f -name '*.ts')
$(CLI_JS): $(TS_SRC) atw.ts parser.js $(TYPINGS_MAIN) $(TSC)
	$(TSC)


# Running tests.

define run_tests
for name in $1 ; do \
	sh test.sh $2 $$name ; \
	if [ $$? -ne 0 ] ; then failed=1 ; fi ; \
done
endef

TESTS_BASIC := $(wildcard test/basic/*.atw) $(wildcard test/snippet/*.atw) \
	$(wildcard test/if/*.atw)
TESTS_COMPILE := $(TESTS_BASIC) $(wildcard test/compile/*.atw)
TESTS_INTERP := $(TESTS_BASIC) $(wildcard test/static/*.atw) \
	$(wildcard test/interp/*.atw) $(wildcard test/macro/*.atw)

.PHONY: test-compile
test-compile: $(CLI_JS)
	@ node $(CLI_JS) -t -cx $(TESTS_COMPILE)

.PHONY: test-interp
test-interp: $(CLI_JS)
	@ node $(CLI_JS) -t $(TESTS_INTERP)

# A few compile tests *without* pre-splicing. This can fail when using splices
# in a function quote.
.PHONY: test-compile-unsplice
test-compile-unsplice:
	@ node $(CLI_JS) -t -cPx $(wildcard test/snippet/*.atw)

.PHONY: test
test: $(CLI_JS)
	@ echo "interpreter" ; \
	node $(CLI_JS) -t $(TESTS_INTERP) || failed=1 ; \
	echo ; \
	echo "compiler" ; \
	node $(CLI_JS) -t -cx $(TESTS_COMPILE) || failed=1 ; \
	[ ! $$failed ]

# Just dump the output code for the WebGL examples.
.PHONY: dump-gl
dump-gl: $(CLI_JS)
	@ node $(CLI_JS) -cw $(wildcard test/webgl/*.atw)


# An asset-munging tool.

tool/munge.js: tool/munge.ts $(TSC) $(TYPINGS_MAIN)
	$(TSC) --out $@ $<


# Documentation.

.PHONY: docs
docs: docs/build/index.html docs/build/docs.js

docs/build/index.html: docs/index.md $(call npmdep,madoko)
	cd docs; $(call npmbin,madoko) --odir=build ../$<

docs/build/docs.js: docs/docs.ts $(TSC)
	$(TSC) --out $@ $<


# Deploy the dingus and docs.

.PHONY: deploy
RSYNCARGS := --compress --recursive --checksum --delete -e ssh \
	--exclude node_modules --exclude package.json --exclude gl.js \
	--exclude '*.ts' --exclude docs
DEST := dh:domains/adriansampson.net/atw
deploy: dingus docs
	rsync $(RSYNCARGS) dingus/ $(DEST)
	rsync $(RSYNCARGS) docs/build/ $(DEST)/docs


# Auto-build using https://facebook.github.io/watchman/

.PHONY: watch
watch:
	watchman-make --settle 0.1 \
		-p 'docs/*.md' 'docs/*.ts' -t docs \
		-p 'src/**/*.ts' 'src/*.pegjs' atw.ts -t cli \
		-p 'src/**/*.ts' 'src/*.pegjs' 'dingus/*.ts' 'dingus/gl.js' \
			'dingus/examples/*.atw' -t dingus


# Lint.

.PHONY: lint
lint:
	find src -name '*.ts' | xargs tslint
	find dingus -name '*.ts' | xargs tslint
	tslint atw.ts
