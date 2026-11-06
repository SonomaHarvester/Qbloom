PREFIX ?= /usr/local
DESTDIR ?=
SWIFT ?= swift

.PHONY: all build test install package

all: build

build:
	$(SWIFT) build -c release

test:
	$(SWIFT) test

install:
	env PREFIX="$(PREFIX)" DESTDIR="$(DESTDIR)" SWIFT="$(SWIFT)" sh scripts/install.sh

package:
	env SWIFT="$(SWIFT)" sh scripts/package.sh
