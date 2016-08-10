# kollector
de novo targeted gene assembly
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
