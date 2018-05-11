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
    -r N      min match length for tagging  reads [0.7]
    -s N      min match length for recruiting reads [0.50]
    -k N      k-mer size for ABySS contig assembly [32]
    -K N      k-mer size for read overlap detection [25]
    -n N      max k-mers to recruit in total [10000]
    -o FILE   output file prefix ['kollector']
    -p FILE   Bloom filter containing repeat k-mers for
              exclusion from scoring calculations; must match
              k-mer size selected with -K opt [disabled]
    -max_iterations N  number of iterations to be performed [5]
    -decrement N       decrement of the r parameter in each iteration [0.1]
    -B N      pass bloom filter size to abyss 2.0.2 
              (B option, to be written: ex - 100M, optional)


HEREDOC

set -eu -o pipefail

#------------------------------------------------------------
# Parse command line opts
#------------------------------------------------------------

# default values for options
B=0
align=0
evaluate=0
j=1
k=32
K=25
r=0.7
s=0.5
o=kollector
n=10000
help=0
d=0.10
max_iterations=5
decrement=0.1

#parse command line options
while getopts B:A:d:eg:hH:Cj:k:K:r:s:m:n:o:p: opt; do
	case $opt in
		B) B=$OPTARG;;
		A) abyss_opt="$OPTARG";;
		C) clean=0;;
		d) decrement=$OPTARG;;
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
		n) n=$OPTARG;;
		o) o=$OPTARG;;
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
pet2=$1; shift

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export PATH=$DIR:$PATH

#symlink files
seed_symlink="${o}_reference.fa"
ln -s -f $seed $seed_symlink

for i in $(seq 1 $max_iterations) 
do
if [ "$i" = 1 ]
then
	echo "Iteration ${i}"
	prevr=$r
	mkdir -p iteration.$i
	cd iteration.$i
	if [ -z ${p+x} ]
	then
		if [ -z ${B+x} ]
		then
			kollector.sh -j$j -d$d -k$k -K$K -r$r -s$s -n$n -o$o ../$seed_symlink $pet1 $pet2
		else
			kollector.sh -j$j -d$d -k$k -K$K -r$r -s$s -n$n -o$o -B$B ../$seed_symlink $pet1 $pet2
		fi
	else
		if [ -z ${B+x} ]
		then
			kollector.sh -j$j -d$d -k$k -K$K -r$r -s$s -p$p -n$n -o$o ../$seed_symlink $pet1 $pet2
		else
			kollector.sh -j$j -d$d -k$k -K$K -r$r -s$s -p$p -n$n -o$o -B$B ../$seed_symlink $pet1 $pet2
		fi
	fi
	cut -f2 -d " " ${o}_hitlist.txt|sort|uniq > ${o}_succeedtranscripts.txt
	grep ">" ../$seed_symlink | sed 's/>//g' | sed 's/\s.*//g' > ${o}_alltranscripts.txt
	grep -w -v -f ${o}_succeedtranscripts.txt ${o}_alltranscripts.txt | xargs samtools faidx ../$seed_symlink > ${o}_failedtranscripts.fa
	cd ..
else
	echo "Iteration ${i}"
	newr=`echo $prevr-$decrement | bc -l`
	prevr=$newr
	previ=$(($i-1))
	mkdir -p iteration.$i
	cd iteration.$i
	cp -a ../iteration.$previ/${o}_failedtranscripts.fa ${o}_prevfailed.fa
	seed_new="$(pwd)"/${o}_prevfailed.fa
	if [ -z ${p+x} ]
	then
		if [ -z ${B+x} ]
		then
			kollector.sh -j$j -d$d -k$k -K$K -r$r -s$s -n$n -o$o $seed_new $pet1 $pet2
		else
			kollector.sh -j$j -d$d -k$k -K$K -r$r -s$s -n$n -o$o -B$B $seed_new $pet1 $pet2
		fi
	else
		if [ -z ${B+x} ]
		then
			kollector.sh -j$j -d$d -k$k -K$K -r$r -s$s -p$p -n$n -o$o $seed_new $pet1 $pet2
		else
			kollector.sh -j$j -d$d -k$k -K$K -r$r -s$s -p$p -n$n -o$o -B$B $seed_new $pet1 $pet2
		fi
	fi
	cut -f2 -d " " ${o}_hitlist.txt|sort|uniq > ${o}_succeedtranscripts.txt
	grep ">" ${o}_prevfailed.fa | sed 's/>//g' | sed 's/\s.*//g' > ${o}_alltranscripts.txt
	grep -w -v -f ${o}_succeedtranscripts.txt ${o}_alltranscripts.txt|xargs samtools faidx ${o}_prevfailed.fa > ${o}_failedtranscripts.fa
	cd ..
fi
done
