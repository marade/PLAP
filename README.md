![alt text](https://github.com/marade/PLAP/blob/master/PLAP_logo.png "PLAP")
# PLAP
PLAP is the Population Level Allele Profiler. It is a Python program designed to help assess presence and depth of alleles in pooled Illumina amplicon sequencing experiments for known loci schemes, such as in MLST.

While other software packages exist that can help gain insight into these kinds of experiments, such as SRST2, Torsten Seemann's MLST, SKA, and MentaLiST, these are mostly geared towards profiling sets of single alleles and not multi-allelic populations. DADA2 is a notable exception, and we found it performed fairly well for populations when there was no tagmentation in the Illumina prep and/or loci were <500bp. Our experiments did use tagmentation, and we found that other methods were required to obtain accurate results. 

The PLAP methodology can be summarized as follows:

1. Do adapter and read trimming with Trim Galore.
2. Do a quick and rough assessment of allele presence with KMA.
3. Test and refine the KMA allele calls through WGS-style alignments
with Minimap2 and filter using various thresholds (see below for details).

We ran PLAP using the following software, though other versions may work equally well:

* Red Hat Linux 7.5 or Ubuntu 18.04
* Python 2.7.5
* KMA 1.1.7 [https://bitbucket.org/genomicepidemiology/kma](https://bitbucket.org/genomicepidemiology/kma)

		git clone https://bitbucket.org/genomicepidemiology/kma.git
		cd kma/
		# because `kma index...` still does not work in newer versions...
		git checkout 1.1.7
		make -j$(nproc)
		sudo cp kma* /usr/local/bin/
		
* Minimap2 2.14 [https://github.com/lh3/minimap2](https://github.com/lh3/minimap2)

		git clone https://github.com/lh3/minimap2
		cd minimap2 && make -j$(nproc)
		sudo mv minimap2 /usr/local/bin/
		sudo chmod 755 /usr/local/bin/minimap2

* SAMTools 1.8 [http://www.htslib.org/](http://www.htslib.org/)

		sudo apt-get install samtools

* BAMTools 2.5.1 [https://github.com/pezmaster31/bamtools](https://github.com/pezmaster31/bamtools)

		git clone git://github.com/pezmaster31/bamtools.git
		cd bamtools/
		mkdir build
		cd build/
		cmake ..
		make
		sudo make install

* BioPython 1.72 [https://biopython.org](https://biopython.org)

		sudo pip install biopython

* Python natsort 6.0.0 [https://pypi.org/project/natsort](https://pypi.org/project/natsort)

		sudo pip install natsort

* Trim Galore 0.6.1 [https://github.com/FelixKrueger/TrimGalore](https://github.com/FelixKrueger/TrimGalore)

		wget https://github.com/FelixKrueger/TrimGalore/archive/0.6.1.tar.gz
		tar xzvf 0.6.1.tar.gz
		sudo cp TrimGalore-0.6.1/trim_galore /usr/local/bin/

* Cutadapt 1.18 [https://github.com/marcelm/cutadapt/](https://github.com/marcelm/cutadapt/)

		sudo pip install cutadapt

* PySAM 0.15.1 [https://pysam.readthedocs.io](https://pysam.readthedocs.io)

		sudo pip install pysam

If you have root access on an Ubuntu machine you can use the ubuntu-prereqs.sh script to install the prequisites:

		bash ubuntu-prereqs.sh

Please be sure all of the above are installed before attempting to run PLAP, and additionally check that executable files for the applications are available through the current user's path.

PLAP requires as input a directory containing untrimmed paired end Fastq files, and another directory containing the reference alleles in Fasta format. Note: the Fastq files should be named with no underscores except the terminal "_1" or "_2", e.g. MyNameHere_1.fastq.gz and MyNameHere_2.fastq.gz.

## Installation

A typical install (including prerequisites) and run of PLAP on Ubuntu might go as follows:

	git clone https://github.com/marade/PLAP.git
	bash PLAP/ubuntu-prereqs.sh
	python3 PLAP/PLAP PLAP/example-reads PLAP/example-ref my-output-dir

A database of alleles for your gene(s), provided in Fasta files located in the "ref-dir" in the command above, is also needed. We have provided our database of fumC and fimH E. coli alleles here. To use these, move them to your own reference directory.

Be warned that PLAP is under active development and testing, and therefore it may have serious bugs or otherwise be unsuitable for production work.

## Quick Start
Note: please see 'Guidelines' for our recommendations on experimental design.

After installation, create folders for the fastq data and the allele database. Make sure that your fastq file names are in proper format (see above). The allele database folder should contain a .fa or .fasta file(s) formatted in the following way:

	>genE_1
	AAAAAAGGGGGGGTTTTTTTCCCCCCC
	>genE_2
	AAAAAAGGGGGGGTTTTTTTCCCGCCC

PLAP is then ready to run. The command may look as follows:

	./PLAP in_dir db_dir out_dir [parameters]

For a description of all parameters avaliable for modification:

	./PLAP --help

While PLAP runs, it will update you on candidate alleles for eachsample, starting with the coverage evaluation filter (see Detailed Overview). If an allele does not pass a filter, this information will be reported in real time. After PLAP completes, the output directory will contain a results.tab file, which will list the following for all samples and alleles:

	Sample_name	allele_#	prevalence(%)

Note: prevalences are approximate.

PLAP will also issue a warning for samples with overtagmentation i.e. samples where over 50% of reads are under 100bp long. We have found that in such cases your prevalences as recorded in the results.tab file may not be accurately predicted by PLAP and need to be verified manually. See the Detailed Overview for how to do this.

The rejects.tab file will contain all alleles rejected for your samples and the filter at which they were rejected.

The nov_out directory within the output directory will contain tab-delimited files for each sample-gene combination. Check these files for uncalled bases indicating the presence of novel allele(s) or allele(s) that are present but did not survive filtering. Note: if you have uncalled bases for your sample, your prevalences as recorded in the results.tab file may not be accurate and will need to be recalculated. See the Detailed Overview for further information.

When a PLAP run is completed, the 'done' directory will have a file for each sample. If you wish to rerun analysis on one or more samples, delete this file before running PLAP again.

If you find that PLAP is filtering out all candidate alleles, parameter adjustment is likely necessary. We recommend looking at the rejects file and seeing where the majority of alleles fall out. Parameters that are most likely to need lowering include:

	-y	--spandiff	specifies the max coverage difference for alleles with similar coverage pattern/span (default 50)
	-s	--minstartcov	specifies the minimum starting coverage	for windowed coverage (default 160)

Parameters that may need to be higher include:

	-d	--maxavgdev	specifies the maximum average deviation cutoff (default 1200)
	-c	--minalleles	specifies the minimum number of alleles to trigger a second windowed coverage evaluation (default 4)
	-l	--maxloss	specifies the maximum fraction of coverage loss for second windowed coverage (default 0.6)

If you find that PLAP is calling many alleles per gene (>5), reverse  adjustments may be necessary. See Detailed Overview for a short list of controls that would be useful for optimizing parameters for your experiment.

## Detailed Overview

### Guidelines
For the best results, we highly recommend the following:

* A target sequencing read length of at least approximately 250bp
* A set of control samples consisting of mixes of at least 2 verified sequence types at various known ratios
	ex: E. coli ST131:ST101 at ratios of 1:1, 1:10, 1:100, and 1:1000
* A set of control natural samples which have been extensively typed using conventional MLST or other single-colony typing
	preferably with varying ratios
	ex: a set of 3 fecal samples which are known to be approximately 
		95% ST131 and 5% ST101
		70% ST131 and 30% ST95
		50% ST88  and 50% ST399

Artificial control mixes do not need to be involved in every run, but one per experiment is advised.
Control natural samples may not be necessary in every run, but is ideal as a check to make sure your run has no issues.

Note: PLAP was developed using target read lengths of 250+bp. While it may work for a 100-200bp read target with modification, we have not tested its accuracy with this kind of data. Additionally, our defaults are geared towards fumC/fimH typing of Escherichia coli. If you have a another MLST-like method, or a different organism, significant calibration may be necessary.

### Trim Galore

Trim Galore does adapter and quality score trimming.

* Output: a *.fq.gz file with “_va_1.fq.gz”/”_val_2.fq.gz” appended to the sample name

		-t	--tgqual	specifies the minimum quality score (default 20)
	
### KMA

KMA does initial allele calling using k-mer matching between the allele database and the sample. We include all parameters available to change in KMA for optimization of the process. 

* Output: KMA database, standard KMA output files per sample including .aln, .fsa, and .res files containing candidate alleles and scores.

		-k 	--klen		specifies the K-mer length for the KMA databases (default 47)
		-m 	--minphred	specifies the minimum Phred score (default 30)
		-I 	--identity	specifies the minimum identity (default 99.99)
		-a	--minascore	specifies the minimum alignment score (default 0.9999)
		-r	--reward	specifies the reward score for matching	(default 1)
		-p	--penalty	specifies the mismatch penalty (default -2)
		-o	--openalty	specifies the gap open penalty (default -3)
		-e	--epenalty	specifies the gap extend penalty (default 20)

## Coverage evaluation

Many false alleles in the KMA output will appear because they are similar to alleles truly existing in the sample. Some of these false positives will have bases unique to the allele. Coverage of these bases will drop below the error threshold if the allele is a false positive. For the purpose of removing these alleles, we have used Minimap2 to align all reads to each individual candidate allele, the output of which is used to detect bases below the error threshold. Control samples are advised to determine the error threshold for your experiment.

* Output: .fa files of all candidate alleles, a tab-delimited file of coverage per position per base for every allele and sample.

		-q	--slurpqual	specifies the minimum quality score used when slurping Minimap2 BAM coverage data (default 20)
		-x	--btnm		specifies the number of mismatches a read must have less than for the BAMTools analysis (default 1)
		--btmp			specifies the map quality each read must exceed for the BAMTools analysis (default 59)
		--stq			specifies the quality theshold for SAMTools depth calculation (default 30)
		-f	--freqthresh	specifies the frequency threshold for coverage evaluation (default 0.008)

Further detection of false positives is usually necessary, since not all false positives will have unique bases. For example:

	True allele 1 AAAAAAGAGGGCTTTTTTTTTTTTTGGGGGAAAAAAAAAAAAAAAAA
	
	False allele  AAAAAAGAGGGCTTTTTTATTTTTTGGGGGAAAAAAATAAAAAAAAA
	
	True allele 2 AGAAAAGGGGGCTTTTTTATTTTTTGGGGGAAAAAAATAAAAAAAAA
	               ^     ^          ^                  ^

To detect these, we must evaluate the coverage of an allele for presence of combinations of distinguishing bases. For this, we use reads that exactly match the allele sequence for a moving window of 10bp (scaled to max read length). We have also used a fraction of the allele length due to high similarity towards the end of fumC and fimH alleles that caused jumps in coverage across all alleles and made discrimination between true and false positives difficult. Control samples are advised to determine if this is an issue for your experiment.

* Output: a tab-delimited file for each allele, that contains start position for each window and coverage at this position.

		-z	--rldiv		specifies the divisor used to determine the reference length minimum (default 2.5)
		-g	--offset	specifies the position offset to use when doing the windowed coverage evaluation (default 30)
		-b	--reaffract	specifies the fraction of the reference length, beyond which we do not use values for average deviation (default 0.68)
		-w	--winlen	specifies the window length to use (default 10)

### False positives	

False positives frequently show the following characteristics:

* Low initial coverage – For fumC especially, the beginning of the allele can be highly differentiating, so false positives will start out with poor coverage as there are few exact matches of adequate length. Filtering for this saves time in later filters.

		-s	--minstartcov	specifies the minimum starting coverage (default 160)

* Volatility of coverage across the allele – for false positives that are “hybrids” of two or more true alleles of differing frequency, coverage will sharply increase and/or decrease as the window moves down the allele. The proxy metric that we use for measuring this volatility is average deviation from the mean coverage.

		-d	--maxavgdev	specifies the maximum deviation cutoff
						(default 1200)

* Mirroring of true alleles in coverage – for some false positives, due to high similarity to a single true allele, the pattern of coverage across the allele will largely copy the coverage pattern of the true allele. These can be removed by detecting the similarity and determining which allele has an overall more stable coverage pattern. We by default define ‘similarity’ as two alleles having coverages within 50X of each other for a span of 20bp or more.

		-y	--spandiff	specifies the coverage difference (default 50)
		-j	--spanlen	specifies the length of the span (default 20)

* Significant loss of coverage after length adjustment – for some samples, similarity between false and true alleles may result in many false positives that survive previous filtering. In these cases, a second windowed coverage filter may be necessary. This second filter is more stringent in read length (scaled to max read length) and should produce a lower coverage. However, since longer reads group more bases together and therefore are more discriminatory, false positives lose significantly more coverage than true alleles when compared to the first windowed coverage filter. Note: some alleles (ex. fimH-86) appear to be more susceptible to tagmentation and may skew towards shorter reads as a result, causing these alleles to be erroneously removed. Such alleles may be rescued manually (see below).

		-c	--minalleles	specifies the minimum number of alleles to trigger a second windowed coverage evaluation (default 4)
		-u	--srldiv	specifies the divisor used to determine the reference length minimum (default 1.5)
		-l	--maxloss	specifies the maximum fraction of coverage loss	(default 0.6)

### Novel allele detection

Once all true alleles have been detected, we can look for potential novel alleles by detecting bases above a certain frequency that are not described by the set of alleles that survived filtering. Note: some samples may have alleles that truly exist in the sample but do not survive filtering due to very low frequency, atypical coverage pattern, selective overtagmentation, presence alongside a highly similar allele, etc. These may be ‘revived’ using this detector. Construction of novel alleles and/or rescue of lost true alleles must be done by aligning alleles detected in the sample, manually amending sequences to include 'novel' bases, and searching available allele databases for the created allele(s).

If novel or rescued alleles are present, the prevalences called automatically by PLAP need to be recalculated: determine if there is any overlap in bases between the novel/rescued allele and a successfully called minor allele, then determine the approximate prevalence of the novel/rescued allele by averaging frequency of uncalled bases (use Minimap2 output to calculate frequencies) and subtract this prevalence from the prevalence of the overlapping allele. If no overlapping minor allele is present, subtract this prevalence from that of the most prevalent allele.

* Output: a tab-delimited file with every position and base detected 

		--ucmfreq	specifies the minimum frequency for an uncalled base to pass the filter (default 0.008)
	
### Prevalence calculation

Allele prevalence is calculated in the following way: 

* For every allele, coverage at all distinguishing positions is extracted from the first windowed coverage filter output
* The minimum of these coverage counts is determined for each allele
* Total of all minimum coverages for a gene is determined
* Allele prevalence is expressed as % of this total using the allele's minimum coverage

#### Manual prevalence calculation

If a sample is overtagmented, predicted prevalences for all alleles should be verified manually. Do this by finding at least one base unique to each called allele (you can use the MAFFT fodler output to do this) and determining the prevalence of that base in the sample using the output from Minimap2. If there is one or more alleles that do not have a unique base, we recommend using the prevalences of several bases to infer allele prevalence similarly to the following:
	
	Allele(s)  position     base      prevalence
	  1 & 3       51          A            80%
	    2         51          G            20%
	    1        108          T            75%
	  2 & 3      108          A            25%
	
	Allele 1	75%
	Allele 2	20%
	Allele 3	 5%

## Rerunning PLAP

If you wish to rerun PLAP from a particular point or for particular sample(s) you may do so. PLAP will check for existing trimmed reads, KMA results, BAMtools results, Minimap2 results, and moving window coverage counts, so if you wish to for example redo analysis from the Minimap2 step, you should delete or move files/directories from Minimap2 onwards. PLAP will use the existing trimmed-read/KMA/etc files for the analysis. However, if PLAP has completed and you want to rerun it, you will need to delete the sample(s) files from the 'done' directory first.

### Citations

PLAP is currently unpublished, but a manuscript has been submitted, so for now please cite this way:

	Escherichia coli clonobiome: assessing the strains diversity in feces and urine by deep amplicon sequencing.
	Shevchenko, Radey, Tchesnokova, Sokurenko 2019

Logo is by Hatchful (Spotify)
