#!/usr/bin/env bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# This script handles installing rcodesign which is an open source tool to sign macOS binaries.
set -euo pipefail

# override for testing
: "${DEST_DIR:=${PWD}/.bob/tools}"
: "${VERSION:=0.22.0}"
# defaults for local testing
: "${RUNNER_TEMP:=/tmp}"
: "${GITHUB_PATH:=${RUNNER_TEMP}/GITHUB_PATH}"

readonly release="apple-codesign-${VERSION}-x86_64-unknown-linux-musl" 
/usr/bin/env | sort
readonly tag="apple-codesign/$VERSION"
readonly asset="${release}.tar.gz"
readonly sums_name="SHA256SUMS"

cd "$RUNNER_TEMP"

# can add --clobber for convenience in local testing
gh release download --repo=github.com/indygreg/apple-platform-rs "$tag" --pattern "$asset"
gh release download --repo=github.com/indygreg/apple-platform-rs "$tag" --pattern "$sums_name"
checksums="$(grep " $asset\$" "$sums_name")" || :
if [ -z "$checksums" ]; then
    echo "$sums_name: no checksum found for asset $asset" 1>&2
    exit 1
fi
sha256sum --quiet --strict --check <<<"$checksums"

mkdir -p "$DEST_DIR"
tar --extract \
    --directory "$DEST_DIR" \
    --strip-components 1 \
    --file "$asset" \
    "${release}"/rcodesign

## Add to path if not already present
if [[ ":$PATH:" != *":${DEST_DIR}:"* ]] ; then
    echo "$DEST_DIR" >> "$GITHUB_PATH"
fi

echo "$GITHUB_PATH"