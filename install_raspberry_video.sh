#!/bin/bash

echo "📢 Démarrage de l'installation automatique..."

# ✅ Mise à jour du système
sudo apt update && sudo apt upgrade -y

# ✅ Installation de VLC et des outils pour la gestion de la TV
sudo apt install -y vlc cec-utils wget

# ✅ Configuration du script de lecture en boucle
echo '#!/bin/bash' > /home/pi/start_video.sh
echo 'while true; do' >> /home/pi/start_video.sh
echo '    cvlc --fullscreen --loop --no-video-title /home/pi/video.mp4' >> /home/pi/start_video.sh
echo 'done' >> /home/pi/start_video.sh
chmod +x /home/pi/start_video.sh
(crontab -l ; echo "@reboot /home/pi/start_video.sh &") | crontab -

# ✅ Téléchargement initial de la vidéo
VIDEO_URL="https://www.etienne-coffeeshop.com/wp-content/uploads/2025/02/video.mp4"
wget -O /home/pi/video.mp4 "$VIDEO_URL"

# ✅ Création du script de mise à jour de la vidéo
echo '#!/bin/bash' > /home/pi/update_video.sh
echo 'VIDEO_URL="https://www.etienne-coffeeshop.com/wp-content/uploads/2025/02/video.mp4"' >> /home/pi/update_video.sh
echo 'VIDEO_PATH="/home/pi/video.mp4"' >> /home/pi/update_video.sh
echo 'TEMP_VIDEO="/home/pi/video_temp.mp4"' >> /home/pi/update_video.sh
echo '' >> /home/pi/update_video.sh
echo 'wget -O "$TEMP_VIDEO" "$VIDEO_URL"' >> /home/pi/update_video.sh
echo 'if [ $? -eq 0 ]; then' >> /home/pi/update_video.sh
echo '    mv "$TEMP_VIDEO" "$VIDEO_PATH"' >> /home/pi/update_video.sh
echo '    pkill vlc' >> /home/pi/update_video.sh
echo '    cvlc --fullscreen --loop --no-video-title "$VIDEO_PATH" &' >> /home/pi/update_video.sh
echo 'fi' >> /home/pi/update_video.sh
chmod +x /home/pi/update_video.sh
(crontab -l ; echo "0 6 * * * /home/pi/update_video.sh") | crontab -

# ✅ Configuration du script de gestion de la TV
echo '#!/bin/bash' > /home/pi/tv_control.sh
echo 'if [ "$1" == "on" ]; then' >> /home/pi/tv_control.sh
echo '    echo "on 0" | cec-client -s -d 1' >> /home/pi/tv_control.sh
echo 'elif [ "$1" == "off" ]; then' >> /home/pi/tv_control.sh
echo '    echo "standby 0" | cec-client -s -d 1' >> /home/pi/tv_control.sh
echo 'fi' >> /home/pi/tv_control.sh
chmod +x /home/pi/tv_control.sh

# ✅ Ajout des tâches CRON pour allumer/éteindre la TV
(crontab -l ; echo "0 6 * * * /home/pi/tv_control.sh on") | crontab -
(crontab -l ; echo "0 21 * * * /home/pi/tv_control.sh off") | crontab -

echo "🎉 Installation terminée ! Redémarrage..."
sudo reboot
