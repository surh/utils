#!/usr/bin/env bash

# Read options
pre_compress=false
while getopts d:g:p:b flag
do
	case "${flag}" in
		d) indir=${OPTARG};;
		g) gdrive=${OPTARG};;
		p) gdrive_path=${OPTARG};;
		b) pre_compress=true;;
	esac
done
# indir=$1
# gdrive="fraserlab_gdrive"
# gdrive_path=""

# Set parameters defaults
if [[ $indir == "" ]]; then
	echo "No input directory specified"
	exit 1
fi

if [[ $gdrive == "" ]]; then
	gdrive="fraserlab_gdrive"
	echo "No rclone remote specified. Trying $gdrive"
fi

if [[ $gdrive_path == "" ]]; then
	id=`whoami`
	gdrive_path="backup/$id"
	echo "gdrive path not provided, using $gdrive_path"
fi


# echo "indir is $indir"
# echo "gdrive is $gdrive"
# echo "gdrive_path is $gdrive_path"
# echo "pre_compress is $pre_compress"

# exit 0

# First compress all files.
compressed=0
if [[ "$pre_compress" == "true" ]]; then
	file_exceptions='! -name "*.gz" ! -name "*.bam" ! -name "*.bz2" ! -name "*.zip"'
	dir_exceptions='! -path "*/.snakemake/*"'
	echo "Compressiing files inside $indir"
	find $indir -type f $file_exceptions $dir_exceptions -exec gzip {} \\;
	compressed=1
fi

# Create tar file
name=`basename $indir`
tar_file="$name.tar"
dir_exceptions='--exclude=".snakemake"'
if [ $compressed == 1 ]; then
	echo "Taring $indir"
	tar $dir_exceptions -cvvf $tar_file $indir
elif [ $compressed == 0 ]; then
	tar_file="$tar_file.gz"
	echo "Taring and compressing $indir"
	tar $dir_exceptions -cvvzf $tar_file $indir
else
	echo "Unexpected compressed flag ($compressed)"
	exit 2
fi


# Rclone to fraserdrive
# rclone sync --tpslimit 2 --transfers 1 $tar_file $gdrive:$gdrive_path --verbose

