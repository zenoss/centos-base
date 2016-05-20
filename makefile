IMAGENAME  = centos-base
VERSION   ?= 1.0.3-dev1
TAG = zenoss/$(IMAGENAME):$(VERSION)

.PHONY: build build-base build-java push clean

build: build-base build-java

build-base:
	@echo Building base image
	@if [ -z "$$(docker images zenoss/$(IMAGENAME) | awk '{print $$2}' | grep -e '^$(VERSION)$$')" ]; then  \
		docker build -t foo-$(VERSION) . || exit 1; \
		export CONTAINER=$$(docker run -d foo-$(VERSION) echo) || exit 1; \
		echo Squashing image; \
		docker export $${CONTAINER} | docker import - $(TAG) || exit 1; \
	 fi


build-java: build-base
	@echo Building java image
	@sed -e 's/%VERSION%/$(VERSION)/g' Dockerfile.java.in > Dockerfile.java
	@docker build -f Dockerfile.java -t zenoss/$(IMAGENAME):$(VERSION)-java .

push:
	docker push $(TAG)
	docker push $(TAG)-java

clean:
	docker rmi $(TAG) $(TAG)-java
