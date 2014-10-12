#! /bin/sh/

################################################
##autoAnalyzeRNAseq_v2.sh
#
#This is a very basic RNA-seq pipeline I use for initial C. elegans miSeq and HiSeq data analysis.
#Must be run within kure.
#If running outside kure, update the locations for bowtie2 and 2bit files.
#
####PROGRAM
#   autoAnalyzeRNAseq_v2.sh - To automate the analysis of RNA-seq data
#
####USAGE
#   step1: load the following modules: tophat, samtools, bedtools, r, bowtie2, fastqc
#   
#   step2:
#   bash autoAnalyzeRNAseq_v2.sh [options] <inputFile.txt> [inputFile2.txt] ... 
#
#ARGUMENTS
       # --genome               Set the organism. Default is ce. Other options are mm.
       # 
       # --cleanmode              At the end of the project, use this option to clean up the dataspace. This will remove the following files:
       #                                 <name>_cleanfile.fastq
       #                                 <name>.bed file
       #                                 bowtie left files
       #                         It will also zip the following files:
       #                                 <name>_quality.fastq
       #                         And it will create a final output directory and drop the following files there:
       #                                 <name_quality_fastq.gz
       #                                 <name>.bam.gz
       #                                 <name>.wig.gz
       # 
       # --maxmultihits          This is an option for calling within tophat. For more information, lookup max-multihits on tophat's manual webpage. Default is 20.
       # --extension             This is the number of sequences to extend the .wig file. Should be equal to mean fragment length. Default is 100.
       #                                 
       #<inputFile.txt>           This is the file from the sequencing facility. It is a fastq file containing Illumina sequencing reads generated from multiplexed samples
       #                          It should be unmultiplexed and trimmed of any barcode indices.
       #                          
#OPTIONS
#   
#AUTHOR
#   Erin Osborne Nishimura
#
#DATE
#   February 28, 2014
#   Updated from:  autoAnalyzeRNAseq_EON_V1.sh --> January 2 2014
#
#BUGS
#  --> Module check is broken
#  --> potential bug --- can we use zinba with the updated bowtie2 files? Need to test this.
#
#TO FIX
#  --> Module check is broken
#  --> set variables up top
#
#
#POTENTIAL FUTURE EXPANSION
#  --> check whether the file is compressed. uncompress and re-compress. (or use zcat to uncompress)
#  --> get and record versions of software
#  --> paired end and single end compatible
#  --> option to scale wigs
#  --> set options to opt out of different parts of the pipeline, for example, opt out of the clean up process
#
#LOG
#   140708 Allow user to select a different organism
#
#################################################


#####################   SET VARIABLES   ######################
solexa_primer_adapter="/proj/dllab/Erin/sequences/solexa-library-seqs.fasta"    #tagdust needs a .fasta file that contains a list of all the solexa primer and adapter sequences. Set this
                                                                                  #variable to a path pointing to that file.
bowtie2path="/proj/dllab/Erin/ce10/from_ucsc/seq/genome_bt2/ce10"               #tophat needs to know where the bowtie2 index files are located. Set this varaible to the path and root
                                                                                  #name of those index files.
                                                                                  #Also, the genome sequence (a .fa file) also needs to be in that same directory.
bowtie2mmpath="/proj/dllab/Erin/sequences/mouse_mm10/bowtie2/mm10"              #This is the mouse (mm10) genome bowtie2 file location.                                                                                  
                                                                                  
mer=100                                                                         #zinba needs to know how long your reads are so that it can make a .wig file with the proper extension lengths
twobit=/proj/dllab/Erin/ce10/from_ucsc/seq/ce10.2bit                            #zinba needs to know where the bowtie twobit files are located. I'm not sure whether zinba works with updated bowtie2
                                                                                  #files or whether you need the old bowtie twobit files.
#####################   USAGE   ######################
usage="
    USAGE
       step1:   load the following modules: tophat, samtools, bedtools, r, bowtie2, fastqc
       step2:   bash autoAnalyzeRNAseq_v2.sh [options] <inputFile.txt> [inputFile2.txt] ... 

    ARGUMENTS
        --genome               Set the organism. Default is ce. Other options are mm.
        
        --cleanmode              At the end of the project, use this option to clean up the dataspace. This will remove the following files:
                                        <name>_cleanfile.fastq
                                        <name>.bed file
                                        bowtie left files
                                It will also zip the following files:
                                        <name>_quality.fastq
                                And it will create a final output directory and drop the following files there:
                                        <name_quality_fastq.gz
                                        <name>.bam.gz
                                        <name>.wig.gz
        
        --maxmultihits          Doesn't work This is an option for calling within tophat. For more information, lookup max-multihits on tophat's manual webpage. Default is 20.
        --extension             This is the number of sequences to extend the .wig file. Should be equal to mean fragment length. Default is 100.
                                        
       <inputFile.txt>           This is the file from the sequencing facility. It is a fastq file containing Illumina sequencing reads generated from multiplexed samples
                                 It should be unmultiplexed and trimmed of any barcode indices.
        
    
    
    "





#####################   PRE-PROCESSING: Check errors, get filenames, set options   ######################

DATE=$(date +"%Y-%m-%d_%H%M")

#Start a log file
dated_log=${DATE}.log
echo $(date +"%Y-%m-%d_%H:%M") | tee -a $dated_log

#Start reporting
printf "\tINITIATED autoAnalyzeRNAseq_v2.sh using command: \n\t"$0" "| tee -a $dated_log
for i in "$@"; do echo $i | tee -a $dated_log; done 
printf "\n" | tee -a $dated_log

if [ -z "$1" ]
  then
    printf "\n"
    echo "ERROR: No inputFile supplied:" | tee -a $dated_log
    echo "$usage" 
    exit
fi


#check modules and load modules get module versions
printf "\n"$(date +"%Y-%m-%d_%H:%M")"\t\tModule: Will check for required loaded modules and their versions:\n" | tee -a $dated_log
modules=$(/nas02/apps/Modules/bin/modulecmd tcsh list 2>&1)

printf "$modules"
printf "\nModule: Please ensure that the following modules are installed:\nsamtools, bedtools, fastqc, bowtie2, R\n" | tee -a $dated_log

#if [[  "${modules}" == .*tophat.* ]] 
#    then
#        printf "\n\n#####################   ERROR   #####################\n\n"
#        printf "Modules not loaded.\nThe modules samtools, tophat, bowtie2, and fastqc are required.\n"
#        printf "Load modules by typing something like ... \nmodule add samtools\n"
#        printf "Exiting"
#        exit
#    fi
#|| [[ ! "${modules}" == .*tophat.* ]] || [[ ! "${modules}" == .*bowtie2.* ]] || [[ ! "${modules}" == .*fastqc.* ]]


#Get options

genome="ce"
cleanmode="off"
maxmultihits=20
for n in $@
do
    case $n in
        --genome) shift;
        genome=${1:--}
        shift
        ;;
        --cleanmode) shift;
        cleanmode="called"
        ;;
        --extension) shift;
        extension=${1:--}
        shift
        ;;
        --maxmultihits) shift;
        maxmultihits=${1:--}
        shift
        ;;
    esac
done



if [[ $genome == "mm" ]]
then
    bowtie2path=${bowtie2mmpath}
fi

    

#Get all the sequence files
array=("$@")



    
    



######################   PROCESSING   ######################


if [[ $cleanmode == "off" ]]    
then
    
    
    #Report the sequence files taken as input:
    printf "\n\n"$(date +"%Y-%m-%d_%H:%M")"\t\tWill process the following sequence samples:\n" |  tee -a $dated_log
    for i in ${array[@]}
        do
            printf "\t$i\n" |  tee -a $dated_log
        done
    
    
    ######################   PROCESSING   ######################
    #Iterate through each sequence file and perform operations:
    
    for i in ${array[@]}
    do
            printf "\n\n####################################################" |  tee -a $dated_log
            printf "\n\n"$(date +"%Y-%m-%d_%H:%M")"\t\tProcessing sample... " |  tee -a $dated_log
    
            echo $i |  tee -a $dated_log
            
            #Isolate the root name of the file:
                #Split path and file name into an array
            IFS="/" read -a patharray <<< "$i"
            #arraylen=${#patharray[@]}
            
            #take the last element in the path that is the file
            file=${patharray[${#patharray[@]}-1]}
            root=
            #If it is a .txtfile, just take the non-.txt part of the name and save it as 'root'
            if [ ${file: -4:4} == ".txt" ]
                then
                root=${file: 0:(${#file}-4)}
            fi
            
            #setup an output directory    
            mkdir $root"_opd" 2>&1 | tee -a $dated_log
            
            
            #Remove any illumina primers, adapters, or indices:  bin: tagdust; input: *.txt; output: *_clean.fastq
            printf "\n\t"$(date +"%Y-%m-%d_%H:%M")"\t\tTagdust: Removing adapter and primer sequences from $file using command:\n" | tee -a $dated_log
            mkdir $root"_opd/tagdust" 2>&1 | tee -a $dated_log
            cmd2="tagdust -q -f 0.001 -s -a "$root"_opd/tagdust/"$root"_artifact.txt -o "$root"_opd/tagdust/"$root"_clean.fastq "$solexa_primer_adapter" "$i
            
            echo $cmd2 | tee -a $dated_log
            $cmd2  2>&1 | tee -a $dated_log
            
            #Trim low quality sequences from the pool. bin: quality filter; input: *_clean.fastq; output: *_quality.fastq
            printf "\n\t"$(date +"%Y-%m-%d_%H:%M")"\t\tFastq_quality_filter: Trimming low quality sequences from "$root" using command:\n" | tee -a $dated.log
            mkdir $root"_opd/qfilter" 2>&1 | tee -a $dated_log
            cmd4="fastq_quality_filter -Q33 -q 30 -p 95 -i "$root"_opd/tagdust/"$root"_clean.fastq -o "$root"_opd/qfilter/"$root"_quality.fastq"
            echo $cmd4 | tee -a $dated.log
            $cmd4 2>&1 | tee -a $dated_log
           
            #Make a quality control report.  bin: fastqc.  input: *_quality.fastq; output: zipped file
            printf "\n\t"$(date +"%Y-%m-%d_%H:%M")"\t\tFastqc:  Assessing quality of "$root"_quality.fastq using command:\n" | tee -a $dated_log
            mkdir $root"_opd/fastqc" 2>&1 | tee -a $dated_log
            cmd3="fastqc -o "$root"_opd/fastqc --noextract "$root"_opd/qfilter/"$root"_quality.fastq"
            echo "$cmd3" | tee -a $dated_log
            $cmd3 2>&1 | tee -a $dated_log
           
           #Align to the genome with tophat. bin: tophat. input $qualityfile; output: /tophat/
           printf "\n\n##################   TOPHAT   ###################"  | tee -a $dated_log
           printf "\n\n\t"$(date +"%Y-%m-%d_%H:%M")"\t\tRunning tophat on the following input files: "  | tee -a $dated_log
           qualityfile=$root"_opd/qfilter/"$root"_quality.fastq"
           mkdir $root"_opd/tophat" 2>&1 | tee -a $dated_log
           cmd5="tophat -i 12000 -o "$root"_opd/tophat --max-multihits "$maxmultihits" "$bowtie2path" "$qualityfile
           printf "%s" "$cmd5"  | tee -a $dated_log
           $cmd5 2>&1 | tee -a $dated_log
           
            #Bedtools
            mkdir $root"_opd/zinba" 2>&1 | tee -a $dated_log
            bamfile=$root"_opd/tophat/accepted_hits.bam"
            bedpathfile=$root"_opd/zinba/"$root".bed"
            wigpathfile=$root"_opd/zinba/"$root".wig"
            bedfile=$root".bed"
            wigfile=$root".wig"
            
            printf "\n\t"$(date +"%Y-%m-%d_%H:%M")"\t\tBedtools:  converting "$bamfile" to "$bedfile" using command:\n" | tee -a $dated_log
            cmd6="bedtools bamtobed -i "$bamfile" > "$bedpathfile
            printf "$cmd6\n"  | tee -a $dated_log
            bedtools bamtobed -i $bamfile > $bedpathfile 2>&1 | tee -a $dated_log
            
            
            #zinba
            rcode=$root"_opd/zinba/"$root"_code.R"
            printf "\n\n\t"$(date +"%Y-%m-%d_%H:%M")"\t\tR: writing an .R file to convert "$bedfile" to "$wigfile" using Zinba(basealigncounts).\n" | tee -a $dated_log
            
            zinba_code="
        library(zinba)
        basealigncount(
            inputfile=\"$bedpathfile\",
            outputfile=\"$wigpathfile\",
            extension="$mer",
            filetype=\"bed\",
            twoBitFile=\""$twobit"\"
        )"
        
            echo "$zinba_code" > $rcode 2>&1 | tee -a $dated_log
            cmd7="/proj/.test/roach/FAIRE/bin/R --vanilla < "$rcode
            printf "%s" "$cmd7" | tee -a $dated_log
            /proj/.test/roach/FAIRE/bin/R --vanilla < $rcode 2>&1 | tee -a $dated_log
            
            gzip $wigpathfile 2>&1 | tee -a $dated.log
    
           
            
        done



    ######################   REPORTING -- PRE-PROCESSING   ######################
    #Make a report of the quality control and pre-processing.
    printf "##################   FINAL SUMMARY  -- PRE-PROCESSING ###################"  | tee -a $dated_log
    printf "\nFile\tReads\tcleanfile_reads\tqfilter_reads\tPercent_retained\n"  | tee -a $dated_log
    
    for i in ${array[@]}
    do
        
        #Get the root name
        IFS="/" read -a patharray <<< "$i"
        #take the last element in the path that is the file
        file=${patharray[${#patharray[@]}-1]}
        root=
        #If it is a .txtfile, just take the non-.txt part of the name and save it as 'root'
        if [ ${file: -4:4} == ".txt" ]
            then
            root=${file: 0:(${#file}-4)}
        fi
    
        #Get the cleanfile and qualityfile
        cleanfile=$root"_opd/tagdust/"$root"_clean.fastq"
        qualityfile=$root"_opd/qfilter/"$root"_quality.fastq"
        
        #Count the lines in each file
        origfilelen=`wc $i | grep -o "\([0-9][0-9]*\)" - | head -n 1`
        cleanfilelen=`wc $cleanfile | grep -o "\([0-9][0-9]*\)" - | head -n 1`
        qfilelen=`wc $qualityfile | grep -o "\([0-9][0-9]*\)" - | head -n 1`
        
        #Calculate the percent of lines that passed the filter (should be eq. to percent of reads that passed).
        percent_retained=`echo "$qfilelen * 100 / $origfilelen" | bc -l`
        
        #report the #reads for each file
        printf $file"\t"  | tee -a $dated_log
        printf "%'d\t" $((origfilelen / 4))  | tee -a $dated_log
        printf "%'d\t" $((cleanfilelen / 4)) | tee -a $dated_log
        printf "%'d\t" $((qfilelen / 4)) | tee -a $dated_log
        printf "%0.2f" $percent_retained | tee -a $dated_log
        printf "%%" | tee -a $dated_log
        printf "\n" | tee -a $dated_log
    
    done
    
    ######################   REPORTING -- ALIGNMENT   ######################
    #Make a report of what was learned.
    printf "\n\n##################   FINAL SUMMARY  -- ALIGNMENT ###################"  | tee -a $dated_log
    printf "\n\nFile\tReads_as_input\tReads_mapped\tPercent_mapped\tPercent_multi_aligned\tReads_with_more_than_20_locs\n"  | tee -a $dated_log
    
    for i in ${array[@]}
    do
        
        #Get the root name
        IFS="/" read -a patharray <<< "$i"
        #take the last element in the path that is the file
        file=${patharray[${#patharray[@]}-1]}
        root=
        #If it is a .txtfile, just take the non-.txt part of the name and save it as 'root'
        if [ ${file: -4:4} == ".txt" ]
            then
            root=${file: 0:(${#file}-4)}
        fi
        
        alignmentsummary=$root"_opd/tophat/align_summary.txt"
    
        #Get the output statistics
        inputnum=`grep "Input" "$alignmentsummary" | perl -nle 'print $1 if /(\d+)/' -`
        mappedreads=`grep "Mapped" "$alignmentsummary" | perl -nle 'print $1 if /(\d+)/' -`
        mappedpercent=`grep "Mapped" $alignmentsummary | perl -nle 'print $1 if /(\d+.\d*%)/' -`
        multireads=`grep "of these" $alignmentsummary | perl -nle 'print $1 if /(\d+)/' -`
        multipercent=`grep "of these" $alignmentsummary | perl -nle 'print $1 if /(\d+.\d*%)/' -`
        repetitive=`grep "of these" $alignmentsummary | perl -nle 'print $1 if /(\d+) have >20/' -`
    
        
        #report the #reads for each file
        printf $file"\t"  | tee -a $dated_log
        printf "%'d\t" $inputnum  | tee -a $dated_log
        printf "%'d\t" $mappedreads | tee -a $dated_log
        printf "%'s\t" $mappedpercent | tee -a $dated_log
        printf "%s\t" $multipercent | tee -a $dated_log
        printf "%'d\n" $repetitive | tee -a $dated_log
    
    done
fi






##################   CLEAN UP FILES   ########################


if [[ $cleanmode == "called" ]]
then
    for i in ${array[@]}
    do
        #Get the root name
        IFS="/" read -a patharray <<< "$i"
        #take the last element in the path that is the file
        file=${patharray[${#patharray[@]}-1]}
        root=
        #If it is a .txtfile, just take the non-.txt part of the name and save it as 'root'
        if [ ${file: -4:4} == ".txt" ]
            then
            root=${file: 0:(${#file}-4)}
        fi
        
        printf "\n\n"$(date +"%Y-%m-%d_%H:%M")"\t\tCleaning up directories associated with... " |  tee -a $dated_log
    
            echo $root |  tee -a $dated_log
        
        mkdir $root"_opd/final_output" 2>&1 | tee -a $dated_log
        
        #Remove tagdust cleanfile
        rm $root"_opd/tagdust/"$root"_clean.fastq"
        #Remove bowtie.left files
        rm $root"_opd/tophat/logs/bowtie.left"*
        #Remove .bed file
        rm $root"_opd/zinba/"$root".bed"
        
        #Zip and Move quality file:
        gzip $root"_opd/qfilter/"$root"_quality.fastq"
        mv $root"_opd/qfilter/"$root"_quality.fastq.gz" $root"_opd/final_output/"
        
        #Move .bam file:
        mv $root"_opd/tophat/accepted_hits.bam" $root"_opd/final_output/"$root"_accepted_hits.bam"
        
        #Move .wig.gz file:
        mv $root"_opd/zinba/"$root".wig.gz" $root"_opd/final_output/"
    done
fi


