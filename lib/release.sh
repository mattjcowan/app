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

echo Creating release v$VERSION

# create release on GitHub
API_JSON=$(printf '{"tag_name": "v%s","target_commitish": "master","name": "v%s","body": "Release of version %s","draft": false,"prerelease": false}' $VERSION $VERSION $VERSION)
curl --data "$API_JSON" "https://api.github.com/repos/$GITHUB_REPOSITORY/releases?access_token=$GITHUB_ACCESSTOKEN"

# get release id
RELEASE_JSON=$(curl  -s -H 'Accept: application/json' https://api.github.com/repos/$GITHUB_REPOSITORY/releases/tags/v$VERSION)
eval $(echo "$RELEASE_JSON" | grep -m 1 "id.:" | grep -w id | tr : = | tr -cd '[[:alnum:]]=')
[ "$id" ] || { echo "Error: Failed to get release id for tag: v$VERSION"; echo "$RELEASE_JSON" | awk 'length($0)<100' >&2; exit 1; }
RELEASE_ID=$id

# build and create release archives
GITHUB_OAUTH_BASIC=$(printf %s:x-oauth-basic $GITHUB_ACCESSTOKEN)

declare -a winOS=("win-x64")
declare -a unixOS=("osx-x64" "linux-x64" "ubuntu-x64")

for rid in "${winOS[@]}"
do
    cd $libdir && ./build.sh $rid
    cd $dir/dist && zip -r $dir/releases/app-$rid.zip .

    curl -X POST \
        --user "${GITHUB_OAUTH_BASIC}" \
        --upload-file "$dir/releases/app-$rid.zip" \
        -H "Authorization: token ${GITHUB_ACCESSTOKEN}" \
        -H "Content-Type: application/octet-stream" \
        "https://uploads.github.com/repos/${GITHUB_REPOSITORY}/releases/$RELEASE_ID/assets?name=app-$rid.zip"
done

for rid in "${unixOS[@]}"
do
    cd $libdir && ./build.sh $rid
    cd $dir/dist && tar -cvzf $dir/releases/app-$rid.tar.gz .

    curl -X POST \
        --user "${GITHUB_OAUTH_BASIC}" \
        --upload-file "$dir/releases/app-$rid.tar.gz" \
        -H "Authorization: token ${GITHUB_ACCESSTOKEN}" \
        -H "Content-Type: application/octet-stream" \
        "https://uploads.github.com/repos/${GITHUB_REPOSITORY}/releases/$RELEASE_ID/assets?name=app-$rid.tar.gz"
done

rm -Rf $dir/dist    