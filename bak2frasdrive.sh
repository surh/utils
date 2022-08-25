#!/usr/bin/env bash
set -x # For debugging

usage(){
cat << EOU
Usage: bak2frasdrive.sh -d directory [-g <gdrive> -p <path in gdrive> ... ]

REQUIRED:
	-d	Directory to be [compressed], tared, and uploaded to the drive.
		NOTE: tar always ignores and excludes .snakemake directories.

OPTIONAL:
	-g	Name of the remote from rclone. Tested only on gdrives but
		in principle should work with any remote. [fraserlab_gdrive]
	-p	Path in the remote to store tar file. If the path does not
			exist it will be created. [backup/$(whoami)]
	-b	Flag to indicate if compression should be done (with gzip)
		*B*EFORE taring. NOTE: This will actually modify the files
		in the local directory by compressing them. It can be more
		efficient but it could break things that rely on specific
		filenames. Compression will ignore BAM (.bam) files and files
		already compressed (.gz, .zip, .bz2). [false]
	-o	By default, rclone is set to not replace files with a newer
		timestamp in the remote (option --update). Using this flag
		will remove that option and *O*VERWRITE any file with the
		same name in the remote. [false]

For any suggestions raise an issue at https://github.com/surh/utils/issues
EOU
}

# Read options
pre_compress=false
overwrite=false
while getopts d:g:p:b:o flag
do
	case "${flag}" in
		d) indir=${OPTARG};;
		g) gdrive=${OPTARG};;
		p) gdrive_path=${OPTARG};;
		b) pre_compress=true;;
		o) overwrite=true;;

		*) usage
		   exit 0;;
	esac
done

# Check options and set defaults
if [[ $indir == "" ]]; then
	echo "No input directory specified"
	usage
	exit 0
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

# Check rclone
if [ ! $(type -P rclone) ]; then
	echo "rclone executable not found"
	exit 3
else
	# echo "Checking remotes"
	remotelist=`rclone listremotes`
	remote_found=0
	for remote in $remotelist; do
		if [[ $remote == "$gdrive:" ]]; then
			remote_found=1
			break
		fi
	done

	if [ $remote_found == 0 ]; then
		echo "The specified gdrive ($gdrive) was not found"
		exit 4
	fi
fi

# First compress all files.
compressed=0
if [[ "$pre_compress" == "true" ]]; then
	cmd_pars=("-type" "f")

	# Add file extension exceptions
	file_exceptions=('.gz' '.bz2' '.zip' '.bam')
	for exception in ${file_exceptions[@]}; do
		cmd_pars[${#cmd_pars[@]}]="-not"
		cmd_pars[${#cmd_pars[@]}]="-name"
		cmd_pars[${#cmd_pars[@]}]="*$exception"
	done


	# Add dir exceptions
	dir_exceptions=('.snakemake')
	for exception in ${dir_exceptions[@]}; do
		cmd_pars[${#cmd_pars[@]}]="-not"
		cmd_pars[${#cmd_pars[@]}]="-path"
		cmd_pars[${#cmd_pars[@]}]="*/$exception/*"
	done

	echo ">find $indir -type f ${cmd_pars[@]} -exec gzip {} \;"
	find $indir -type f "${cmd_pars[@]}" -exec gzip {} \;
	compressed=1
fi

# Create tar file
## Build name for tar file
name=`basename $indir`
tar_file="$name.tar"
## Exclude .snakemake
dir_exceptions="--exclude=.snakemake"
if [ $compressed == 1 ]; then
	echo "Taring $indir"
	echo ">tar $dir_exceptions -cvvf $tar_file $indir"
	tar $dir_exceptions -cvvf $tar_file $indir
elif [ $compressed == 0 ]; then
	tar_file="$tar_file.gz"
	echo "Taring and compressing $indir"
	echo ">tar $dir_exceptions -cvvzf $tar_file $indir"
	tar $dir_exceptions -cvvzf $tar_file $indir
	compressed=1
else
	echo "Unexpected compressed flag ($compressed)"
	exit 2
fi

# Rclone to gdrive
## Set update option
if [[ "$overwrite" == "true" ]]; then
	update_opt="--update"
	echo "Hola"
else
	update_opt=""
	echo "Adios"
fi
echo "Uploading to gdrive with rclone"
echo ">rclone sync --tpslimit 2 --transfers 1 $tar_file $gdrive:$gdrive_path --verbose $update_opt"
rclone sync --tpslimit 2 --transfers 1 $tar_file $gdrive:$gdrive_path --verbose $update_opt
