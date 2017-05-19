# Create a common image based on Alpine Linux and add to it the needed tooling.
# See base/Dockerfile for the details.

.DEFAULT_GOAL := baseimg

.PHONY: baseimg

ROOT := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

ALPINE_LINUX_VERSION := 3.5

DOCKER_BUILD_FLAGS := --rm
DOCKER_BUILD_FLAGS += --tag alpine_$(ALPINE_LINUX_VERSION)-onebit

DOCKER_BASE_IMG_DIR := $(ROOT)/base

baseimg: ; docker build $(DOCKER_BUILD_FLAGS) $(DOCKER_BASE_IMG_DIR)
