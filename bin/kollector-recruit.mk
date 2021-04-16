#!/usr/bin/make -Rrf
ifdef profile
SHELL=/usr/bin/time -f '=> kollector-recruit.mk: %e %C' /bin/bash -o pipefail
else
SHELL=/bin/bash -o pipefail
endif

#------------------------------------------------------------
# params
#------------------------------------------------------------

# k-mer size
k?=25
# threads
j?=1
# max false positive rate permitted for Bloom filters
max_fpr?=0.001
# min match score when recruiting PET reads
r?=0.7
#min match score for filtering PET reads
s?=0.50
# expected number of Bloom filter elements
n?=10000

#------------------------------------------------------------
# meta rules
#------------------------------------------------------------

.PRECIOUS: $(name).bf
.DELETE_ON_ERROR:
.PHONY: check-params recruit

default: recruit

recruit: check-params $(name).recruited_pe.fastq

check-name-param:
ifndef name
	$(error missing required param 'name' (output file prefix))
endif

check-params: check-name-param
ifndef seed
	$(error missing required param 'seed' (FASTA file))
endif

# add pe1 pe2 check

#------------------------------------------------------------
# pipeline rules
#------------------------------------------------------------

# index FASTA file
%.fai: %
	samtools faidx $*

# iteratively add PETs with paired matches to Bloom filter
$(name)_BBT.bf: $(seed).fai  $(pe1) $(pe2)
	biobloommaker -i -k $k -p $(name)_BBT -f $(max_fpr) -t $j -n $n -r $r $(if $(subtract),-s $(subtract))  $(seed) <(zcat -f -- < $(pe1)) <(zcat -f -- < $(pe2))

#filter PET reads with built BF
$(name).recruited_pe.fastq: $(name)_BBT.bf $(pe1) $(pe2)
	biobloomcategorizer -p $(name)_BBT -t $j -d $(name)_BBT -f $(name)_BBT.bf -s $s -e -i <(zcat -f -- < $(pe1)) <(zcat -f -- < $(pe2)) >> $@
