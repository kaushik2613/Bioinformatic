#!/bin/bash

#SBATCH -J Tcas-Agla           						# Job name
#SBATCH -o Tcas-Agla.o%j       						# Name of stdout output file
#SBATCH -e Tcas-Agla.e%j 		     				# Name of stderr error file
#SBATCH -p RM          									# Queue (partition) name
#SBATCH -N 1               									# Total # of nodes 
#SBATCH -n 128              								# Total # of mpi tasks 
#SBATCH -t 2:00:00        								# Run time (hh:mm:ss)
#SBATCH --mail-user=<your@email.edu>		#email address
#SBATCH --mail-type=all    							# Send email at begin and end of job      

# Other commands must follow all #SBATCH directives...

module load BLAST

blastp -query Tcas5.2_protein.faa -db Agla_2.0_protein.faa -outfmt "6 qseqid sseqid evalue" -max_target_seqs 1 -num_threads 128 -out Tcas_query_v_Agla_subject.txt
blastp -query Agla_2.0_protein.faa -db Tcas5.2_protein.faa -outfmt "6 qseqid sseqid evalue" -max_target_seqs 1 -num_threads 128 -out Agla_query_v_Tcas_subject.txt