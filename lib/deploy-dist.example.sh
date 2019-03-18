#!/usr/bin/env bash
dir=$(pwd)
cdir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# deploy variables
local_path=$cdir/../dist
remote_user=root
remote_server=demoserver
remote_service=app
remote_path=/var/www/app/dist

# publish local dist directory to remote server
local_path=$cdir/../dist
ssh $remote_user@$remote_server "sudo chown -R $remote_user:$remote_user $remote_path"
rsync -avz --delete --no-perms -e 'ssh' $local_path/ $remote_user@$remote_server:$remote_path
ssh $remote_user@$remote_server "sudo chown -R www-data:www-data $remote_path/ && sudo chmod -R 755 $remote_path/"
ssh $remote_user@$remote_server "sudo service $remote_service restart"