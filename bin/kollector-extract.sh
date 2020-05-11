#!/bin/bash 

#------------------------------------------------------------
# params
#------------------------------------------------------------

name=$1
contigs=$2
seed=$3
workdir=$4
j=$5


#------------------------------------------------------------
# alignment 
#------------------------------------------------------------

# build GMAP index for FASTA file
gmap_build -D $workdir -d $name.gmap $contigs

# align transcripts to the assemblies 
gmap -D $workdir -d $name.gmap -f samse -O -B 4 -t $j $seed  >> $name.transcript2assembly.sam 

awk '{ if ($2!=4) print $0;}' $name.transcript2assembly.sam >allmapped.sam

grep -v '^@' allmapped.sam > allcleanmapped.sam
rm allmapped.sam
cut -f1 allcleanmapped.sam|sort|uniq>allnames.txt
cut -f6 allcleanmapped.sam>allcigars.txt
cut -f10 allcleanmapped.sam>allseq.txt
paste allcigars.txt allseq.txt >allcigarseq.txt
rm allcigars.txt
rm allseq.txt

awk '
{
        n1 = n2 = n3 = 0
        a=$1
        while(match(a, "[0-9]+M") != 0){
                n1 += substr(a, RSTART, RLENGTH-1)
                a = substr(a, RSTART+RLENGTH)
        }
        a=$1
        while(match(a, "[0-9]+H") != 0){
                n3 += substr(a, RSTART, RLENGTH-1)
                a = substr(a, RSTART+RLENGTH)
        }
        n2 = length($2)
        print n1 / (n2 + n3)
}' <allcigarseq.txt >allcoverages.txt

paste allcoverages.txt allcleanmapped.sam > allcoveredmapped.sam
awk '{ if ($1>=0.90) print $2,$4;}' allcoveredmapped.sam > $1_hitlist.txt
rm allcoveredmapped.sam allcleanmapped.sam allcigarseq.txt allcoverages.txt allnames.txt
samtools faidx $contigs
cut -f2 -d " " $1_hitlist.txt|sort|uniq|xargs samtools faidx $contigs > $1_assembledtargets.fa


