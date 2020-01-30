FROM golang:alpine as builder
LABEL maintainer="Pasad Tengse <code@prasadt.com>"

ENV PATH /go/bin:/usr/local/go/bin:$PATH
ENV GOPATH /go

RUN  apk add --no-cache \
	bash \
	ca-certificates

COPY . /go/src/github.com/tprasadtp/dummy

RUN set -x \
	&& apk add --no-cache --virtual .build-deps \
		git \
		gcc \
		libc-dev \
		libgcc \
		make \
	&& cd /go/src/github.com/tprasadtp/dsn-now \
	&& make static \
	&& mv dsn-now /usr/bin/dsn-now \
	&& echo "Build complete."

FROM alpine:latest

COPY --from=builder /usr/bin/dsn-now /usr/bin/dsn-now
COPY --from=builder /etc/ssl/certs/ /etc/ssl/certs

ENTRYPOINT [ "dsn-now" ]
CMD [ "help" ]
