#!/bin/sh

#   video2gif - Convert a video clip into an animated GIF
#
#   Copyright (C) 2007  Douglas A. Augusto (daaugusto@gmail.com)
#   Minor modifications by Damien Smeets (@gmail.com)
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.

VERSION="20071030"

usage()
{
   SCRIPT_NAME=`basename $0`
   echo "video2gif - Convert a video clip into an animated GIF (v. $VERSION)"
   echo ""
   echo "Usage: $SCRIPT_NAME -t <secs> filename [-o <file> -s <hh:mm:ss>"
   echo "                 -kb <size> -fps <n> -size <WxH> -c <n> -speed <f> -d -h]"
   echo
   echo "where:"
   echo
   echo "  -t <n>"
   echo "     clip duration in seconds (n>0)"
   echo "  -s hh:mm:ss[.xxx]"
   echo "      start time (default = 00:00:00)"
   echo "  -kb <n>"
   echo "      maximum kilobytes allowed (n>0; default = unlimited)"
   echo "  -fps <n>"
   echo "      frame rate (1<=n<=30; default = 30, may be adjusted to satisfy the maximum size)"
   echo "  -size <WxH>"
   echo "      width and height of output (imagemagick syntax; default height=120px, width=auto)"
   echo "  -o <filename>"
   echo "      output file (default = anim.gif)"
   echo "  -c <n>"
   echo "      restrict GIF colors to maximum n colors (n>=2)"
   echo "  -speed <f>"
   echo "      speed factor (0.1<=f<=10; default = 1.0)"
   echo "  -d"
   echo "      debug (don't delete the log file)"
   echo "  -h"
   echo "      this help"
   echo
   echo "Example: $SCRIPT_NAME -t 10 -s 00:05:25 -kb 1000 video.avi -o video.gif"
   echo ""

   echo "This is free software. You may redistribute copies of it under the terms"
   echo "of the GNU General Public License <http://www.gnu.org/licenses/gpl.html>."
   echo "There is NO WARRANTY, to the extent permitted by law."
   echo ""
   echo "Written by Douglas Adriano Augusto (daaugusto)."

   exit 1
}

# ----------------------------------------------------------------------
# Check dependencies
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

# ----------------------------------------------------------------------
CURDIR=`pwd`
TMPDIR="/tmp/v2g-$$"
LOG="$TMPDIR/video2gif.log"

mkdir -p $TMPDIR;

# Print the command-line into LOG file
(echo "$*"; echo) >> $LOG

# ----------------------------------------------------------------------
RESIZE="x120" # pixels
FPS=30 # first try
START="00:00:00"
DURATION=""
MAXSIZE=0
OUTPUT="anim.gif"
FILE=""
COLORS=""
COLORS_CMD=""
SPEED=1.0;
DEBUG=""

# ----------------------------------------------------------------------
while [ $# -ge 1 ]; do
   case $1 in
      -s)    shift; START="$1";;
      -t)    shift; DURATION="$1";;
      -kb)   shift; MAXSIZE="$1";;
      -fps)  shift; FPS="$1";;
      -size) shift; RESIZE="$1";;
      -o)    shift; OUTPUT="$1";;
      -c)    shift; COLORS="$1";;
      -speed)  shift; SPEED="$1";;
      -d)    DEBUG="1";;
      -h)    usage;;
      *)     FILE="$1";;
   esac
   shift
done

# ----------------------------------------------------------------------
# check input args
if [ -z "$DURATION" ]; then
   echo "Error: missing '-t'."
   usage
fi

if [ -z "$OUTPUT" ]; then
   echo "Error: -o is invalid."
   usage
fi

if [ ! -e "$FILE" ]; then
   echo "Error: a valid source video (filename) is required."
   usage
fi

if [ `echo "$SPEED < 0.1 || $SPEED > 10.0" | calc -p` -eq 1 ]; then
   echo "Error: option '-speed' is out of range."
   usage
fi

if [ `echo "$FPS < 1 || $FPS > 30.0" | calc -p` -eq 1 ]; then
   echo "Error: option '-fps' is out of range."
   usage
fi

if [ -n "$COLORS" ]; then
  if [ `echo "$COLORS < 2" | calc -p` -eq 1 ]; then
     echo "Error: option '-colors' is out of range."
     usage
  else
     COLORS_CMD="--colors $COLORS"
  fi
fi

if [ `echo "$MAXSIZE < 0" | calc -p` -eq 1 ]; then
  echo "Error: option '-kb' is out of range."
  usage
fi

# ----------------------------------------------------------------------
echo "video2gif - Convert a video clip into an animated GIF (v. $VERSION)"
echo ""
echo "> Log file: $LOG"

SIZE=0

echo; echo "> Trying with FPS=$FPS...";

while true;
do

   rm -f $TMPDIR/[0-9]*.png $TMPDIR/[0-9]*.gif $TMPDIR/*.avi

   # ----------------------------------------------------------------------
   # mplayer -ss is inaccurate
   CMD_FFMPEG='ffmpeg -y -b 2000k -an -ss $START -t $DURATION -i "$FILE" -r $FPS -c:v libx264 -preset slow -crf 22  $TMPDIR/ffmpeg.avi >> $LOG 2>&1'
   echo $CMD_FFMPEG >> $LOG
   echo; echo "Running ffmpeg...";
   if ! eval $CMD_FFMPEG; then echo "An error occurred in ffmpeg, aborting..."; exit 1; fi

   # ----------------------------------------------------------------------
   CMD_MPLAYER='mplayer -nosound -vf hqdn3d,pp=lb/ha:128:7/va/dr ffmpeg.avi -vo png:z=1 >> $LOG 2>&1'
   echo $CMD_MPLAYER >> $LOG
   cd $TMPDIR
   echo; echo "Running mplayer...";
   if ! eval $CMD_MPLAYER; then echo "An error occurred in mplayer, aborting..."; exit 1; fi
   cd $CURDIR

   # ----------------------------------------------------------------------
   CMD_MOGRIFY='mogrify -resize $RESIZE -format gif $TMPDIR/[0-9]*.png >> $LOG 2>&1'
   echo $CMD_MOGRIFY >> $LOG
   echo; echo "Running mogrify...";
   if ! eval $CMD_MOGRIFY; then echo "An error occurred in mogrify, aborting..."; exit 1; fi

   # ----------------------------------------------------------------------
   CMD_GIFSICLE='gifsicle --loop=forever $COLORS_CMD -O2 -d $(echo "round((100/$FPS)/$SPEED)"|calc -p) $TMPDIR/[0-9]*.gif -o "$OUTPUT" >> $LOG 2>&1'
   echo $CMD_GIFSICLE >> $LOG
   echo; echo "Running gifsicle...";
   if ! eval $CMD_GIFSICLE; then echo "An error occurred in gifsicle, aborting..."; exit 1; fi

   # ----------------------------------------------------------------------
   rm -f $TMPDIR/[0-9]*.png $TMPDIR/[0-9]*.gif $TMPDIR/*.avi
   # ----------------------------------------------------------------------

   # check the final size (in KB)
   SIZE=$(echo "round(`du -b "$OUTPUT" | cut -f 1`/1024)"|calc -p)

   if [ $MAXSIZE -eq 0 -o $SIZE -le $MAXSIZE -o $FPS -eq 1 ]; then
      # delete only if DEBUG mode isn't enabled
      if [ -z "$DEBUG" ]; then rm -f $LOG; rmdir $TMPDIR; fi

      echo; echo "Done! Saved GIF as "$OUTPUT" (FPS=$FPS, final size=${SIZE}KB)"
      exit 0;
   else
      # calculating the next FPS guess
      FPS=`echo "floor($FPS * $MAXSIZE/$SIZE)"|calc -p`
      if [ $FPS -lt 1 ]; then FPS=1; fi
   fi

   echo; echo "> Trying with FPS=$FPS... (last size was ${SIZE}KB)";

done
