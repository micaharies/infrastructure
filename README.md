# Home Server Infrastructure

```bash
# Install Ubuntu Server, Import SSH Keys
# Login with user created during install
sudo su -
cd ~
cp /home/usernameCreatedDuringInstall/.ssh/authorized_keys .
git clone https://github.com/micaharies/infrastructure.git
cd infrastructure
bash install.sh
# Unzip backup'd resources to where they need to be (dockerData, Apache2 Configs)
cd ~/infrastructure/resources
nano docker-compose.yml # Edit all the "Change This" sections
docker compose up -d
rm -rf infrastructure/
```

Manual Things:
1. Drive Mounts 
   1. `lsblk` 
   2. Find Drive(s) to mount
   3. `blkid | grep "/dev/driveHere"` (Repeat for other drives)
   4. `nano /etc/fstab`
   5. Add `UUID=uuidHereFromBefore /mnt/easystore ext4 defaults 0 0` (Repeat for other drives)
   6. `mkdir /mnt/easystore` (Repeat for other drives)
   7. `mount -a`
2. Certbot w/ Certs 
   1. Comment out certs from `/etc/apache2/000-default.conf`
   2. `sudo snap install --classic certbot`
   3. `sudo ln -s /snap/bin/certbot /usr/bin/certbot`
   4. `sudo certbot certonly --apache`, Do each cert individually.
   5. Uncomment certs from `/etc/apache2/000-default.conf`
   6. `sudo systemctl restart apache2`
3. Folder Permissions 
   1. Look in [docker-compose.yml](https://github.com/micaharies/infrastructure/blob/main/resources/docker-compose.yml)
   2. Search for `PGID`
   3. `chown -R user:media /dockerData/containerName`
4. Fix containers
   1. Open Portainer
   2. Look for any container that doesn't have a IP/Published Port that is expecting one
   3. Fix Them
5. Deploy Nextcloud
   1. Backup Nextcloud Data (`mkdir /mnt/easystore/nc_backup_files && mv /mnt/easystore/nextcloud/admin/files/* /mnt/easystore/nc_backup_files/ && rm -rf /mnt/easystore/nextcloud/*`)
```bash
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
      1. Copy down password
      2. Login
      3. Disable Talk
      4. Set Timezone
      5. Start Containers
   2. Copy/Move Data Back (`cp -r /mnt/easystore/nc_backup_files/* /mnt/easystore/nextcloud/admin/files/`, or `mv /mnt/easystore/nc_backup_files/* /mnt/easystore/nextcloud/admin/files/ && chown -R www-data:www-data /mnt/easystore/nextcloud/admin/files/`)
   3. Re-Index Files (`sudo docker exec --user www-data -it nextcloud-aio-nextcloud php occ files:scan --all`)
1. Deploy Immich (`cd /dockerData/immich && docker compose up -d`) [Waiting on this PR to import data again](https://github.com/immich-app/immich/pull/3124)
