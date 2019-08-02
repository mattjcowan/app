#!/usr/bin/env bash
libdir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $libdir
cd ..
dir=$(pwd)
timestamp=`date '+%Y%m%d%H%M%S'`

# create src with an empty app
if [ ! -d "$dir/src" ]; then
    mkdir -p $dir/src
    cd $dir/src
    dotnet new web -n app
    cd $dir/src/app

    sed -i "" "s/Hello World!/app (timestamp: ${timestamp})/g" Startup.cs
fi

# create Version tag
CURRENT_VERSION=$(grep '<Version>' < "$dir/src/app/app.csproj" | sed 's/.*<Version>\(.*\)<\/Version>/\1/')
if [ "$CURRENT_VERSION" = "" ]; then sed -i '' 's|</TargetFramework>|</TargetFramework><Version>1.0.0</Version>|g' $dir/src/app/app.csproj; fi

# install global tools
if [[ $(dotnet tool list -g) != *"dotnet-version-cli"* ]]; then dotnet tool install -g dotnet-version-cli; fi

cd $libdir
source env.sh