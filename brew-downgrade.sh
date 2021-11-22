#!/usr/bin/env bash

##
##  Downgrade brew package
##
##  Created by Hiroki Ishiura on 2021/11/22.
##  Copyright (c) 2021 Hiroki Ishiura. All rights reserved.
##
##  Released under the MIT license
##  http://opensource.org/licenses/mit-license.php
##

usage_exit() {
    echo "Usage: $0 [-c] [-d HASH| -l] package" 1>&2
    echo "Options:"
    echo "    -c ........ Use cask"
    echo "    -d HASH ... Downgrade to HASH"
    echo "    -l ........ List hash (Default mode)"
    echo "    -h ........ Show usage"
    exit 1
}

# Parse command line option
OPT_USE_CASK=0
OPT_DOWN_HASH=
while getopts cd:lh OPT
do
    case $OPT in
    c)  OPT_USE_CASK=1
        ;;
    d)  OPT_DOWN_HASH=$OPTARG
        ;;
    l)  OPT_DOWN_HASH=
        ;;
    h) usage_exit
        ;;
    esac
done
shift $((OPTIND - 1))
if [ $# -eq 0 ]; then
    usage_exit
fi

# Determine the file
if [ $OPT_USE_CASK -eq 0 ]; then
    USE_CASK=
    REPO_DIR=`brew --prefix`/Homebrew/Library/Taps/homebrew/homebrew-core/Formula/
else
    USE_CASK="--cask"
    REPO_DIR=`brew --prefix`/Homebrew/Library/Taps/homebrew/homebrew-cask/Casks/
fi
if [ ! -d $REPO_DIR ]; then
    echo "Not found $REPO_DIR." 1>&2
    exit 1
fi
cd $REPO_DIR
PACKAGE=$1.rb
if [ ! -f $PACKAGE ]; then
    echo "Not found $1. Try -c option." 1>&2
    exit 1
fi

# Execute action
brew update
if [ -z "$OPT_DOWN_HASH" ]; then
    # List hash
    git log -5 --oneline $PACKAGE

else
    # Uninstall, Downgrade, Install again
    echo "Uninstall ..."
    brew uninstall $1
    echo "Downgrade to $OPT_DOWN_HASH ..."
    git checkout $OPT_DOWN_HASH $PACKAGE >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Not found $OPT_DOWN_HASH." 1>&2
        exit 1
    fi
    echo "Install ..."
    brew install $USE_CASK $1

    # Recover to HEAD for `brew upgrade`
    git reset $PACKAGE >/dev/null 2>&1
    git checkout $PACKAGE >/dev/null 2>&1

fi
exit 0
