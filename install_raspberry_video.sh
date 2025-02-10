#!/bin/bash

echo "🔄 Mise à jour du système..."
sudo apt update && sudo apt upgrade -y

echo "🔧 Installation des dépendances nécessaires..."
sudo apt install -y vlc cec-utils wget

echo "🌐 Vérification de la connexion Internet..."
if ping -c 3 google.com > /dev/null; then
    echo "✅ Connexion Internet établie. Téléchargement de la vidéo..."
    wget -O /home/pi/video.mp4 "https://www.etienne-coffeeshop.com/wp-content/uploads/2025/02/video.mp4"
else
    echo "❌ Pas de connexion Internet. Impossible de télécharger la vidéo."
    echo "⚠️ Assurez-vous que le Raspberry Pi est connecté au Wi-Fi, puis relancez le script."
    exit 1
fi

echo "🛠 Configuration du service pour la lecture en boucle..."
cat <<EOF | sudo tee /etc/systemd/system/video-loop.service
[Unit]
Description=Lecture vidéo en boucle avec VLC sur Raspberry Pi
After=multi-user.target

[Service]
ExecStart=/usr/bin/cvlc --fullscreen --loop /home/pi/video.mp4
Restart=always
User=pi
Group=pi
Environment=DISPLAY=:0

[Install]
WantedBy=multi-user.target
EOF

echo "🚀 Activation du service vidéo..."
sudo systemctl daemon-reload
sudo systemctl enable video-loop.service
sudo systemctl start video-loop.service

echo "🖥️ Activation de HDMI-CEC pour contrôle TV..."
sudo apt install -y cec-utils

echo "✅ Test HDMI-CEC : allumer la TV"
echo "on 0" | cec-client -s -d 1

echo "✅ Test HDMI-CEC : éteindre la TV"
echo "standby 0" | cec-client -s -d 1

echo "✅ Installation terminée !"
