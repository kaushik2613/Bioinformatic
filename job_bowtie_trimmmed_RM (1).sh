#!/bin/bash

#SBATCH -J mapping_trimmed           			# Job name
#SBATCH -o mapping_trimmed.o%j       		# Name of stdout output file
#SBATCH -e mapping_trimmed.e%j 		     	# Name of stderr error file
#SBATCH -p RM          									# Queue (partition) name
#SBATCH -N 1               									# Total # of nodes 
#SBATCH -c 16              								# Total # of mpi tasks 
#SBATCH -t 2:00:00        								# Run time (hh:mm:ss)
#SBATCH --mail-user=<your_username>@uta.edu		#your email address
#SBATCH --mail-type=all    							# Send email at begin and end of job      


# === conda "bioinf" env test | install packages if needed | activate ===

module load anaconda3
eval "$(conda shell.bash hook)"

# Check if "bioinf" environment exists
if ! conda env list | grep -qE '^\s*bioinf\s'; then
  echo "[*] Creating bioinf conda environment..."
  conda create -y -n bioinf -c conda-forge -c bioconda fastp
else
  echo "[*] bioinf env already exists."
  
  # Check if fastp is installed
  if ! conda list -n bioinf fastp | grep -q fastp; then
    echo "[*] Installing fastp into bioinf..."
    conda install -y -n bioinf -c conda-forge -c bioconda fastp
  else
    echo "[*] fastp already installed in bioinf."
  fi
fi

conda activate bioinf

# ============================================
fastp \
  -i SRR030257_1.fastq.gz -I SRR030257_2.fastq.gz \
  -o SRR030257_trimmed_1.fastq.gz -O SRR030257_trimmed_2.fastq.gz \
  --html SRR030257_fastp.html \
  --json SRR030257_fastp.json \
  --thread 16

# ======== use bowtie2 to map reads =========
# ====== pipe to samtools for bam creation ======
module load bowtie2 samtools

bowtie2-build NC_012967.1.fasta NC_012967.1
samtools faidx NC_012967.1.fasta
 
bowtie2 \
  -p 16 \
  -x NC_012967.1 \
  -1 SRR030257_trimmed_1.fastq.gz   -2 SRR030257_trimmed_2.fastq.gz \
  2> trimmed_reads_summary.txt \
  | samtools view -@ 16 -b \
  | samtools sort -@ 16 -o trimmed_reads.sorted.bam 
  
  samtools index -@ 16 trimmed_reads.sorted.bam

# ========== use bcftools to call variants ==============

module load bcftools
bcftools mpileup -f NC_012967.1.fasta trimmed_reads.sorted.bam -Ou \
  | bcftools call --ploidy 1 -mv  -Ov -o trimmed_reads.vcf

bcftools stats trimmed_reads.vcf > trimmed_reads.bcftools.stats




