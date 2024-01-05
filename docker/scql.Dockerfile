FROM openanolis/anolisos:8.6 as base

ARG TARGETPLATFORM

ENV TZ=Asia/Shanghai

# update os infra
RUN dnf update -y && dnf upgrade -y && dnf clean all

RUN yum install -y iproute-tc
# libgomp is used in spu to speed up psi.
RUN yum install -y libgomp

COPY ./scqlengine /home/admin/bin/scqlengine
COPY ./scdbserver /home/admin/bin/scdbserver
COPY ./scdbclient /home/admin/bin/scdbclient
COPY ./broker /home/admin/bin/broker
COPY ./brokerctl /home/admin/bin/brokerctl

FROM base as image-dev

ARG GO_VERSION=1.21.5

RUN yum install -y wget

RUN if [ "$TARGETPLATFORM" = "linux/arm64" ] ; \
  then \
  GO_ARECH=arm64 && \
  GO_SHA256SUM=841cced7ecda9b2014f139f5bab5ae31785f35399f236b8b3e75dff2a2978d96 ; \
  else \
  GO_ARCH=amd64 && \
  GO_SHA256SUM=e2bc0b3e4b64111ec117295c088bde5f00eeed1567999ff77bc859d7df70078e ; \
  fi \
  && url="https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"; \
  && wget --no-check-certificate -O go.tgz "$url"; \
  && echo "${GO_SHA256SUM} *go.tgz" | sha256sum -c -; \
  && tar -C /usr/local -xzf go.tgz; \
  && rm -f go.tgz

ENV PATH="/usr/local/go/bin:${PATH}" 

#install dlv
RUN go install github.com/go-delve/delve/cmd/dlv@latest

# Add GOPATH to PATH
ENV PATH="${PATH}:/root/go/bin"

FROM base as image-prod