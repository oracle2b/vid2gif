#!/bin/sh

DEP="ffmpeg mplayer mogrify gifsicle calc du cut"
for d in $DEP; do
   if ! type $d >> /dev/null 2>&1; then
      echo "Error: $d is required!";

      echo -e "\nvideo2gif's dependencies:"
      echo ""
      echo "ffmpeg    - http://ffmpeg.mplayerhq.hu"
      echo "mplayer   - http://www.mplayerhq.hu"
      echo "mogrify   - http://www.imagemagick.org"
      echo "calc      - http://www.isthe.com/chongo/tech/comp/calc/index.html"
      echo "gifsicle  - http://www.lcdf.org/gifsicle"
      echo "coreutils - http://www.gnu.org/software/coreutils"

      exit 1;
      fi
done

sudo mkdir /usr/share/vid2gif
sudo cp vid* /usr/share/vid2gif 
sudo ln -s /usr/share/vid2gif/video2gif /usr/bin/video2gif

