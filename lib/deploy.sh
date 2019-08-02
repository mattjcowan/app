#!/usr/bin/env bash
libdir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $libdir/..
dir=$(pwd)

cd $libdir
source env.sh

$libdir/build.sh $RID

ssh $REMOTE_USER@$REMOTE_SERVER "sudo chown -R $REMOTE_USER:$REMOTE_USER $REMOTE_PATH"
rsync -avz --delete --no-perms -e 'ssh' $dir/dist/ $REMOTE_USER@$REMOTE_SERVER:$REMOTE_PATH
ssh $REMOTE_USER@$REMOTE_SERVER "sudo chown -R www-data:www-data $REMOTE_PATH/ && sudo chmod -R 755 $REMOTE_PATH/"
ssh $REMOTE_USER@$REMOTE_SERVER "sudo service $REMOTE_SERVER restart"
