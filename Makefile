CGO_ENABLED=0
GOOS=linux
GOARCH=amd64
TAG?=latest
MAINT?=opsforge
IMAGE?=shipyard
COMMIT=`git rev-parse --short HEAD`

all: build media

clean:
	@rm -rf controller/controller

build:
	@cd controller && godep go build -a -tags "netgo static_build" -installsuffix netgo -ldflags "-w -X github.com/opsforgeio/shipyard/version.GitCommit=$(COMMIT)" .

remote-build:
	@docker build -t shipyard-build -f Dockerfile.build .
	@rm -f ./controller/controller
	@cd controller && docker run --rm -w /go/src/github.com/opsforgeio/shipyard --entrypoint /bin/bash shipyard-build -c "make build 1>&2 && cd controller && tar -czf - controller" | tar zxf -

media:
	@cd controller/static && bower -s install --allow-root -p | xargs echo > /dev/null

image:
	@echo Building Shipyard image $(TAG)
	@cd controller && docker build -t $(MAINT)/$(IMAGE):$(TAG) .

release: build image
	@echo $(DOCKER_PASS) | docker login -u $(DOCKER_USER) --password-stdin
	@docker push $(MAINT)/$(IMAGE):$(TAG)

test: clean
	@godep go test -v ./...

.PHONY: all build clean media image test release
