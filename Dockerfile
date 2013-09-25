FROM ubuntu:12.10

MAINTAINER "Guillaume J. Charmes <guillaume@dotcloud.com>"

# Update apt repos
RUN apt-get update

# Install Deps
RUN apt-get install -q -y mercurial git build-essential

# Install Go itself
ENV GOPATH /go

RUN mkdir -p $GOPATH
RUN hg clone https://code.google.com/p/go /goroot
RUN cd /goroot/src && ./all.bash

ENV PATH /goroot/bin:$PATH

# Download/configure/build lvm2
RUN git clone git://git.fedorahosted.org/git/lvm2.git && cd /lvm2 && ./configure --enable-static_link && make && cd libdm && make install

# Retrieve Docker
RUN go get github.com/alexlarsson/docker
RUN ln -s /go/src/github.com/alexlarsson/docker /docker

# Grab alex's branch and rebase master (for gh#1822)
#RUN cd /docker && git checkout -b alexlarsson-device-mapper2 master && git pull https://github.com/alexlarsson/docker.git device-mapper2

# Create Go cache with tag netgo
RUN cd /docker; go install -ldflags '-w -linkmode external -extldflags "-static -Wl,--unresolved-symbols=ignore-in-shared-libs"' -tags netgo -a std

# Compile docker test binary
RUN cd /docker; go test -v . -c -ldflags '-w -linkmode external -extldflags "-static -Wl,--unresolved-symbols=ignore-in-shared-libs"' -tags netgo

# Compile/Install docker
RUN cd /docker/docker; go build -ldflags '-w -linkmode external -extldflags "-static -Wl,--unresolved-symbols=ignore-in-shared-libs"' -tags netgo; cp docker /goroot/bin
