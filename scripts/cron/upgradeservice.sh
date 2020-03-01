#!/bin/bash

VERSION=2.2.1

CONFIGVARS=${CONFIGS}/Docker/.config
sudo mkdir -p ${CONFIGVARS}
sudo chown -R ${USER}:${USER} ${CONFIGS}/Docker
touch ${CONFIGVARS}/version

if [ "$(cat ${CONFIGVARS}/version)" == ${VERSION} ]; then

	echo "${GREEN}Your system has already been upgraded to v${VERSION}... skipping upgrade${STD}"; echo

else

	echo "${LYELLOW}Upgrading to v${VERSION}... just a moment${STD}"; echo; sleep 2

	# Check if necessary apps are installed

	if [ ! -e ${CONFIGVARS}/proxyversion ]; then
		sudo apt-get update
		APPLIST="acl apt-transport-https ca-certificates curl fuse git gpg-agent grsync jq mergerfs nano pigz rsyncufw socat sqlite3 ufw unzip wget"
		for i in ${APPLIST}; do
			echo Checking $i...
			sudo apt-get -y install $i
			echo
		done
	fi

	# Move and rename folders

	if [ -d ${CONFIGS}/Security ]; then
		sudo mv ${CONFIGS}/Certs ${CONFIGS}/Docker
		sudo mv ${CONFIGS}/Docker/Certs ${CONFIGS}/Docker/certs
		sudo mv ${CONFIGS}/nginx ${CONFIGS}/Docker
		sudo mv ${CONFIGS}/Security ${CONFIGS}/Docker
		sudo mv ${CONFIGS}/Docker/Security ${CONFIGS}/Docker/security
	fi

	if [ -d /var/local/.Gooby ]; then
		sudo mv /var/local/.Gooby/* ${CONFIGVARS}
		sudo rm -r /var/local/.Gooby
	fi

	if [ -d /var/local/Gooby/.config ]; then
		sudo mv ${CONFIGS}/.config/* ${CONFIGVARS}
		sudo mv ${CONFIGVARS}/rclonev ${CONFIGVARS}/rcloneversion
		sudo mv ${CONFIGVARS}/upgrade ${CONFIGVARS}/version
		sudo rm -r /var/local/Gooby/.config
	fi

	# Upgrade Rclone service 

	cat /etc/systemd/system/rclonefs.service | grep "pass" > /dev/null
	if ! [[ ${?} -eq 0 ]]; then
		sudo mv /etc/systemd/system/rclone* /tmp
		sudo rsync -a /opt/Gooby/scripts/services/rclonefs* /etc/systemd/system/
		sudo sed -i "s/GOOBYUSER/${USER}/g" /etc/systemd/system/rclonefs.service
		sudo systemctl daemon-reload
	fi

	cat ${HOME}/.config/rclone/rclone.conf | grep "Local" > /dev/null
	if ! [[ ${?} -eq 0 ]]; then
		echo [Local] >> ${HOME}/.config/rclone/rclone.conf
		echo type = local >> ${HOME}/.config/rclone/rclone.conf
		echo nounc = >> ${HOME}/.config/rclone/rclone.conf
	fi

	# Add resetbackup cron

	if crontab -l | grep 'backup.sh'; then
		crontab -l | grep 'resetbackup' || (crontab -l 2>/dev/null; echo "10 2 1 * * /bin/resetbackup > /dev/null 2>&1") | crontab -
	fi

	# Add Gooby branch

	if [ ! -s ${CONFIGVARS}/goobybranch ]; then
		echo "master" > ${CONFIGVARS}/goobybranch
	fi

	# Add proxy version

	if [ ! -s ${CONFIGVARS}/proxyversion ]; then
		echo "nginx" > ${CONFIGVARS}/proxyversion
		touch ${CONFIGVARS}/cf_email ${CONFIGVARS}/cf_key
	fi

	if [ ! -d ${CONFIGS}/Docker/traefik ]; then
		sudo mkdir -p ${CONFIGS}/Docker/traefik
		sudo rsync -a /opt/Gooby/scripts/services/traefik.toml ${CONFIGS}/Docker/traefik/
		sudo sed -i "s/GOOBYDOMAIN/${MYDOMAIN}/g" ${CONFIGS}/Docker/traefik/traefik.toml
		sudo sed -i "s/GOOBYEMAIL/${MYEMAIL}/g" ${CONFIGS}/Docker/traefik/traefik.toml
	fi

	# Update Proxy

	if [ -f ${CONFIGS}/Docker/components/00-AAA.yaml ]; then
		PROXYVERSION=$(cat ${CONFIGVARS}/proxyversion)
		sudo rsync -a /opt/Gooby/scripts/${PROXYVERSION}/{00-version.yaml,01-proxy.yaml,99-network.yaml} ${CONFIGS}/Docker/components
		sudo rm ${CONFIGS}/Docker/components/00-AAA.yaml
	fi

	# Finalizing upgrade

	echo; echo "${GREEN}Upgrade to v${VERSION} complete... prodeeding${STD}"; echo

fi

echo ${VERSION} > ${CONFIGVARS}/version
