include versions.mk

APPLICATION = centos-base
PROJECT = zenoss
TAG = $(VERSION)
BASEIMAGE = $(PROJECT)/$(APPLICATION):$(TAG)
JAVAIMAGE = $(BASEIMAGE)-java

TEMP_NAME = build-$(APPLICATION)-$(VERSION)

BASEIMAGE_EXISTS = $(shell docker image list --format '{{.Tag}}' $(BASEIMAGE))
JAVAIMAGE_EXISTS = $(shell docker image list --format '{{.Tag}}' $(JAVAIMAGE))
RPM_PACKAGES = $(shell cat yum_package_list.txt)

.PHONY: build build-base push clean

build: build-base

build-base: baseimage/Dockerfile
ifeq ($(BASEIMAGE_EXISTS),)
	@echo Building base image...
	@cp -a scrub.sh baseimage/scrub.sh
	@cd baseimage; docker build -t $(TEMP_NAME) .
	@docker container create --name $(TEMP_NAME) $(TEMP_NAME) echo
	@echo Squashing image...
	@docker container export $(TEMP_NAME) | docker image import - $(BASEIMAGE)
	@docker container rm $(TEMP_NAME)
	@docker image rm $(TEMP_NAME)
else
	@echo Base image already built.
endif

# build-java: build-base javaimage/Dockerfile
# ifeq ($(JAVAIMAGE_EXISTS),)
# 	@echo Building java base image...
# 	@cd javaimage; docker build -t $(TEMP_NAME) .
# 	@docker container create --name $(TEMP_NAME) $(TEMP_NAME) echo
# 	@echo Squashing image...
# 	@docker container export $(TEMP_NAME) | docker image import - $(JAVAIMAGE)
# 	@docker container rm $(TEMP_NAME)
# 	@docker image rm $(TEMP_NAME)
# else
# 	@echo Java base image already built.
# endif

baseimage/Dockerfile: | baseimage
baseimage/Dockerfile: Dockerfile.in
	@sed -e "s/%PACKAGES%/$(RPM_PACKAGES)/" $< > $@

# javaimage/Dockerfile: | javaimage
# javaimage/Dockerfile: Dockerfile.java.in
# 	@sed -e 's/%VERSION%/$(VERSION)/g' $< > $@

baseimage:
	@mkdir $@

push:
	docker push $(BASEIMAGE)
#	docker push $(JAVAIMAGE)

# Don't generate an error if the image does not exist
clean:
ifneq ($(BASEIMAGE_EXISTS),)
	-docker image rm $(BASEIMAGE)
	BASEIMAGE_EXISTS=
endif
	-rm -rf baseimage

# Generate a make failure if the VERSION string contains "-<some letters>"
verifyVersion:
	@./verifyVersion.sh $(VERSION)

# Generate a make failure if the image(s) already exist
verifyImage:
	@./verifyImage.sh $(PROJECT)/$(APPLICATION) $(VERSION)
#	@./verifyImage.sh $(PROJECT)/$(APPLICATION) $(VERSION)-java

# Do not release if the image version is invalid
# This target is intended for use when trying to build/publish images from the master branch
release: verifyVersion verifyImage clean build push
