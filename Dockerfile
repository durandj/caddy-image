# syntax=docker/dockerfile:1

FROM golang:1.25.1 AS caddy_builder

ARG XCADDY_VERSION

WORKDIR /code

COPY ./go.mod ./go.sum ./

RUN set -o errexit -o xtrace \
	&& CADDY_VERSION="$(go list -m -f '{{.Version}}' github.com/caddyserver/caddy/v2)" \
	&& CADDY_DOCKER_PROXY_VERSION="$(go list -m -f '{{.Version}}' github.com/lucaslorentz/caddy-docker-proxy/v2)" \
	&& CLOUDFLARE_VERSION="$(go list -m -f '{{.Version}}' github.com/caddy-dns/cloudflare)" \
	&& go install "github.com/caddyserver/xcaddy/cmd/xcaddy@${XCADDY_VERSION}" \
	&& CGO_ENABLED=0 GOARCH=amd64 GOOS=linux \
		xcaddy build \
			"${CADDY_VERSION}" \
			--output caddy \
			--with "github.com/lucaslorentz/caddy-docker-proxy/v2@${CADDY_DOCKER_PROXY_VERSION}" \
			--with "github.com/caddy-dns/cloudflare@${CLOUDFLARE_VERSION}"


FROM debian:bullseye-slim

WORKDIR /

EXPOSE 80 443 2019

ENV XDG_CONFIG_HOME=/config \
	XDG_DATA_HOME=/data

# hadolint ignore=DL3008
RUN set -o errexit -o xtrace \
	&& apt-get update \
	&& apt-get install --yes --no-install-recommends \
	ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint.sh /
COPY --from=caddy_builder /code/caddy /bin/

ENTRYPOINT [ "/docker-entrypoint.sh" ]

CMD [ "docker-proxy" ]
