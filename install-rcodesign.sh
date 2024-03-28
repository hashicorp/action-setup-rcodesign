#!/usr/bin/env bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# This script handles installing rcodesign which is an open source tool to sign macOS binaries.
set -euo pipefail

# override for testing
: "${DEST_DIR:="$(/bin/pwd -P)/.bob/tools"}"
: "${VERSION:=0.22.0}"
# defaults for local testing
: "${RUNNER_TEMP:=/tmp}"
: "${GITHUB_PATH:=${RUNNER_TEMP}/GITHUB_PATH}"

declare -a cksum_command=( )

arch=x86_64
os=linux
case "$(uname -m)" in
    x86_64) ;;
    amd64) arch=x86_64 ;;
    *) echo "$(uname -m): unsupported machine architecture" 1>&2 ; exit 1 ;;
esac
case "$(uname -s)" in
    Darwin)
        # only used for selecting rcodesign release artifact
        os=apple-darwin
        cksum_command=( 'shasum' '-a' '256' )
        ;;
    Linux)
        # only used for selecting rcodesign release artifact
        os=unknown-linux-musl
        cksum_command=( 'sha256sum' )
        ;;
    *) echo "$(uname -s): unsupported operating system" 1>&2 ; exit 1 ;;
esac
echo "==> installing rcodesign for arch=${arch} and os=${os}"

readonly release="apple-codesign-${VERSION}-${arch}-${os}"
readonly tag="apple-codesign/$VERSION"
readonly asset="${release}.tar.gz"
readonly sums_name="SHA256SUMS"

cd "$RUNNER_TEMP"
echo "Fetching release artifact: $release"

# can add --clobber for convenience in local testing
gh release download --repo=github.com/indygreg/apple-platform-rs "$tag" --pattern "$asset"
gh release download --repo=github.com/indygreg/apple-platform-rs "$tag" --pattern "$sums_name"
checksums="$(grep " $asset\$" "$sums_name")" || :
if [ -z "$checksums" ]; then
    echo "$sums_name: no checksum found for asset $asset" 1>&2
    exit 1
fi

"${cksum_command[@]}" --quiet --strict --check <<<"$checksums"

mkdir -p "$DEST_DIR"
tar --extract \
    --directory "$DEST_DIR" \
    --strip-components 1 \
    --file "$asset" \
    "${release}"/rcodesign

## Add to path if not already present
if [[ ":$PATH:" != *":${DEST_DIR}:"* ]] ; then
    echo "Adding [$DEST_DIR] to PATH"
    echo "$DEST_DIR" >> "$GITHUB_PATH"
fi
