IMAGENAME  = centos-base
VERSION   ?= 1.1.0-dev
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

# Don't generate an error if the image does not exist
clean:
	-docker rmi $(TAG) $(TAG)-java

# Generate a make failure if the VERSION string contains "-<some letters>"
verifyVersion:
	@./verifyVersion.sh $(VERSION)

# Generate a make failure if the image(s) already exist
verifyImage:
	@./verifyImage.sh zenoss/$(IMAGENAME) $(VERSION)
	@./verifyImage.sh zenoss/$(IMAGENAME) $(VERSION)-java

# Do not release if the image version is invalid
# This target is intended for use when trying to build/publish images from the master branch
release: verifyVersion verifyImage clean build push
