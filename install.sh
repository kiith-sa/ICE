#!/bin/bash
cp -r data /usr/local/share/dpong
cp -r pong-release /usr/bin/dpong.bin
rm -f /usr/bin/dpong
echo -e "#!/bin/bash\ndpong.bin -R=/usr/local/share/dpong -U=$HOME/.dpong" >> /usr/bin/dpong
chmod +x /usr/bin/dpong
