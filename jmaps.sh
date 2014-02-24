#! /usr/bin/env bash

# Combine multiple JOSM map tiles into a single file.
# This script combine the map tile files downloaded by JOSM into single
# large map. JOSM downloads the OSM tiles to a folder pointed by
# imagery.tms.tilecache_path (Edit->Preferences,Expert Mode, Advance
# Preferences, imagery.tms.tilecache_path). Use the "Show Tile Info" from the
# pop up menu in JOSM to identify the name of the tile. The tiles are usually
# named as zz/xxxxx/yyyyy and the corresponding tiles can be found in the 
# tile cache folder with the name zz_xxxxx_yyyyy.png
#
# Prime Jyothi 20131029 primejyothi [at] gmail [dot] com
# License GPLv3

# Log functions
. logs.sh

function help ()
{
	echo "Usage : `basename $0` [-d] [-h] -t tileDirectory -l topLeftImage -r lowerRightImage -o outputFile"
	echo -e "\t -d : Enable debug messages"
	echo -e "\t -h : Display this help message"
	echo -e "\t -t : Directory containing tile images"
	echo -e "\t -l : Name of the top left tile image file"
	echo -e "\t -r : Name of the lower right tile image file"
	echo -e "\t -o : Name of the output file"
}

while getopts t:l:r:o:hd args
do
	case $args in
	t) dName="$OPTARG"
		;;
	l) startName="$OPTARG"
		;;
	r) endName="$OPTARG"
		;;
	o) outFile="$OPTARG"
		;;
	d) dbgFlag=Y
		;;
	h) help
		exit
		;;
	*) help
	esac
done

if [ -z "$dName" -o -z "$startName" -o -z "$endName" -o -z "$outFile" ]
then
	help
	exit 2
fi

if [[ ! -d "$dName" ]]
then
	echo "Unable to access directory : $dName"
	exit 2
fi

if [[ ! -r "${dName}/${startName}" ]]
then
	echo "Unable to access file ${dName}/${startName}"
	# exit 3
fi


# Blank file, if tiles are not available
convert -size 256x256 xc:white /tmp/blank.png

# The tiles file name have the format zz_xxxx_yyyy.ext
# Remove the ext so that the x and y part can be extracted easily
ext=`echo $startName | awk -F"." '{print $NF}'`
dbg $LINENO "[${ext}]"
fName=`basename $startName .${ext}`

zoom=`echo $fName | awk -F"_" '{print $1}'`
dbg $LINENO "zoom [${zoom}]"

xStart=`echo $fName | awk -F"_" '{print $2}'`
dbg $LINENO "xStart [${xStart}]"

fName=`basename $endName .${ext}`
xEnd=`echo $fName | awk -F"_" '{print $2}'`
dbg $LINENO "xEnd [${xEnd}]"

# Find the max yyyy and min yyyy for the file range xStart and xEnd.
xRange=`eval echo {${xStart}..${xEnd}}`
dbg $LINENO xRange [${xRange}]
# Generate list of files between xStart and xEnd
fList=/tmp/flist
for f in ${xRange}
do
	ls -1 "${dName}/${zoom}_${f}_"*.png >> ${fList}
done

# Find the max yyyy and min yyyy from the list
awk -F"_" '{print $NF}' ${fList} |awk -F"." '{print $1}' > ${fList}.lst

yStart=`sort ${fList}.lst | sort -n | head -1`
yEnd=`sort ${fList}.lst | sort -n | tail -1`
rm ${fList} ${fList}.lst


fName=`basename $startName .${ext}`
yStart=`echo $fName | awk -F"_" '{print $3}'`
dbg $LINENO "yStart [${yStart}]"

fName=`basename $endName .${ext}`
yEnd=`echo $fName | awk -F"_" '{print $3}'`
dbg $LINENO "yEnd [${yEnd}]"

dbg $LINENO "yStart = $yStart yEnd = $yEnd"

# Number of tiles along x axis
xNum=`expr $xEnd - $xStart + 1` 
dbg $LINENO xNum [${xNum}]

# Number of tiles along y axis
yNum=`expr $yEnd - $yStart + 1` 
dbg $LINENO yNum [${yNum}]

yRange=`eval echo {${yStart}..${yEnd}}`
dbg $LINENO yRange [${yRange}]

n=0
for y in $yRange
do
	for x in $xRange
	do
		target=`echo -n "${dName}/${zoom}_${x}_${y}.${ext}"`
		dbg $LINENO target $target
		if [[ -r "${target}" ]]
		then
			lst=`echo $lst \"$target\"`	
		else
			lst=`echo $lst /tmp/blank.png`	
		fi
	done
	n=`expr $n + 1`
	log $LINENO "Processing $n of $yNum"
	# Bash is inserting single quotes which is causing montage to fail.
	# Using bash -c till I find the root cause.
	# dbg $LINENO lst [${lst}]
	# montage -geometry 256x256+0+0 -tile ${xNum}x1 $lst /tmp/$n.png
	bash -c "montage -geometry 256x256+0+0 -tile ${xNum}x1 $lst /tmp/$n.png"
	lst=""
done

xLen=`expr $xNum \* 256`
yRange=`eval echo {1..${yNum}}`
for i in ${yRange}
do
	lst=`echo $lst /tmp/$i.png`
done

log $LINENO "Combining files..."
montage -geometry ${xLen}x256+0+0 -tile 1x${yNum} $lst $outFile

# Remove intermediate files
for i in ${yRange}
do
	rm /tmp/$i.png
done
rm /tmp/blank.png
log $LINENO "Finished."
