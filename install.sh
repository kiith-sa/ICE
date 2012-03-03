#!/bin/bash
cp -r data /usr/local/share/ice
cp -r ice-release /usr/bin/ice.bin
rm -f /usr/bin/ice
echo -e "#!/bin/bash\nice.bin -R=/usr/local/share/ice -U=$HOME/.ice" >> /usr/bin/ice
chmod +x /usr/bin/ice
