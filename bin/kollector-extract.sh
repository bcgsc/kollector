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
while read name 
do
num1=$(echo $name|cut -f1 -d " "|grep -o "[0-9]*M"|grep -o "[0-9]*"|xargs | tr ' ' + | bc)
num2=$(echo $name|cut -f2 -d " "|wc -c)
num3=$(echo $name|cut -f1 -d " "|grep -o "[0-9]*H"|grep -o "[0-9]*"|xargs | tr ' ' + | bc)
if [ -z $num3 ];then num3=0;fi
num4=$(echo "$num3+$num2"|bc)
echo "scale=2;$num1/$num4"|bc
done<allcigarseq.txt>allcoverages.txt
paste allcoverages.txt allcleanmapped.sam > allcoveredmapped.sam
awk '{ if ($1>=0.90) print $2,$4;}' allcoveredmapped.sam > $1_hitlist.txt
rm allcoveredmapped.sam allcleanmapped.sam allcigarseq.txt allcoverages.txt allnames.txt
samtools faidx $contigs
cut -f2 -d " " $1_hitlist.txt|sort|uniq|xargs samtools faidx $contigs > $1_assembledtargets.fa


