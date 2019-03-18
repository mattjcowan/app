# app

Private repository for bootstrapping demos

## Setup

ssh to a vanilla `Ubuntu 16.04` vm:

```bash
sudo apt-get install git -y
mkdir -p /tmp/repos
cd /tmp/repos
git clone -b master https://github.com/mattjcowan/app.git
./app/lib/setup-server.sh
```

Your app is now available at https://{server_ip}/

## Deploying

To re-deploy or deploy a new app, you can do the following:

```bash
# `cd` to the root of your repo
dir=$(pwd)

# set some variables
local_src=$dir/src/app              # assumes app is at this location
local_path=$dir/dist                # local deployment location
remote_server=44.44.44.44           # remote server ip
remote_user=root                    # remote user
remote_service=app                  # name of system.d service
remote_path=/var/www/app/dist       # deployment path

# publish app locally
cd $local_src
dotnet publish -c release -r ubuntu.16.04-x64 -o $local_path
chmod +x $local_path/app

# rsync app to remote server
ssh $remote_user@$remote_server "sudo chown -R $remote_user:$remote_user $remote_path"
rsync -avz --delete --no-perms -e 'ssh' $local_path/ $remote_user@$remote_server:$remote_path
ssh $remote_user@$remote_server "sudo chown -R www-data:www-data $remote_path/ && sudo chmod -R 755 $remote_path/"
ssh $remote_user@$remote_server "sudo service $remote_service restart"
```