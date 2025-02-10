#!/bin/bash

echo "📢 Démarrage de l'installation automatique..."

# ✅ Mise à jour du système
sudo apt update && sudo apt upgrade -y

# ✅ Installation de VLC, des outils pour la gestion de la TV et des logs
sudo apt install -y vlc cec-utils wget
mkdir -p /home/pi/logs

# ✅ Désactivation de la mise en veille de l’écran
sudo bash -c 'echo "hdmi_blanking=1" >> /boot/config.txt'

# ✅ Configuration par défaut du Wi-Fi
DEFAULT_SSID="Livebox-F6F0"
DEFAULT_PASSWORD="uxvykt3oLpHMQcf57f"

# ✅ Script pour changer le Wi-Fi
cat <<EOF > /home/pi/change_wifi.sh
#!/bin/bash
if [ "\$#" -ne 2 ]; then
    echo "Usage: ./change_wifi.sh <SSID> <PASSWORD>"
    exit 1
fi
NEW_SSID="\$1"
NEW_PASSWORD="\$2"
echo "network={" | sudo tee /etc/wpa_supplicant/wpa_supplicant.conf
echo "    ssid=\"\$NEW_SSID\"" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf
echo "    psk=\"\$NEW_PASSWORD\"" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf
sudo wpa_cli -i wlan0 reconfigure
echo "📶 Wi-Fi mis à jour avec SSID: \$NEW_SSID"
EOF
chmod +x /home/pi/change_wifi.sh

# ✅ Configuration initiale du Wi-Fi
echo "network={" | sudo tee /etc/wpa_supplicant/wpa_supplicant.conf
echo "    ssid=\"$DEFAULT_SSID\"" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf
echo "    psk=\"$DEFAULT_PASSWORD\"" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf
sudo wpa_cli -i wlan0 reconfigure

echo "📶 Wi-Fi configuré avec SSID: $DEFAULT_SSID"

# ✅ Vérification du CEC
CEC_CHECK=$(echo "scan" | cec-client -s -d 1)
if [[ "$CEC_CHECK" == *"device #0"* ]]; then
    echo "CEC détecté ✅" >> /home/pi/logs/setup.log
else
    echo "⚠️ CEC non détecté ! Vérifiez la configuration HDMI de votre TV." >> /home/pi/logs/setup.log
fi

# ✅ Configuration du script de lecture en boucle
cat <<EOF > /home/pi/start_video.sh
#!/bin/bash
while true; do
    cvlc --fullscreen --loop --no-video-title --no-xlib /home/pi/video.mp4
    sleep 2  # Ajout d'un délai pour éviter une surcharge CPU
done
EOF
chmod +x /home/pi/start_video.sh
(crontab -l ; echo "@reboot /home/pi/start_video.sh &") | crontab -

# ✅ Téléchargement initial de la vidéo avec vérification du Wi-Fi
VIDEO_URL="https://www.etienne-coffeeshop.com/wp-content/uploads/2025/02/video.mp4"
VIDEO_PATH="/home/pi/video.mp4"
while ! ping -c 1 -W 1 8.8.8.8; do
    echo "⚠️ Pas de connexion internet. Nouvelle tentative dans 10 secondes..." >> /home/pi/logs/setup.log
    sleep 10
done
wget -O "$VIDEO_PATH" "$VIDEO_URL"

# ✅ Création du script de mise à jour de la vidéo
cat <<EOF > /home/pi/update_video.sh
#!/bin/bash
VIDEO_URL="$VIDEO_URL"
VIDEO_PATH="$VIDEO_PATH"
TEMP_VIDEO="/home/pi/video_temp.mp4"
echo "\$(date) - Début de la mise à jour de la vidéo." >> /home/pi/logs/update_video.log
if wget -O "\$TEMP_VIDEO" "\$VIDEO_URL"; then
    mv "\$TEMP_VIDEO" "\$VIDEO_PATH"
    pkill vlc
    sleep 2  # Ajout d'un délai avant redémarrage
    cvlc --fullscreen --loop --no-video-title --no-xlib "\$VIDEO_PATH" &
    echo "\$(date) - Vidéo mise à jour et relancée." >> /home/pi/logs/update_video.log
else
    echo "\$(date) - ⚠️ Erreur lors du téléchargement de la vidéo." >> /home/pi/logs/update_video.log
fi
EOF
chmod +x /home/pi/update_video.sh
(crontab -l ; echo "0 6 * * * /home/pi/update_video.sh") | crontab -

# ✅ Configuration du script de gestion de la TV
cat <<EOF > /home/pi/tv_control.sh
#!/bin/bash
if [ "\$1" == "on" ]; then
    echo "on 0" | cec-client -s -d 1
elif [ "\$1" == "off" ]; then
    echo "standby 0" | cec-client -s -d 1
fi
EOF
chmod +x /home/pi/tv_control.sh

# ✅ Ajout des tâches CRON pour allumer/éteindre la TV
(crontab -l ; echo "0 6 * * * /home/pi/tv_control.sh on") | crontab -
(crontab -l ; echo "0 21 * * * /home/pi/tv_control.sh off") | crontab -

echo "🎉 Installation terminée ! Redémarrage..."
sudo reboot
