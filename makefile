IMAGENAME = centos-base
VERSION = $(shell cat VERSION)
BASE_TAG = zenoss/$(IMAGENAME):$(VERSION)
JAVA_TAG = zenoss/$(IMAGENAME):$(VERSION)-java
UNSQUASHED = zenoss/$(IMAGENAME)-unsquashed:$(VERSION)
CONTAINER = zenoss_centos_base_container

.PHONY: build build-base build-java push clean release verifyImage verifyVersion

build: build-base build-java

build-base:
	@if [ -z "$$(docker image ls -q $(BASE_TAG))" ]; then  \
		echo Building base image; \
		docker build -t $(UNSQUASHED) . || exit 1; \
		docker run --name $(CONTAINER) -d $(UNSQUASHED) echo || exit 1; \
		echo Squashing image; \
		docker export $(CONTAINER) | docker import - $(BASE_TAG) || exit 1; \
		echo Created image $(BASE_TAG); \
		docker container rm $(CONTAINER); \
		docker image rm $(UNSQUASHED); \
	 else \
	    echo Image $(BASE_TAG) already built.; \
	 fi

build-java: Dockerfile.java build-base
	@if [ -z "$$(docker image ls -q $(JAVA_TAG))" ]; then  \
		echo Building java image; \
		docker build -f $< -t $(JAVA_TAG) .; \
	 else \
	    echo Image $(JAVA_TAG) already built.; \
	 fi

push:
	docker push $(BASE_TAG)
	docker push $(JAVA_TAG)

# Don't generate an error if the image does not exist
clean:
	-docker rmi $(BASE_TAG) $(JAVA_TAG) $(UNSQUASHED)
	-rm -f Dockerfile.java

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

Dockerfile.java: Dockerfile.java.in
	@sed -e 's/%VERSION%/$(VERSION)/g' $< > $@
