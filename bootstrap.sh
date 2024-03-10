#!/bin/bash

# Bootstrap Swift environment for Playground

function program_is_installed {
  # set to 1 initially
  local return_=1
  # set to 0 if not found
  type $1 >/dev/null 2>&1 || { local return_=0; }
  # return value
  echo "$return_"
}

function install_toolchain {
    SWIFT_VERSION=$1
    BRANCH=$2
    RELEASE=$3
    SWIFT_TARGET=$4
    LINUX_DISTRO=$5
    if [ ! -d "Toolchains/swift-$SWIFT_VERSION-$RELEASE.xctoolchain" ]; then
        case "$SWIFT_TARGET" in
        *osx)
            mkdir -p Toolchains/swift-$SWIFT_VERSION-$RELEASE.xctoolchain
            # download
            curl -LO https://swift.org/builds/swift-$SWIFT_VERSION-$BRANCH/xcode/swift-$SWIFT_VERSION-$RELEASE/swift-$SWIFT_VERSION-$RELEASE-$SWIFT_TARGET.pkg
            # extract
            xar -xf swift-$SWIFT_VERSION-$RELEASE-$SWIFT_TARGET.pkg -C Toolchains/
            tar -xzf Toolchains/swift-$SWIFT_VERSION-$RELEASE-$SWIFT_TARGET-package.pkg/Payload -C Toolchains/swift-$SWIFT_VERSION-$RELEASE.xctoolchain
            # cleanup
            rm Toolchains/Distribution
            rm -r Toolchains/swift-$SWIFT_VERSION-$RELEASE-$SWIFT_TARGET-package.pkg
            rm -r swift-$SWIFT_VERSION-$RELEASE-$SWIFT_TARGET.pkg
            ;;
        ubuntu*)
            # select toolchain binary based on cpu architecture
            if [[ $(arch) = aarch* ]]; then ARCH=-$(arch); fi

            mkdir -p Toolchains/swift-$SWIFT_VERSION-$RELEASE.xctoolchain
            # download
            curl -LO https://download.swift.org/swift-$SWIFT_VERSION-$BRANCH/$LINUX_DISTRO$ARCH/swift-$SWIFT_VERSION-$RELEASE/swift-$SWIFT_VERSION-$RELEASE-$SWIFT_TARGET$ARCH.tar.gz
            # extract
            tar -xvzf swift-$SWIFT_VERSION-$RELEASE-$SWIFT_TARGET$ARCH.tar.gz -C Toolchains/swift-$SWIFT_VERSION-$RELEASE.xctoolchain --strip-components=1
            # # cleanup
            rm -rf swift-$SWIFT_VERSION-$RELEASE-$SWIFT_TARGET$ARCH.tar.gz
            ;;
        esac
    fi
}

function build_onlineplayground {
    RELEASE=$2
    SWIFT_VERSION="$1-$RELEASE"

    ONLINE_PLAYGROUND_DIR="OnlinePlayground/OnlinePlayground-$SWIFT_VERSION"
    Toolchains/swift-$SWIFT_VERSION.xctoolchain/usr/bin/swift build --package-path $ONLINE_PLAYGROUND_DIR --static-swift-stdlib --scratch-path $ONLINE_PLAYGROUND_DIR/.build -c release
    Toolchains/swift-$SWIFT_VERSION.xctoolchain/usr/bin/swift build --package-path $ONLINE_PLAYGROUND_DIR --static-swift-stdlib --scratch-path $ONLINE_PLAYGROUND_DIR/.build -c debug -Xswiftc -DDEBUG -Xswiftc -Xfrontend -Xswiftc -validate-tbd-against-ir=none
}

npm install -y
npx webpack

if [ $(program_is_installed xcrun) == 1 ]; then
    # Install Toolchains
    install_toolchain "5.7" "release" "RELEASE" "osx"
else
    # Install Toolchains
    install_toolchain "5.7" "release" "RELEASE" "ubuntu22.04" "ubuntu2204"
fi

# Build OnlinePlayground
build_onlineplayground "5.7" "RELEASE"
