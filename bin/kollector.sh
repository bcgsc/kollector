#!/bin/bash

#------------------------------------------------------------
# Usage
#------------------------------------------------------------

PROGRAM=$(basename $0)
read -r -d '' USAGE <<HEREDOC
Usage: $PROGRAM [options] <seed> <pet_read1.fq> <pet_read2.fq> 

Description:

Do a targeted assembly  using ABySS. The input files are  
PET sequencing reads which must be a FASTA/FASTQ pair and a 
seed sequence FASTA file to recruit reads. The input files may be gzipped.


AbySS(1.5+),BioBloom Tools and GMAP should be in your path.

Options:
    
    -h        show this help message
    -j N      threads [1]
    -r N      min match length for tagging reads. Decimal value are
              the proportion of the valid k-mers and integer values
              will require that minimum number of bases to match [0.7]
    -s N      min match length for recruiting reads [0.50]
    -k N      k-mer size for ABySS contig assembly [32]
    -K N      k-mer size for read overlap detection [25]
    -n N      max k-mers to recruit in total [10000]
    -o FILE   output file prefix ['kollector']
    -p FILE   Bloom filter containing repeat k-mers for
              exclusion from scoring calculations; must match
              k-mer size selected with -K opt [disabled]
    -B N      pass bloom filter size to abyss 2.0.2 
              (B option, to be written: ex - 100M, optional)

HEREDOC

set -eu -o pipefail

#------------------------------------------------------------
# Parse command line opts
#------------------------------------------------------------

# default values for options
align=0
evaluate=0
j=1
k=32
K=25
r=0.7
s=0.50
prefix=kollector
max_kmers=10000
help=0

# parse command line options
while getopts A:B:d:eg:hH:Cj:k:K:r:s:m:n:o:p: opt; do
	case $opt in
		A) abyss_opt="$OPTARG";;
		B) B=$OPTARG;;
		C) clean=0;;
		d) mpet_dist=$OPTARG;;
		e) evaluate=1;;
		g) ref=$OPTARG;;
		h) help=1;;
		H) num_hash=$OPTARG;;
		j) j=$OPTARG;;
		k) k=$OPTARG;;
		K) K=$OPTARG;;
		r) r=$OPTARG;;
		s) s=$OPTARG;;
		m) max_iterations=$OPTARG;;
		n) max_kmers=$OPTARG;;
		o) prefix=$OPTARG;;
		p) p=$OPTARG;;
		
		\?) echo "$PROGRAM: invalid option: $OPTARG"; exit 1;;
	esac
done
shift $((OPTIND-1))

# -h for help message
if [ $help -ne 0 ]; then
	echo "$USAGE"
	exit 0;
fi

# we expect 3 file arguments
if [ $# -lt 3  ]; then
    echo "Error: number of file args must be  3" >&2
	echo "$USAGE" >&2
	exit 1
fi

seed=$1; shift;
pet1=$1; shift;
pet2=$1; shift;

# Support for MacOS: 
#   - BSD's time command does not have the format option
#   - there is no `free` program for checking the swap space
#   - `du` is also different on Darwin
# If `uname -a` indicates Darwin, set programs that work for MacOS
timer="/usr/bin/time"
du="du"
free='free -m | awk '"'"'NR==3{print $3}'"'"

OS=$(uname -s)
if [ "$OS" == "Darwin" ] ; then
  echo Found MacOS
  timer="gtime"
  du="gdu"
  free='sysctl vm.swapusage | gawk '"'"'match($0, /used = ([0-9]+)\.[0-9]+[GMBK]/,m) {print m[1]}'"'"
fi

#------------------------------------------------------------
# Helper functions
#------------------------------------------------------------

# print progress message
function heading() {
	echo '-----------------------------------------'
	echo -e "$@"
	echo '-----------------------------------------'
}

# track peak disk space usage
function update_peak_disk_usage() {
	disk_usage=$($du -sb | cut -f1)
	if [ $disk_usage -gt $peak_disk_usage ]; then
		peak_disk_usage=$disk_usage
	fi
}

# log mem usage in background (in megabytes)
function start_mem_logging() {
	peak_mem_file=$prefix.peak-mem-mb.txt
	rm -f $peak_mem_file
	(
    base_mem=$(eval $free)
		peak_mem=$base_mem
		trap 'echo $(($peak_mem - $base_mem)) > $peak_mem_file; exit $?' \
			EXIT INT TERM KILL
		while true; do
      mem=$(eval $free)
			if [ $mem -gt $peak_mem ]; then peak_mem=$mem; fi
			sleep 1
		done
	) &
	mem_logger_pid=$!
	trap "kill $mem_logger_pid; exit $?" INT TERM KILL
}

# stop logging mem usage in background
function stop_mem_logging() {
	kill $mem_logger_pid
	wait $mem_logger_pid
}

# log the real elapsed time for a command
function time_command() {
	script_name=$(basename $0)
	$timer -f "=> $script_name: %e %C" "$@"
}

#------------------------------------------------------------
# Start up
#------------------------------------------------------------

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export PATH=$DIR:$PATH

heading "Recruiting a maximum of $max_kmers k-mers"
start_time=$(date +%s)
peak_disk_usage=0
start_mem_logging

#symlink files
seed_symlink="${prefix}_reference.fa"
ln -s -f $seed $seed_symlink

#------------------------------------------------------------
# Recruit PET reads
#------------------------------------------------------------
echo $pet1 
echo $pet2
time_command kollector-recruit.mk name=$prefix seed=$seed_symlink pe1="$pet1" pe2="$pet2" s=$s r=$r n=$max_kmers j=$j k=$K ${p+subtract=$p} 

update_peak_disk_usage



#------------------------------------------------------------
# Contig assembly with ABySS
#------------------------------------------------------------

heading "Running ABySS assembly..."


# run ABySS
abyss_dir=$prefix.abyss
abyss_input=../$prefix.recruited_pe.fastq
mkdir -p $abyss_dir
if [ -z ${B+x} ]
then
	time_command abyss-pe -C $abyss_dir v=-v k=$k name=$prefix np=$j  lib='pet' pet=$abyss_input long='longlib' longlib=../$seed_symlink
else
	time_command abyss-pe -C $abyss_dir v=-v k=$k name=$prefix np=$j  lib='pet' pet=$abyss_input long='longlib' longlib=../$seed_symlink B=$B H=4 kc=3
fi
abyss_fa=$abyss_dir/$prefix-10.fa

update_peak_disk_usage

#------------------------------------------------------------
# Extract successfully assembled targets
#------------------------------------------------------------

heading "Extracting successfully assembled targets from ABySS contigs..."

time_command kollector-extract.sh $prefix $abyss_fa $seed $abyss_dir $j 

update_peak_disk_usage


stop_mem_logging
