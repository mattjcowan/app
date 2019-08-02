#!/usr/bin/env bash
libdir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $libdir
cd ..
dir=$(pwd)

cd $libdir
source env.sh

rm -Rf $dir/releases
mkdir -p $dir/releases

# bump version
CURRENT_VERSION=$(grep '<Version>' < "$dir/src/app/app.csproj" | sed 's/.*<Version>\(.*\)<\/Version>/\1/')
if [ "$CURRENT_VERSION" = "" ]
then 
    CURRENT_VERSION=1.0.0
    sed -i '' 's|</TargetFramework>|</TargetFramework><Version>1.0.0</Version>|g' $dir/src/app/app.csproj
fi

if [[ $(dotnet tool list -g) != *"dotnet-version-cli"* ]]; then dotnet tool install -g dotnet-version-cli; fi
dotnet version -f "$dir/src/app/app.csproj" patch
VERSION=$(grep '<Version>' < "$dir/src/app/app.csproj" | sed 's/.*<Version>\(.*\)<\/Version>/\1/')

if [ "$CURRENT_VERSION" = "$VERSION" ]; then exit 1; fi

git add .
git commit -m "Release of version $VERSION"
git push
git tag -a v$VERSION -m "Release of version v$VERSION"
git push --tags

# create release on GitHub
API_JSON=$(printf '{"tag_name": "v%s","target_commitish": "master","name": "v%s","body": "Release of version %s","draft": false,"prerelease": false}' $VERSION $VERSION $VERSION)
curl --data "$API_JSON" "https://api.github.com/repos/$GITHUB_REPOSITORY/releases?access_token=$GITHUB_ACCESSTOKEN"

# build and create release archives
declare -a winOS=("win-x64")
declare -a unixOS=("osx-x64" "linux-x64" "ubuntu-x64")

for rid in "${winOS[@]}"
do
    cd $libdir
    ./build.sh $rid
    cd $dir/dist
	zip -r $dir/releases/app-$rid.zip .
    rm -Rf $dir/dist    

    curl -X POST https://uploads.github.com/repos/${GITHUB_REPOSITORY}/releases/v${VERSION}/assets?access_token=${GITHUB_ACCESSTOKEN}&name=app-${rid}.zip\
        --header 'Content-Type: text/javascript ' --upload-file ${dir}/releases/app-${rid}.zip
done

for rid in "${unixOS[@]}"
do
    cd $libdir
    ./build.sh $rid
    cd $dir/dist
	tar -cvzf $dir/releases/app-$rid.tar.gz .
    rm -Rf $dir/dist

    curl -X POST https://uploads.github.com/repos/${GITHUB_REPOSITORY}/releases/v${VERSION}/assets?access_token=${GITHUB_ACCESSTOKEN}&name=app-${rid}.tar.gz\
        --header 'Content-Type: text/javascript ' --upload-file ${dir}/releases/app-${rid}.tar.gz
done
