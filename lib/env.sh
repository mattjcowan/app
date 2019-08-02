envdir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
envf=$envdir/.env

if [ -f "$envf" ]; then source "$envf"; fi

if [ "$GITHUB_REPOSITORY" = "" ];
then 
    echo -n "Enter your GitHub repository name (eg: mattjcowan/app) and press [ENTER]: "
    read GITHUB_REPOSITORY
    if [ "$GITHUB_REPOSITORY" = "" ]; then exit 1; fi
    echo "GITHUB_REPOSITORY=$GITHUB_REPOSITORY" >> "$envf"
fi

if [ "$GITHUB_ACCESSTOKEN" = "" ];
then 
    if [ -f '~/.ghtoken' ]; then GITHUB_ACCESSTOKEN=`cat ~/.ghtoken`; fi
fi

if [ "$GITHUB_ACCESSTOKEN" = "" ];
then 
    echo -n "Enter your GitHub access token and press [ENTER]: "
    read GITHUB_ACCESSTOKEN
    if [ "$GITHUB_ACCESSTOKEN" = "" ]; then exit 1; fi
    echo "GITHUB_ACCESSTOKEN=$GITHUB_ACCESSTOKEN" >> "$envf"
fi

if [ "$RID" = "" ];
then 
    echo -n "Enter your remote server runtime id (default: ubuntu-x64) and press [ENTER]: "
    read RID
    if [ "$RID" = "" ]; then RID=ubuntu-x64; fi
    echo "RID=$RID" >> "$envf"
fi

if [ "$REMOTE_SERVICE" = "" ] 
then 
    REMOTE_SERVICE=app
    echo "REMOTE_SERVICE=$REMOTE_SERVICE" >> "$envf"
fi

if [ "$REMOTE_PATH" = "" ] 
then 
    REMOTE_PATH=/var/www/app/dist
    echo "REMOTE_PATH=$REMOTE_PATH" >> "$envf"
fi