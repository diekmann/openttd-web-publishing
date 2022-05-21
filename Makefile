
openttd := $(PWD)/OpenTTD

all:
	git clone git@github.com:OpenTTD/OpenTTD.git || echo reusing local checkout
	cd OpenTTD;	pwd; git checkout 'origin/release/12'
	# https://github.com/OpenTTD/OpenTTD/tree/master/os/emscripten
	cd OpenTTD/os/emscripten; docker build -t emsdk-lzma .
	
	echo $(openttd)

	mkdir -p OpenTTD/build-host
	docker run -it --rm -v ${openttd}:${openttd} -u $(shell id -u):$(shell id -g) --workdir ${openttd}/build-host emsdk-lzma cmake .. -DOPTION_TOOLS_ONLY=ON
	docker run -it --rm -v $(openttd):$(openttd) -u $(shell id -u):$(shell id -g) --workdir $(openttd)/build-host emsdk-lzma make -j5 tools
	mkdir -p OpenTTD/build
	cd OpenTTD; docker run -it --rm -v $(openttd):$(openttd) -u $(shell id -u):$(shell id -g) --workdir $(openttd)/build emsdk-lzma emcmake cmake .. -DHOST_BINARY_DIR=../build-host -DCMAKE_BUILD_TYPE=Release -DOPTION_USE_ASSERTS=OFF
	cd OpenTTD; docker run -it --rm -v $(openttd):$(openttd) -u $(shell id -u):$(shell id -g) --workdir $(openttd)/build emsdk-lzma emmake make -j5

gh-pages: all
	mkdir -p ./public
	cp -r ./OpenTTD//build/openttd* ./public/

clean:
	rm -rf ./OpenTTD
	rm -rf ./public

