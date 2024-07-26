install-opensuse-deps:
	zypper install SDL2-devel

install-ubuntu-deps:
	apt install libsdl2-dev

build-static:
	docker run --rm -it -v $$(pwd):/workspace -w /workspace crystallang/crystal:latest-alpine bin/build-alpine.sh
