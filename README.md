# Home Server Infrastructure

```bash
# Backup /dockerData and Apache2 Configs First
# Install Ubuntu Server, Import SSH Keys
# Login with user created during install
sudo su -
cd ~
cp /home/user/.ssh/authorized_keys /root/.ssh
git clone https://github.com/micaharies/infrastructure.git
cd infrastructure
bash install.sh
# Unzip backup'd resources to where they need to be (dockerData, Apache2 Configs)
cd ~/infrastructure/resources
nano docker-compose.yml # Edit all the "Change This" sections
docker compose up -d #! Do Manual Steps 1-3 before this
rm -rf infrastructure/
```

## Manual Steps:
### 1. Mount Drives
```bash
lsblk
# Find Drive(s) to mount
blkid | grep "/dev/driveHere" # Look for "UUID="
nano /etc/fstab # Add "UUID=uuidHereFromBefore /mnt/easystore ext4 defaults 0 0" to the end of the file
mkdir /mnt/easystore # Repeat for other drives
mount -a
```
### 2. Certbot w/ Certs
```bash
# Comment out certs from /etc/apache2/sites-available/000-default.conf
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
sudo certbot certonly --apache # Do each cert individually
# Uncomment certs from /etc/apache2/sites-available/000-default.conf
sudo systemctl restart apache2
```
### 3. Folder Permissions
1. Look in [docker-compose.yml](https://github.com/micaharies/infrastructure/blob/main/resources/docker-compose.yml)
2. Search for `PGID`
3. `chown -R user:media /dockerData/containerName`
### 4. Fix Containers
1. Open Portainer
2. Look for any container that doesn't have a IP/Published Port that is expecting one
3. Fix Them
### 5. Deploy Nextcloud
```bash
# Backup Nextcloud Data
rm -rf /mnt/easystore/nc_backup_files
mkdir /mnt/easystore/nc_backup_files
mv /mnt/easystore/nextcloud/admin/files/* /mnt/easystore/nc_backup_files/
rm -rf /mnt/easystore/nextcloud # Clean out existing Nextcloud (for reinstall)
sudo docker run -d \
--init \
--sig-proxy=false \
--name nextcloud-aio-mastercontainer \
--restart always \
--publish 11001:8080 \
--volume nextcloud_aio_mastercontainer:/mnt/docker-aio-config \
--volume /var/run/docker.sock:/var/run/docker.sock:ro \
-e APACHE_PORT=11000 \
-e DISABLE_BACKUP_SECTION=true \
-e NEXTCLOUD_ADDITIONAL_APKS=imagemagick \
-e NEXTCLOUD_ADDITIONAL_PHP_EXTENSIONS=imagick \
-e NEXTCLOUD_ENABLE_DRI_DEVICE=true \
-e NEXTCLOUD_DATADIR=/mnt/easystore/nextcloud \
nextcloud/all-in-one:latest
```
1. Open Nextcloud AIO
2. Copy down password
3. Login
4. Disable Talk
5. Set Timezone
6. Start Containers
7. Use Nextcloud Web UI to delete all the default files
```bash
# Restore Nextcloud Data
mv /mnt/easystore/nc_backup_files/* /mnt/easystore/nextcloud/admin/files/
chown -R www-data:www-data /mnt/easystore/nextcloud/admin/files/
sudo docker exec --user www-data -it nextcloud-aio-nextcloud php occ files:scan --all
rm -rf /mnt/easystore/nc_backup_files
```
### 6. Deploy Immich
```bash
cd /dockerData/immich
docker compose up -d
```
[Waiting on this PR to import existing library.](https://github.com/immich-app/immich/pull/3124)
