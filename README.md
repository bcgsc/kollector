#**Kollector**

**_de novo_ Targeted Gene Assembly**

Kollector is a targeted assembly tool using [BioBloom Tools](http://www.bcgsc.ca/platform/bioinfo/software/biobloomtools) and [ABySS](http://www.bcgsc.ca/platform/bioinfo/software/abyss).


###Installation

Kollector is implemented as a bash script and can be run directly from the downloaded github repo.

###Dependencies 

Kollector requires the following tools:

* [ABySS](http://www.bcgsc.ca/platform/bioinfo/software/abyss)(min v.1.5 )
* [BioBloomTools](http://www.bcgsc.ca/platform/bioinfo/software/biobloomtools)
* [GMAP/GSNAP](http://research-pub.gene.com/gmap)
* [BWA](http://bio-bwa.sourceforge.net)
* [Samtools](http://www.htslib.org/)

The binaries for the above tools are needed to be added to your path.The easiest way to install these tools is to install [Linuxbrew](http://linuxbrew.sh/) and add linuxbrew binary to your `PATH`:

```{r}
export PATH="$HOME/.linuxbrew/bin:$PATH"

```

Installing any package will be as easy as:

```{r}
brew install (package name)

```
For example to install ABySS run:

```{r}
brew install abyss

```

Also,the kollector bin directory needs to be added to your `PATH`:

```{r}
export export PATH="$HOME/kollector/bin:$PATH"

```
To see an simple example for running Kollector please see the `Example` section below.

## Running Kollector

Kollector consists of three bash scripts:

* `kollector-extract.sh`
* `kollector-recruit.sh`
* `kollector.sh`

`kollector.sh` is the main script.It calls `kollector-recruit.sh` to recruit PET reads,invokes ABySS to perform contig assembly and calls `kollector-extract.sh` to extract assembled targets and finally aligns input transcripts to the assembly with GMAP.

To run Kollector simply run :

`./Kollector.sh <params> <seed.fa> <read1.fa> <read2.fa>`


The parameters options are as following:

```{r} 
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
```


 `<seed.fa>` is the input transcript sequence in a form of FASTA file to recruit reads.
 
 `<read1.fa>` and `<read2.fa>` are the PET sequencing reads and could be in a form of FASTA/FASTQ files.
All the input files could be gzipped.

### Example : Testing Kollector with C.elegans dataset

The `test` folder contains a `Makefile` that runs kollector on C.elegans data set.
The test target  C. elegans transcript C17E4.10 FASTA file (Acession NM_060106.6, RefSeq mRNA sequences longer than 1 kb) is provided in `data` folder.
To run Kollector on C.elegans data set simply run `make` in the test folder. Make sure `linuxbrew` and kollector `bin` directory is on your `PATH` as mentioned in the in `Dependancies` section.

The `Makefile` installs `samtools`,  `biobloomtools`,`abyss`,`gmap-gsnap` and `bwa` via `linuxbrew`.
Then,it downloads WGS read pairs FASTQ.gz files (SRA Accession: DRR008444,read length:110pb, total number of base pairs:7.5G and 75x raw coverage) to the data folder.
Finally, it runs kollector pipeline with the default parameters mentioned above. The output of kollector is assembledtargets.fa file. 

