# app

Private repository for bootstrapping demos

## Run bits locally

### Windows

Create an empty directory and `cd` into it:

```cmd
rem download and extract
@"powershell" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = 'tls12, tls11, tls'; $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri https://github.com/mattjcowan/app/releases/latest/download/app-win-x64.zip -OutFile app-win-x64.zip"
@"powershell" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "Unblock-File -Path app-win-x64.zip"
@"powershell" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "$global:ProgressPreference = 'SilentlyContinue'; Expand-Archive -Force -Path app-win-x64.zip -DestinationPath .\\"

rem run the app
.\app.exe
```

### MacOS

Create an empty directory and `cd` into it:

```shell
# download and extract
wget -q https://github.com/mattjcowan/app/releases/latest/download/app-osx-x64.tar.gz
tar -zxvf app-osx-x64.tar.gz

# run the app
$ chmod +x app && ./app
```

### Linux

Create an empty directory and `cd` into it:

```shell
# download and extract
wget -q https://github.com/mattjcowan/app/releases/latest/download/app-linux-x64.tar.gz
tar -zxvf app-linux-x64.tar.gz

# run the app
$ chmod +x app && ./app
```

## Setup (Remote Server)

`ssh` to a vanilla `Ubuntu (16|18).04` vm:

```bash
wget -q https://raw.githubusercontent.com/mattjcowan/app/master/lib/setup-server.sh
chmod +x ./setup-server.sh
./setup-server.sh
```

Your app is now available at https://{server_ip}/

## Development

### Bootstrap a new app

You've cloned this repo and want to use it as the basis for your own app:

```bash
chmod +x ./lib/init-local.sh
./lib/init-local.sh
```

### Releases

Create a release by pushing changes, tagging the repo and uploading the latest archives to GitHub:

```bash
chmod +x ./lib/release.sh
./lib/release.sh
```

### Deploying updates

To re-deploy or deploy a new version of the app to the server:

```bash
chmod +x ./lib/deploy.sh
./lib/deploy.sh
```