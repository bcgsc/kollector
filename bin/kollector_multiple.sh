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
    -r N      min match length for tagging  reads [50]
    -s N      min match length for recruiting reads [0.50]
    -k N      k-mer size for ABySS contig assembly [50]
    -K N      k-mer size for read overlap detection [25]
    -n N      max k-mers to recruit in total [25000]
    -o FILE   output file prefix ['kollector']
    -p FILE   Bloom filter containing repeat k-mers for
              exclusion from scoring calculations; must match
              k-mer size selected with -K opt [disabled]
    -max_iterations N  number of iterations to be performed [5]
    -decrement N       decrement of the r parameter in each iteration [0.1]


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
decrement=10
max_iterations=5
# parse command line options
while getopts :aA:d:eg:hH:Cj:k:K:r:s:m:n:o:p: opt; do
	case $opt in
		a) align=1;;
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

for i in $(seq 1 $max_iterations)
do
if [ "$i" = 1 ]
then
prevr=$r
mkdir iteration.$i
cd iteration.$i
kollector.sh $seed $pet1 $pet2 j=$j k=$k K=$K r=$r s=$s p=$p max_kmers=$max_kmers p= prefix=$prefix
cut -f1 -d " " hitlist.txt|sort|uniq > succeedtranscripts.txt
grep ">" $seed | sed 's/>//g' >alltranscripts.txt
grep -w -v -f succeedtranscripts.txt alltranscripts.txt|xargs samtools faidx $seed > failedtranscripts.fa
cd ..
else
newr=$prevr-$decrement
prevr=$newr
previ=$i-1
mkdir iteration.$i
cd iteration.$i
cp ../iteration.$previ/failedtranscripts.fa >prevfailed.fa
samtools faidx prevfailed.fa
kollector.sh prevfailed.fa $pet1 $pet2 j=$j k=$k K=$K r=$newr s=$s p=$p max_kmers=$max_kmers prefix=$prefix
grep ">" prevfailed.fa | sed 's/>//g' >alltranscripts.txt
grep -w -v -f succeedtranscripts.txt alltranscripts.txt|xargs samtools faidx prevfailed.fa > failedtranscripts.fa
fi
done

