#!/bin/bash

{ # Prevent execution if this script was only partially downloaded

oops() {
    echo "$0:" "$@" >&2
    exit 1
}

umask 0022

tmpDir="$(mktemp -d -t bor-temp-dir-XXXXXXXXXXX || \
          oops "Can't create temporary directory for downloading files")"
cleanup() {
    rm -rf "$tmpDir"
}
trap cleanup EXIT INT QUIT TERM

require_util() {
    command -v "$1" > /dev/null 2>&1 ||
        oops "you do not have '$1' installed, which I need to $2"
}

version="0.2.17"
network="mainnet"
nodetype="sentry"


# Help function -h
helpFunction()
{
    echo ""
    echo "Usage: $0 [version [network [nodetype]]]"
    echo -e "\tversion: Version of Heimdall to install. Default: $version"
    echo -e "\tnetwork: Network to install. Default: $network"
    echo -e "\tnodetype: Type of node configuration to install. Default: $nodetype"
    exit 1 # Exit script after printing help
}

while getopts ":h" option; do
   case $option in
      h) # display Help
         helpFunction
         exit;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

if [ ! -z "$1" ]; then
    version="$1"
    if [ "${version:0:1}" = "v" ]; then
        version=${version:1}
    fi
fi

if [ ! -z "$2" ]; then
    if [ "$2" = "mainnet" ] || [ "$2" = "mumbai" ]; then
        network="$2"
    else
        echo "Invalid network: $2, choose from 'mainnet' or 'mumbai'"
        exit 1
    fi
fi

if [ ! -z "$3" ]; then
    if [ "$3" = "sentry" ] || [ "$3" = "validator" ]; then
        nodetype="$3"
    else
        echo "Invalid node type: $3, choose from 'sentry' or 'validator'"
        exit 1
    fi
fi

if [[ $version > "0.3" ]]; then
    tag=${version}_${network}_${nodetype}
else
    echo "Version is less than 0.3, ignoring network and node type"
    tag=${version}
fi

baseUrl="https://github.com/maticnetwork/bor/releases/download/v${version}"

echo $baseUrl

case "$(uname -s).$(uname -m)" in
    Linux.x86_64)
        if command -v dpkg &> /dev/null; then
            type="deb"
            binary="bor_${tag}_linux_amd64.deb"
        elif command -v rpm &> /dev/null; then
            type="rpm"
            binary="bor_${tag}_linux_x86_64.rpm"
        elif command -v apk &> /dev/null; then
            type="apk"
            binary="bor_${tag}_linux_amd64.apk"
        else
            type="tar.gz"
            binary="bor_${tag}_linux_amd64.tar.gz"
        fi
        ;;
    Linux.aarch64)
        if command -v dpkg &> /dev/null; then
            type="deb"
            binary="bor_${tag}_linux_arm64.deb"
        elif command -v rpm &> /dev/null; then
            type="rpm"
            binary="bor_${tag}_linux_arm64.rpm"
        elif command -v apk &> /dev/null; then
            type="apk"
            binary="bor_${tag}_linux_arm64.apk"
        else
            type="tar.gz"
            binary="bor_${tag}_linux_arm64.tar.gz"
        fi
        ;;
    Darwin.x86_64)
        type="tar.gz"
        binary="bor_${version}_darwin_amd64.tar.gz"
        ;;
    Darwin.arm64|Darwin.aarch64)
        type="tar.gz"
        binary="bor_${version}_darwin_arm64.tar.gz"
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

echo "downloading bor binary package for $system from '$url' to '$tmpDir'..."
fetch "$url" "$package" || oops "failed to download '$url'"

if [ $type = "tar.gz" ]; then
    require_util tar "unpack the binary package"
    unpack=$tmpDir/unpack
    mkdir -p "$unpack"
    tar -xzf "$package" -C "$unpack" || oops "failed to unpack '$package'"
    sudo cp "${unpack}/bor" /usr/local/bin/bor || oops "failed to copy bor binary to '/usr/local/bin/bor'"
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

echo "Checking bor version ..."
bor version || oops "something went wrong"
echo "bor has been installed successfully!"

} # End of wrapping