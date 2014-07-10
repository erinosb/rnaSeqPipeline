rnaSeqPipeline
==============


autoAnalyzeRNAseq_v2.sh

This is a very basic RNA-seq pipeline I use for initial C. elegans miSeq and HiSeq data analysis.
Must be run within kure.
If running outside kure, update the locations for bowtie2 and 2bit files.

###PROGRAM
   autoAnalyzeRNAseq_v2.sh - To automate the analysis of RNA-seq data

###USAGE
   step1: load the following modules: tophat, samtools, bedtools, r, bowtie2, fastqc
   
   step2:
   bash autoAnalyzeRNAseq_v2.sh [options] \<inputFile.txt\> [inputFile2.txt] ... 

###ARGUMENTS
        --genome               Set the organism. Default is ce. Other options are mm.
        
        --cleanmode              At the end of the project, use this option to clean up the dataspace. This will remove the following files:
                                        \<name\>_cleanfile.fastq
                                        \<name\>.bed file
                                        bowtie left files
                                It will also zip the following files:
                                        \<name\>_quality.fastq
                                And it will create a final output directory and drop the following files there:
                                        \<name\>_quality_fastq.gz
                                        \<name\>.bam.gz
                                        \<name\>.wig.gz
        
        --maxmultihits          This is an option for calling within tophat. For more information, lookup max-multihits on tophat's manual webpage. Default is 20.
        --extension             This is the number of sequences to extend the .wig file. Should be equal to mean fragment length. Default is 100.
                                        
       \<inputFile.txt\>           This is the file from the sequencing facility. It is a fastq file containing Illumina sequencing reads generated from multiplexed samples
                                 It should be unmultiplexed and trimmed of any barcode indices.

###AUTHOR
   Erin Osborne Nishimura

###DATE
   February 28, 2014
   Updated from:  autoAnalyzeRNAseq_EON_V1.sh --> January 2 2014

###BUGS
  --> Module check is broken
  --> potential bug --- can we use zinba with the updated bowtie2 files? Need to test this.

###TO FIX
  --> Module check is broken
  --> set variables up top


###POTENTIAL FUTURE EXPANSION
  --> check whether the file is compressed. uncompress and re-compress. (or use zcat to uncompress)
  --> get and record versions of software
  --> paired end and single end compatible
  --> option to scale wigs
  --> set options to opt out of different parts of the pipeline, for example, opt out of the clean up process

###LOG
  140708 Allow user to select a different organism
