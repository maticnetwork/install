## Installation scripts

Utility scripts that install binaries based on the operating system. The script will ask the user for root permission as required by installation.

### Setup

Clone this git repository

```
git clone https://github.com/maticnetwork/install.git
cd install
```

### Bor

#### Install default bor binary

```
./bor.sh
```

#### Install a specific bor version

Simply pass the version tag as the first argument to the installation script. Notice that the script will overwrite existing bor binaries if they exist. Example:

```
./bor.sh 0.2.14-tmp-span-hotfix
```

#### Installing PBSS profiles
```shell
./bor.sh $version $network pbss-$network-$type
```
Where $version is desired version, $network is mainnet or amoy, and $type is defined as sentry or validator as PBSS does not support bootnode or archive.


### Heimdall-v2

#### Install default Heimdall-v2 binary

```
./heimdall-v2.sh
```

#### Install a specific Heimdall-v2 version

Simply pass the version tag as the first argument to the installation script. Notice that the script will overwrite existing Heimdall-v2 binaries if they exist. Example:

```
./heimdall-v2.sh 0.1.6
```
