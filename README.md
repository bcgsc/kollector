#**Kollector**

**_de novo_ Targeted Gene Assembly**

Kollector is a targeted assembly tool using [BioBloom Tools](http://www.bcgsc.ca/platform/bioinfo/software/biobloomtools) and [ABySS](http://www.bcgsc.ca/platform/bioinfo/software/abyss).


###Installation

Kollector is implemented as a bash script and can be run directly from the downloaded github repo.

###Dependencies 

Kollector requires the following tools:

* [AbySS](http://www.bcgsc.ca/platform/bioinfo/software/abyss)(min v.1.5 )
* [BioBloomTools](http://www.bcgsc.ca/platform/bioinfo/software/biobloomtools)
* [BWA](http://bio-bwa.sourceforge.net)
* [GMAP/GSNAP](http://research-pub.gene.com/gmap)

The binaries for the above tools are needed to be added to your path. Also,the directory bin needs to be added to your path.

Kollector consists of three bash scripts:

* `kollector-extract.sh`
* `kollector-recruit.sh`
* `kollector.sh`

`kollecto.sh` is the main script.It calls `kollector-recruit.sh` to recruit PET reads,invokes ABySS to perform contig assembly and calls `kollector-extract.sh` to extract assembled targets.

To run Kollector simply run :

`./Kollector.sh <params> <seed.fa> <read1.fa> <read2.fa>`


The parameters options are as following:

```{r} 
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
```


 `<seed.fa>` is the input transcript sequence in a form of FASTA file to recruit reads.
 
 `<read1.fa>` and `<read2.fa>` are the PET sequencing reads and could be in a form of FASTA/FASTQ files.
All the input files could be gzipped.

