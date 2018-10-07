#!/bin/bash

ls /opt/Tautulli > /tmp/checkapp.txt
clear

if [ -s /tmp/checkapp.txt ]; then

	ALREADYINSTALLED

else

	EXPLAINTASK

	CONFIRMATION

	if [[ ${REPLY} =~ ^[Yy]$ ]]; then

		GOAHEAD

		# Open ports

		sudo ufw allow 8181

		# Dependencies

		sudo apt-get upgrade -y && sudo apt-get upgrade -y

		sudo -s apt-get -y install \
			git-core \
			python3-setuptools-git \
		denyhosts at sudo software-properties-common

		# Main script

		cd /opt/
		sudo git clone https://github.com/Tautulli/Tautulli.git
		sudo chown plexuser:plexuser -R /opt/Tautulli

		# Installing Services

		sudo rsync -a /opt/GooPlex/scripts/tautulli.service /etc/systemd/system/tautulli.service
		sudo systemctl enable tautulli.service
		sudo systemctl daemon-reload
		sudo systemctl start tautulli.service

		TASKCOMPLETE

	else

		CANCELTHIS

	fi

fi

rm /tmp/checkapp.txt
PAUSE
