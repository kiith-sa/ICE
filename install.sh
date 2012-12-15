#!/bin/bash
DATA_DIR='/usr/local/share/ice-game'

if [ "$(whoami)" != "root" ]; then
    echo "This script requires root priviledges; use as root or use sudo."
    exit 1
fi

if [ -d "$DATA_DIR" ]; then 
    cp -r data/* $DATA_DIR
else
    cp -r data $DATA_DIR
fi

cp -r ice-debug /usr/bin/ice-game.bin
rm -f /usr/bin/ice-game
echo -e "#!/bin/bash\nice-game.bin -R=$DATA_DIR -U=$HOME/.ice-game" >> /usr/bin/ice-game
chmod +x /usr/bin/ice-game

echo 'Done.'
