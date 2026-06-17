#!/bin/bash 
sshpass -p ',ilovejjqwe' scp ucode/template/themes/argon/*.ut root@192.168.1.1:/usr/share/ucode/luci/template/themes/argon/
sshpass -p ',ilovejjqwe' scp -r htdocs/luci-static/argon/ root@192.168.1.1:/www/luci-static/
echo "Upload complete."
