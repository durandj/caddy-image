#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

ENTRYPOINT=/bin/caddy

function load_secret_if_set() {
	local secret_name="$1"; shift
	local secret_file="$1"; shift

	if [ -z "${secret_file}" ]; then
		return
	elif ! [ -f "${secret_file}" ]; then
		echo "Secret file variable '${secret_name}' was set but file does not exist at '${secret_file}'"

		exit 1
	fi

	secret="$(cat "${secret_file}")"
	export "${secret_name}"="${secret}"
}

load_secret_if_set "CLOUDFLARE_API_TOKEN" "${CLOUDFLARE_API_TOKEN_FILE:-}"
load_secret_if_set "OIDC_CLIENT_ID" "${OIDC_CLIENT_ID_FILE:-}"
load_secret_if_set "OIDC_CLIENT_SECRET" "${OIDC_CLIENT_SECRET_FILE:-}"
load_secret_if_set "OIDC_SIGNING_KEY" "${OIDC_SIGNING_KEY_FILE:-}"

exec "${ENTRYPOINT}" "$@"
