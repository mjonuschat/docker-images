FROM hashicorp/packer:latest
RUN apk --no-cache add \
  ca-certificates \
  cmake \
  docker \
  gcc \
  g++ \
  libc-dev \
  make
WORKDIR /build
ENTRYPOINT []
