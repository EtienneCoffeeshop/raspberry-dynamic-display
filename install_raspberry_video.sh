#!/bin/bash

echo "🔄 Mise à jour du système..."
sudo apt update && sudo apt upgrade -y

echo "🔧 Installation des dépendances..."
sudo apt install -y mpv cec-utils wget

echo "📥 Téléchargement de la vidéo..."
wget -O /home/pi/video.mp4 "https://franchise.etienne-coffeeshop.com/uploads/video.mp4"

echo "🛠 Configuration du service pour la lecture en boucle..."
cat <<EOF | sudo tee /etc/systemd/system/video-loop.service
[Unit]
Description=Lecture vidéo en boucle sur Raspberry Pi
After=multi-user.target

[Service]
ExecStart=/usr/bin/mpv --fs --loop=inf /home/pi/video.mp4
Restart=always
User=pi
Group=pi

[Install]
WantedBy=multi-user.target
EOF

echo "🚀 Activation du service..."
sudo systemctl daemon-reload
sudo systemctl enable video-loop.service
sudo systemctl start video-loop.service

echo "🎛 Activation de HDMI-CEC pour contrôle TV..."
sudo apt install -y cec-utils

echo "✅ Test HDMI-CEC : allumer la TV"
echo "on 0" | cec-client -s -d 1

echo "✅ Test HDMI-CEC : éteindre la TV"
echo "standby 0" | cec-client -s -d 1

echo "✅ Installation terminée !"

