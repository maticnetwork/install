#!/bin/bash

{ # Prevent execution if this script was only partially downloaded
set -e

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

version="0.1.3"
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
    if [ "$2" = "mainnet" ] || [ "$2" = "amoy" ]; then
        network="$2"
    else
        echo "Invalid network: $2, choose from 'mainnet' or 'amoy'"
        exit 1
    fi
fi

if [ ! -z "$3" ]; then
    if [ "$3" = "sentry" ] || [ "$3" = "validator" ]; then
        nodetype="$3"
    elif [ "$3" = "archive" ]; then
        echo "No option of archive node type in heimdall. Using default mode: $nodetype"
    elif [ "$3" = "bootnode" ]; then
        echo "No option of bootnode type in heimdall. Using default mode: $nodetype"
    else
        echo "Invalid node type: $3, choose from 'sentry' or 'validator'"
        exit 1
    fi
fi

tag=${version}
profileInfo=${network}-${nodetype}-config_v${version}
profileInforpm=${network}-${nodetype}-config-v${version}

baseUrl="https://github.com/maticnetwork/heimdall/releases/download/v${version}"

echo $baseUrl

case "$(uname -s).$(uname -m)" in
    Linux.x86_64)
        if command -v dpkg &> /dev/null; then
            type="deb"
            binary="heimdall-v${tag}-amd64.deb"
            profile="heimdall-${profileInfo}-all.deb"
        elif command -v rpm &> /dev/null; then
            type="rpm"
              binary="heimdall-v${tag}.x86_64.rpm"
              profile="heimdall-${profileInforpm}.noarch.rpm"
        elif command -v apk &> /dev/null; then
            oops "sorry, there is no binary distribution for your platform"
        else
            oops "sorry, there is no binary distribution for your platform"
        fi
        ;;
    Linux.aarch64)
        if command -v dpkg &> /dev/null; then
            type="deb"
            binary="heimdall-v${tag}-arm64.deb"
            profile="heimdall-${profileInfo}-all.deb"
        elif command -v rpm &> /dev/null; then
            type="rpm"
            binary="heimdall-v${tag}.aarch64.rpm"
            profile="heimdall-${profileInforpm}.noarch.rpm"
        elif command -v apk &> /dev/null; then
            oops "sorry, there is no binary distribution for your platform"
        else
            oops "sorry, there is no binary distribution for your platform"
        fi
        ;;
    Darwin.x86_64)
        oops "sorry, there is no binary distribution for your platform"
        ;;
    Darwin.arm64|Darwin.aarch64)
        oops "sorry, there is no binary distribution for your platform"
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

# Check if profile is not empty
if [ ! -z "$profile"  ]; then
    profileUrl="${baseUrl}/${profile}"
    profilePackage=$tmpDir/$profile

    echo "downloading heimdall profile package for $system from '$profileUrl' to '$tmpDir'..."
    fetch "$profileUrl" "$profilePackage" || oops "failed to download '$profileUrl'"
fi

if [ $type = "tar.gz" ]; then
    require_util tar "unpack the binary package"
    unpack=$tmpDir/unpack
    mkdir -p "$unpack"
    tar -xzf "$package" -C "$unpack" || oops "failed to unpack '$package'"
    sudo cp "${unpack}/heimdalld" /usr/local/bin/heimdalld || oops "failed to copy heimdalld binary to '/usr/local/bin/heimdalld'"
elif [ $type = "deb" ]; then
    echo "Uninstalling any existing old binary ..."
    sudo dpkg -r heimdall
    sudo dpkg -r heimdalld
    echo "Installing $package ..."
    sudo dpkg -i $package
    if [ ! -z "$profilePackage" ] && sudo [ ! -d /var/lib/heimdall/config ]; then
        sudo dpkg -i $profilePackage
    fi
elif [ $type = "rpm" ]; then
    echo "Uninstalling any existing old binary ..."
    sudo rpm -e heimdall
    echo "Installing $package ..."
    sudo rpm -i --force $package
    if [ ! -z "$profilePackage" ] && sudo [ ! -d /var/lib/heimdall/config ]; then
        sudo rpm -i --force $profilePackage
    fi
elif [ $type = "apk" ]; then
    echo "Installing $package ..."
    sudo apk add --allow-untrusted $package
fi

echo "Checking heimdalld version ..."
/usr/bin/heimdalld version || oops "something went wrong"

echo "heimdall has been installed successfully!"

} # End of wrapping
