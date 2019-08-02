#!/usr/bin/env bash
libdir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $libdir/..
dir=$(pwd)

cd $libdir
source env.sh

envf=$libdir/.env

if [ "$REMOTE_SERVER" = "" ];
then 
    echo -n "Enter your remote server host name or IP and press [ENTER]: "
    read REMOTE_SERVER
    if [ "$REMOTE_SERVER" = "" ]; then exit 1; fi
    echo "REMOTE_SERVER=$REMOTE_SERVER" >> "$envf"
fi

if [ "$REMOTE_USER" = "" ];
then 
    echo -n "Enter your remote server sudo user (default: root) and press [ENTER]: "
    read REMOTE_USER
    if [ "$REMOTE_USER" = "" ]; then REMOTE_USER=root; fi
    echo "REMOTE_USER=$REMOTE_USER" >> "$envf"
fi

if [ "$DEPLOY_ARCHIVE_URL" = "" ]
then 
    echo -n "Enter the release you wish to deploy (eg: v1.0.4, default: latest) and press [ENTER]: "
    read RELEASE_TAG
    if [ "$RELEASE_TAG" = "" ]; then RELEASE_TAG=latest; fi
    if [ "$RELEASE_TAG" = "latest" ]; then 
        DEPLOY_ARCHIVE_URL="https://github.com/mattjcowan/app/releases/latest/download/app-$RID.tar.gz"
    else
        DEPLOY_ARCHIVE_URL="https://github.com/mattjcowan/app/releases/download/${RELEASE_TAG}/app-$RID.tar.gz"
    fi
fi

if [ "$DEPLOY_ARCHIVE_FILE" = "" ]; then DEPLOY_ARCHIVE_FILE=app-$RID.tar.gz; fi

echo "Fetching archive from: ${DEPLOY_ARCHIVE_URL}"

ssh $REMOTE_USER@$REMOTE_SERVER "sudo chown -R $REMOTE_USER:$REMOTE_USER $REMOTE_PATH"
ssh $REMOTE_USER@$REMOTE_SERVER "cd $REMOTE_PATH && sudo wget -q $DEPLOY_ARCHIVE_URL && sudo tar -zxf $DEPLOY_ARCHIVE_FILE && sudo chmod +x app && sudo rm $DEPLOY_ARCHIVE_FILE"
ssh $REMOTE_USER@$REMOTE_SERVER "sudo chown -R www-data:www-data $REMOTE_PATH/ && sudo chmod -R 755 $REMOTE_PATH/"

echo "Restarting application"

ssh $REMOTE_USER@$REMOTE_SERVER "sudo service $REMOTE_SERVICE restart"
