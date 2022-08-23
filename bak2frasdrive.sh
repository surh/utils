#!/usr/bin/env bash

indir=$1
gdrive="fraserlab_gdrive"
gdrive_path=""

if [[ $indir == "" ]]; then
	echo "No input directory specified"
	exit 1
fi

if [[ $gdrive_path == "" ]]; then
	id=`whoami`
	gdrive_path="backup/$id"
	echo "gdrive path not provided, using $gdrive_path"
fi

# First compress all files.
# Exceptions for allready compressed files & bam files
# When untaring and uncompressing, this will break links to compressed files
find $indir -type f ! -name "*.gz" ! -name "*.bam" ! -name "*.bz2" ! -name "*.zip" ! -path "*/.snakemake/*" -exec gzip {} \;

# Now create a tar file of compressed files
name=`basename $indir`
tar_file="$name.tar"
# echo $tar_file
#tar -cvvf $tar_file $indir
tar --exclude=".snakemake" -cvvf $tar_file $indir

# Rclone to fraserdrive
rclone sync --tpslimit 2 --transfers 1 $tar_file $gdrive:$gdrive_path --verbose


