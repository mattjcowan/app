#!/usr/bin/env bash
libdir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $libdir
cd ..
dir=$(pwd)

cd $libdir
source env.sh

if [ $# -eq 0 ]; then
    rid=ubuntu-x64 # you can be more specific (ubuntu.16.04-x64, ubuntu.18.04-x64), or less specific (linux-x64)
else
    rid=$1
fi

# (re-)create dist
if [ -d "$dir/dist" ]; then rm -Rf $dir/dist; fi
cd $dir/src/app
dotnet publish -c release --self-contained -r $rid -o $dir/dist
chmod +x $dir/dist/app
cd $dir
