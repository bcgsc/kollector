# run kollector on a test c.elegans data

# Kollector parameters
j=8
r=0.7
s=0.5
k=32
K=25
n=10000
o=test-kollector

# Report Run time and memory usage

export SHELL=zsh -opipefail
export REPORTTIME=1
export TIMEFMT=%J  %U user %S system %P cpu %*E total %M MB

#Path to Kollector executables

kollector_bin=../bin

#Path to reference transcriptom and genomic reads test data
data:=../data
 
.DELETE_ON_ERROR:
.SECONDARY:

all: DRR008444_1.fastq.gz DRR008444_2.fastq.gz assembledtargets.fa celegans-kollector.log

clean:
	rm test-kollector.bf test-kollector.txt test-kollector.peak-mem-mb.txt test-kollector.recruited_pe.fastq test-kollector.transcript2assembly.sam hitlist.txt _summary.tsv assembledtargets.fa 

curl: \
	DRR008444_1.fastq.gz \
	DRR008444_2.fatsq.gz

# Install Dependencies

brew_deps= samtools biobloomtools abyss gmap-gsnap bwa

# check if not windows
ifneq ($(OS),Windows_NT)
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Darwin)
    brew_deps += gnu-time gawk coreutils
  endif
endif

deps:
	@echo $(brew_deps)

install-deps:
	brew tap brewsci/bio
	brew install $(brew_deps)

#Download genomic reads from NCBI
 
DRR008444_1.fastq.gz:
	curl -o $(data)/DRR008444_1.fastq.gz ftp://ftp.sra.ebi.ac.uk/vol1/fastq/DRR008/DRR008444/DRR008444_1.fastq.gz
DRR008444_2.fastq.gz:
	curl -o $(data)/DRR008444_2.fastq.gz ftp://ftp.sra.ebi.ac.uk/vol1/fastq/DRR008/DRR008444/DRR008444_2.fastq.gz

#Run kollector.sh
assembledtargets.fa:
	$(kollector_bin)/kollector.sh -j$j -r$r -s$s -k$k -K$K -n$n -o$o $(data)/c17e4-10.fa $(data)/DRR008444_1.fastq.gz $(data)/DRR008444_2.fastq.gz 2>&1 | tee celegans-kollector.log

	@echo 'Testing Kollector completed.' 


