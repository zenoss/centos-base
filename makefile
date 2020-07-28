include versions.mk

PROJECT      = zenoss
REPOSITORY   = centos-base
TAG          = $(VERSION)
IMAGE        = $(PROJECT)/$(REPOSITORY):$(TAG)
DEV_IMAGE    = $(PROJECT)/$(REPOSITORY):$(TAG).devtools
EXPORT_IMAGE = export-$(REPOSITORY)-$(VERSION)

EXPORT_CONTAINER = build-$(REPOSITORY)-$(VERSION)
EXPORT_FILE = $(REPOSITORY)_$(VERSION).tar
JAVA_EXPORT_FILE = java.tar

IMAGE_EXISTS = $(shell docker image list --format '{{.Tag}}' $(IMAGE))
DEV_IMAGE_EXISTS = $(shell docker image list --format '{{.Tag}}' $(DEV_IMAGE))
EXPORT_IMAGE_EXISTS = $(shell docker image list --format '{{.Tag}}' $(EXPORT_IMAGE))

RPM_PACKAGES = $(shell cat packages.txt)

.PHONY: build
build: build-image build-dev-image

.PHONY: build-image
build-image: img/Dockerfile img/$(EXPORT_FILE)
	@tar --concatenate --file=img/$(EXPORT_FILE) export/$(JAVA_EXPORT_FILE)
	@docker build -f img/Dockerfile -t $(IMAGE) img

img/Dockerfile: | img
img/Dockerfile: Dockerfile.in
	@sed -e 's/%EXPORT_FILE%/$(EXPORT_FILE)/g' $< > $@

img/$(EXPORT_FILE): | img
img/$(EXPORT_FILE): export/Dockerfile export.sh export/scrub.sh 
	@docker build -f export/Dockerfile -t $(EXPORT_IMAGE) export
	@./export.sh

export/Dockerfile: | export
export/Dockerfile: Dockerfile.export.in
	@sed -e 's/%RPM_PACKAGES%/$(RPM_PACKAGES)/g' $< > $@

export.sh: export.sh.in
	@sed \
		-e 's/%EXPORT_FILE%/$(EXPORT_FILE)/g' \
		-e 's/%CONTAINER_NAME%/$(EXPORT_CONTAINER)/g' \
		-e 's/%EXPORT_IMAGE%/$(EXPORT_IMAGE)/g' \
		-e 's/%JAVA_TAR%/$(JAVA_EXPORT_FILE)/g' \
		$< > $@
	@chmod +x $@

export/scrub.sh: | export
export/scrub.sh: scrub.sh
	@cp $< $@

img export:
	@mkdir -p $@

.PHONY: push
push:
	@docker push $(BASEIMAGE)
#	@docker push $(JAVAIMAGE)

# Don't generate an error if the image does not exist
.PHONY: clean
clean:
	@if [ -n "$(IMAGE_EXISTS)" ]; then docker image rm $(IMAGE); fi
	@if [ -n "$(DEV_IMAGE_EXISTS)" ]; then docker image rm $(DEV_IMAGE); fi
	@if [ -n "$(EXPORT_IMAGE_EXISTS)" ]; then docker image rm $(EXPORT_IMAGE); fi
	@rm -rf img export export.sh

# Generate a make failure if the VERSION string contains "-<some letters>"
.PHONY: verifyVersion
verifyVersion:
	@./verifyVersion.sh $(VERSION)

# Generate a make failure if the image(s) already exist
.PHONY: verifyImage
verifyImage:
	@./verifyImage.sh $(PROJECT)/$(APPLICATION) $(VERSION)
#	@./verifyImage.sh $(PROJECT)/$(APPLICATION) $(VERSION)-java

# Do not release if the image version is invalid
# This target is intended for use when trying to build/publish images from the master branch
.PHONY: release
release: verifyVersion verifyImage clean build push
