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

$libdir/build.sh $RID

echo "Deploying build"

ssh $REMOTE_USER@$REMOTE_SERVER "sudo chown -R $REMOTE_USER:$REMOTE_USER $REMOTE_PATH"
rsync -avz --delete --no-perms -e 'ssh' $dir/dist/ $REMOTE_USER@$REMOTE_SERVER:$REMOTE_PATH
ssh $REMOTE_USER@$REMOTE_SERVER "sudo chown -R www-data:www-data $REMOTE_PATH/ && sudo chmod -R 755 $REMOTE_PATH/"

echo "Restarting application"

ssh $REMOTE_USER@$REMOTE_SERVER "sudo service $REMOTE_SERVICE restart"
