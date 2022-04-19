#!/bin/bash

{ # Prevent execution if this script was only partially downloaded

oops() {
    echo "$0:" "$@" >&2
    exit 1
}

umask 0022

tmpDir="$(mktemp -d -t heimdall-temp-dir-XXXXXXXXXXX || \
          oops "Can't create temporary directory for downloading files")"
cleanup() {
    rm -rf "$tmpDir"
}
trap cleanup EXIT INT QUIT TERM

require_util() {
    command -v "$1" > /dev/null 2>&1 ||
        oops "you do not have '$1' installed, which I need to $2"
}

version="0.2.9"

if [ ! -z "$1" ]; then
    version="$1"
    if [ "${version:0:1}" = "v" ]; then
        version=${version:1}
    fi
fi

baseUrl="https://github.com/maticnetwork/heimdall/releases/download/v${version}"

echo $baseUrl

case "$(uname -s).$(uname -m)" in
    Linux.x86_64)
        if command -v dpkg &> /dev/null; then
            type="deb"
            binary="heimdall_${version}_linux_amd64.deb"
        elif command -v rpm &> /dev/null; then
            type="rpm"
            binary="heimdall_${version}_linux_x86_64.rpm"
        elif command -v apk &> /dev/null; then
            type="apk"
            binary="heimdall_${version}_linux_amd64.apk"
        else
            type="tar.gz"
            binary="heimdall_${version}_linux_amd64.tar.gz"
        fi
        ;;
    Linux.aarch64)
        if command -v dpkg &> /dev/null; then
            type="deb"
            binary="heimdall_${version}_linux_arm64.deb"
        elif command -v rpm &> /dev/null; then
            type="rpm"
            binary="heimdall_${version}_linux_arm64.rpm"
        elif command -v apk &> /dev/null; then
            type="apk"
            binary="heimdall_${version}_linux_arm64.apk"
        else
            type="tar.gz"
            binary="heimdall_${version}_linux_arm64.tar.gz"
        fi
        ;;
    Darwin.x86_64)
        type="tar.gz"
        binary="heimdall_${version}_darwin_amd64.tar.gz"
        ;;
    Darwin.arm64|Darwin.aarch64)
        type="tar.gz"
        binary="heimdall_${version}_darwin_arm64.tar.gz"
        ;;
    *) oops "sorry, there is no binary distribution for your platform";;
esac

url="${baseUrl}/${binary}"

package=$tmpDir/$binary

if command -v curl > /dev/null 2>&1; then
    fetch() { curl -L "$1" -o "$2"; }
elif command -v wget > /dev/null 2>&1; then
    fetch() { wget "$1" -O "$2"; }
else
    oops "you don't have wget or curl installed, which I need to download the binary package"
fi

echo "downloading heimdall binary package for $system from '$url' to '$tmpDir'..."
fetch "$url" "$package" || oops "failed to download '$url'"

if [ $type = "tar.gz" ]; then
    require_util tar "unpack the binary package"
    unpack=$tmpDir/unpack
    mkdir -p "$unpack"
    tar -xzf "$package" -C "$unpack" || oops "failed to unpack '$package'"
    sudo cp "${unpack}/heimdalld" /usr/local/bin/heimdalld || oops "failed to copy heimdalld binary to '/usr/local/bin/heimdalld'"
    sudo cp "${unpack}/heimdallcli" /usr/local/bin/heimdallcli || oops "failed to copy heimdallcli binary to '/usr/local/bin/heimdallcli'"
    sudo cp "${unpack}/bridge" /usr/local/bin/bridge || oops "failed to copy bridge binary to '/usr/local/bin/bridge'"
elif [ $type = "deb" ]; then
    echo "Installing $package ..."
    sudo dpkg -i $package
elif [ $type = "rpm" ]; then
    echo "Installing $package ..."
    sudo rpm -i --force $package
elif [ $type = "apk" ]; then
    echo "Installing $package ..."
    sudo apk add --allow-untrusted $package
fi

echo "Checking heimdalld version ..."
heimdalld version || oops "something went wrong"
echo "Checking heimdallcli version ..."
heimdallcli version || oops "something went wrong"
echo "Checking bridge version ..."
bridge version || oops "something went wrong"
echo "heimdall has been installed successfully!"

} # End of wrapping