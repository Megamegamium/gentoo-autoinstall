#!/bin/bash
# Cyberpunk 2077-inspired Rice Script for Gentoo KDE
set -e

# --------------------------------------------
# Base Aesthetic Packages
# --------------------------------------------
sudo emerge -q --autounlock \
    plasma-meta \
    konsole \
    latte-dock \
    kvantum \
    qps \
    neofetch \
    cmatrix \
    lolcat \
    figlet \
    imagemagick \
    fontconfig \
    vlc \
    codeblocks \
    kdenlive

# --------------------------------------------
# Cyberpunk Theme Elements
# --------------------------------------------
# Plasma Theme
git clone https://github.com/Robert-96/Cyberpunk-Neon.git /tmp/Cyberpunk-Neon
sudo cp -r /tmp/Cyberpunk-Neon/Cyberpunk-Neon /usr/share/plasma/desktoptheme/

# Global Theme
sudo git clone https://github.com/Alexhuszagh/Breeze-Enhanced /usr/share/plasma/look-and-feel/Breeze-Enhanced

# Icons
sudo emerge -q papirus-icon-theme
wget https://github.com/rtlewis88/rtl88-Themes/raw/master/Cyberpunk-Neon-Papirus.tar.xz
sudo tar -xJf Cyberpunk-Neon-Papirus.tar.xz -C /usr/share/icons/

# SDDM Theme
git clone https://github.com/MarianArlt/sddm-sugar-candy /tmp/sddm-sugar-candy
sudo cp -r /tmp/sddm-sugar-candy /usr/share/sddm/themes/sugar-candy

# Konsole Color Scheme
git clone https://github.com/Gogh-Co/Gogh.git /tmp/gogh
/tmp/gogh/themes/cyberpunk-neon.sh

# --------------------------------------------
# Fonts & Typography
# --------------------------------------------
sudo emerge -q \
    media-fonts/terminus-font \
    media-fonts/hack-ttf \
    media-fonts/noto \
    media-fonts/fontawesome

wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip
sudo unzip JetBrainsMono.zip -d /usr/share/fonts/

# Refresh font cache
fc-cache -fv

# --------------------------------------------
# System Customization
# --------------------------------------------
# Create rice config directory
mkdir -p ~/.cyberpunk/{scripts,wallpapers,conky}

# Cyberpunk wallpaper
wget https://wallpapercave.com/wp/wp12503473.jpg -O ~/.cyberpunk/wallpapers/main.jpg
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
    "var allDesktops = desktops(); for (i=0;i<allDesktops.length;i++) { d = allDesktops[i]; d.wallpaperPlugin = 'org.kde.image'; d.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General'); d.writeConfig('Image', 'file://$HOME/.cyberpunk/wallpapers/main.jpg') }"

# Plasma Theme Apply
lookandfeeltool -a org.kde.breeze-enhanced.desktop

# Kvantum Theme
git clone https://github.com/tsujan/KvCyberpunk /tmp/KvCyberpunk
mkdir -p ~/.config/Kvantum/
cp -r /tmp/KvCyberpunk/KvCyberpunk ~/.config/Kvantum/
kvantummanager --set KvCyberpunk

# --------------------------------------------
# Terminal Customization
# --------------------------------------------
# Install Oh-My-Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Powerlevel10k Theme
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k

# Cyberpunk ZSH RC
cat <<EOF > ~/.zshrc
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
POWERLEVEL9K_MODE="nerdfont-complete"
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon dir vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status root_indicator background_jobs time)
POWERLEVEL9K_COLOR_SCHEME='dark'
plugins=(git zsh-syntax-highlighting zsh-autosuggestions colored-man-pages)
source \$ZSH/oh-my-zsh.sh

# Cyberpunk Color Scheme
echo -e "\e]P01c1c1c" # Black
echo -e "\e]P1ff0055" # Red
echo -e "\e]P200ff99" # Green
echo -e "\e]P3fffc00" # Yellow
echo -e "\e]P400b4ff" # Blue
echo -e "\e]P5d600ff" # Magenta
echo -e "\e]P600ffd2" # Cyan
echo -e "\e]P7e5e5e5" # White
clear
EOF

# --------------------------------------------
# Visual Effects
# --------------------------------------------
# Compositor Settings
kwriteconfig5 --file kwinrc --group Compositing --key AnimationSpeed 3
kwriteconfig5 --file kwinrc --group Compositing --key Backend OpenGL
kwriteconfig5 --file kwinrc --group Compositing --key GlSmoothScale 8
kwriteconfig5 --file kwinrc --group Compositing --key Enabled true

# Latte Dock Layout
cat <<EOF > ~/.config/latte/layouts/cyberpunk.layout.latte
[Layout]
version=0.2
scheme=0
lastNonAssignedLayout=33554436
disableBordersForMaximizedWindows=false
showInMenu=true
lockPanels=false
preferredForShortcuts=
colorizedStyle=Material

[Containments]
1\activityId=
1\applets=2,3,4,5,6,7,8,9,10,11
1\layout=0
1\preferredForShortcuts=
1\type=0
EOF

# Conky System Monitor
sudo emerge -q conky
wget https://raw.githubusercontent.com/brndnmtthws/conky/master/configs/conky_cyberpunk.conf -O ~/.cyberpunk/conky/conkyrc

cat <<EOF > ~/.config/autostart/conky.desktop
[Desktop Entry]
Type=Application
Name=Conky
Exec=conky -c ~/.cyberpunk/conky/conkyrc
X-KDE-autostart-phase=2
EOF

# --------------------------------------------
# Final System Polish
# --------------------------------------------
# Neon Grub Theme
git clone https://github.com/ChrisTitusTech/grub-cyberpunk.git /tmp/grub-cyberpunk
sudo cp -r /tmp/grub-cyberpunk /boot/grub/themes/cyberpunk
sudo sed -i 's/^GRUB_THEME=.*/GRUB_THEME="\/boot\/grub\/themes\/cyberpunk\/theme.txt"/' /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Neon Boot Animation
sudo emerge -q plymouth
sudo plymouth-set-default-theme -R cyberpunk

# Custom Login Sound
wget https://filesamples.com/samples/audio/wav/sample1.wav -O /usr/share/sounds/login.wav
kwriteconfig5 --file kwinrc --group General --key LoginSound /usr/share/sounds/login.wav

echo "Rice complete! Reboot to enjoy your cyberpunk system."
