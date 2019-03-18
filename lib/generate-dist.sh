#!/usr/bin/env bash
libdir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $libdir
cd ..

dir=$(pwd)
timestamp=`date '+%Y%m%d%H%M%S'`

# (re-)create src
if [ ! -d "$dir/src" ]; then
    mkdir -p $dir/src
    cd $dir/src
    dotnet new web -n app
    cd $dir/src/app

    sed -i "" "s/Hello World!/app (timestamp: ${timestamp})/g" Startup.cs
fi


# (re-)create dist
if [ -d "$dir/dist" ]; then rm -Rf $dir/dist; fi
cd $dir/src/app
dotnet publish -c release -r ubuntu.16.04-x64 -o $dir/dist
chmod +x $dir/dist/app
cd $dir

# clean up
rm -Rf $dir/src