
openttd := $(PWD)/OpenTTD

ROOTLESS_DOCKER := $(shell docker info 2>/dev/null | grep -q rootless && echo 1 || echo 0)
ifeq ($(ROOTLESS_DOCKER), 1)
	DOCKER_USER := 
else
	DOCKER_USER := -u $(shell id -u):$(shell id -g)
endif

all:
	git clone https://github.com/OpenTTD/OpenTTD.git || echo reusing local checkout
	cd OpenTTD;	pwd; git checkout 'origin/release/12'
	# https://github.com/OpenTTD/OpenTTD/tree/master/os/emscripten
	cd OpenTTD/os/emscripten; docker build -t emsdk-lzma .
	
	echo $(openttd)

	mkdir -p OpenTTD/build-host
	docker run --rm -v $(openttd):$(openttd) $(DOCKER_USER) --workdir $(openttd)/build-host emsdk-lzma cmake .. -DOPTION_TOOLS_ONLY=ON
	docker run --rm -v $(openttd):$(openttd) $(DOCKER_USER) --workdir $(openttd)/build-host emsdk-lzma make -j5 tools
	mkdir -p OpenTTD/build
	cd OpenTTD; docker run --rm -v $(openttd):$(openttd) $(DOCKER_USER) --workdir $(openttd)/build emsdk-lzma emcmake cmake .. -DHOST_BINARY_DIR=../build-host -DCMAKE_BUILD_TYPE=Release -DOPTION_USE_ASSERTS=OFF
	cd OpenTTD; docker run --rm -v $(openttd):$(openttd) $(DOCKER_USER)--workdir $(openttd)/build emsdk-lzma emmake make -j5

gh-pages: all
	mkdir -p ./public
	cp -r ./OpenTTD//build/openttd* ./public/

clean:
	rm -rf ./OpenTTD
	rm -rf ./public

