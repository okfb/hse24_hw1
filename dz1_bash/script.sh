#! /bin/bash

SEED=530
THREADS=16

report() {
mkdir $1_report
cd $1_report
mkdir fastqc
fastqc ../$1/* -o fastqc -t $THREADS
mkdir multiqc
multiqc fastqc --filename "multiqc_report_$1" --outdir "multiqc"
cd ..
}

process() {
OUTPUT_DIR=$1
PE_NUM=$2
MP_NUM=$3

cd $OUTPUT_DIR
if [ ! -d "sub" ]; then
mkdir sub
seqtk sample -s "$SEED" $HOME/src/pe1.fq $PE_NUM > sub/pe1_sub.fq
seqtk sample -s "$SEED" $HOME/src/pe2.fq $PE_NUM > sub/pe2_sub.fq
seqtk sample -s "$SEED" $HOME/src/mp1.fq $MP_NUM > sub/mp1_sub.fq
seqtk sample -s "$SEED" $HOME/src/mp2.fq $MP_NUM > sub/mp2_sub.fq
fi
if [ ! -d "sub_report" ]; then
report sub
fi
if [ ! -d "trimmed" ]; then
mkdir trimmed
echo -e "sub/pe1_sub.fq\nsub/pe2_sub.fq" > trimmed/pe.fofn
echo -e "sub/mp1_sub.fq\nsub/mp2_sub.fq" > trimmed/mp.fofn
platanus_trim -i trimmed/pe.fofn -t $THREADS
platanus_internal_trim -i trimmed/mp.fofn -t $THREADS
mv sub/*trimmed trimmed/
fi
if [ ! -d "trimmed_report" ]; then
report trimmed
fi
if [ ! -d "assemble" ]; then
mkdir assemble
platanus assemble -o platanus -f trimmed/*trimmed -t $THREADS
mv platanus* assemble
fi
if [ ! -d "scaffold" ]; then
mkdir scaffold
platanus scaffold \
         -o platanus \
         -c assemble/platanus_contig.fa \
  -b assemble/platanus_contigBubble.fa \
  -IP1 trimmed/*.trimmed \
  -OP2 trimmed/*.int_trimmed \
  -t $THREADS
mv platanus* scaffold
fi
if [ ! -d "gap_close" ]; then
mkdir gap_close
platanus gap_close \
  -o platanus \
  -c scaffold/platanus_scaffold.fa \
  -IP1 trimmed/*.trimmed \
  -OP2 trimmed/*.int_trimmed \
  -t $THREADS
mv platanus* gap_close
fi
}

cd $HOME
if [ ! -d "src" ]; then
mkdir src
ln -s /usr/share/data-minor-bioinf/assembly/oil_R1.fastq src/pe1.fq
ln -s /usr/share/data-minor-bioinf/assembly/oil_R2.fastq src/pe2.fq
ln -s /usr/share/data-minor-bioinf/assembly/oilMP_S4_L001_R1_001.fastq src/mp1.fq
ln -s /usr/share/data-minor-bioinf/assembly/oilMP_S4_L001_R2_001.fastq src/mp2.fq
fi

if [ ! -d "default" ]; then
mkdir default
process default 5000000 1500000
fi
cd $HOME
if [ ! -d "lessy" ]; then
mkdir lessy
process lessy 500000 150000
fi
cd $HOME
if [ ! -d "data" ]; then
mkdir data
cp default/assemble/platanus_contig.fa data/contigs.fasta
cat lessy/assemble/platanus_contig.fa >> data/contigs.fasta
cp default/scaffold/platanus_scaffold.fa data/scaffolds.fasta
cat lessy/scaffold/platanus_scaffold.fa >> data/scaffolds.fasta
fi
