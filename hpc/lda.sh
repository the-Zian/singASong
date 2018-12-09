#!/bin/bash
#SBATCH --nodes=16
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=4:00:00
#SBATCH --mem=64GB
#SBATCH --job-name=LDA
#SBATCH --mail-type=END
#SBATCH --mail-user=alanzchen@nyu.edu
#SBATCH --output=slurm/slurm_%j.out
  
module purge
module load r/intel/3.4.2
RUNDIR=$SCRATCH/singASong/run-${SLURM_JOB_ID/.*}
mkdir -p $RUNDIR
  
PROJDIR=/home/azc211/singASong
cd $PROJDIR

# Model settings
NGRAMS=$(cat hpc/settings.csv | awk 'FNR==3 {print $2}')
SONG=$(cat hpc/settings.csv | awk 'FNR==4 {print $3}')
ARTIST=$(cat hpc/settings.csv | awk 'FNR==5 {print $4}')

Rscript $PROJDIR/code/lda.r
