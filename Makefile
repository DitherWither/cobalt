cobalt-builder: Dockerfile
	docker build -t cobalt-builder .

.PHONY: shell
shell: cobalt-builder
	docker run -it --rm --mount source=cobalt-sysroot,destination=/sysroot cobalt-builder bash