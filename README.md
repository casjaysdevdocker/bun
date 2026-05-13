## 👋 Welcome to bun 🚀  

bun README  
  
  
## Install my system scripts  

```shell
 sudo bash -c "$(curl -q -LSsf "https://github.com/systemmgr/installer/raw/main/install.sh")"
 sudo systemmgr --config && sudo systemmgr install scripts  
```
  
## Automatic install/update  
  
```shell
dockermgr update bun
```
  
## Install and run container
  
```shell
dockerHome="/var/lib/srv/$USER/docker/casjaysdevdocker/bun/bun/latest/rootfs"
mkdir -p "/var/lib/srv/$USER/docker/bun/rootfs"
git clone "https://github.com/dockermgr/bun" "$HOME/.local/share/CasjaysDev/dockermgr/bun"
cp -Rfva "$HOME/.local/share/CasjaysDev/dockermgr/bun/rootfs/." "$dockerHome/"
docker run -d \
--restart always \
--privileged \
--name casjaysdevdocker-bun-latest \
--hostname bun \
-e TZ=${TIMEZONE:-America/New_York} \
-v "$dockerHome/data:/data:z" \
-v "$dockerHome/config:/config:z" \
-p 80:80 \
casjaysdevdocker/bun:latest
```
  
## via docker-compose  
  
```yaml
version: "2"
services:
  ProjectName:
    image: casjaysdevdocker/bun
    container_name: casjaysdevdocker-bun
    environment:
      - TZ=America/New_York
      - HOSTNAME=bun
    volumes:
      - "/var/lib/srv/$USER/docker/casjaysdevdocker/bun/bun/latest/rootfs/data:/data:z"
      - "/var/lib/srv/$USER/docker/casjaysdevdocker/bun/bun/latest/rootfs/config:/config:z"
    ports:
      - 80:80
    restart: always
```
  
## Get source files  
  
```shell
dockermgr download src casjaysdevdocker/bun
```
  
OR
  
```shell
git clone "https://github.com/casjaysdevdocker/bun" "$HOME/Projects/github/casjaysdevdocker/bun"
```
  
## Build container  
  
```shell
cd "$HOME/Projects/github/casjaysdevdocker/bun"
buildx 
```
  
## Authors  
  
🤖 casjay: [Github](https://github.com/casjay) 🤖  
⛵ casjaysdevdocker: [Github](https://github.com/casjaysdevdocker) [Docker](https://hub.docker.com/u/casjaysdevdocker) ⛵  
