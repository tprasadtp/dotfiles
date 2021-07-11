#syntax=docker/dockerfile:1.2

FROM ubuntu:focal as base
LABEL "io.github.tprasadtp.shlib-test-image"="true"
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt/lists \
    apt-get update && apt-get install --no-install-recommends --yes bash ash zsh dash

FROM base as none
# Please, do not do this anywhere else!
# This leaves your system/container in a broken state as it removes apt!
RUN apt-get purge --yes --allow-remove-essential gpgv

FROM base as all
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get install --no-install-recommends --yes curl wget gpg rhash perl

FROM base as curl-gpgv
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get install --no-install-recommends --yes curl

FROM base as curl-gpg
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get install --no-install-recommends --yes curl gpg

FROM base as wget-gpgv
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get install --no-install-recommends --yes wget

FROM base as wget-gpg
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get install --no-install-recommends --yes gpg wget
