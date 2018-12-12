#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --time=8:00:00
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
SONG=$(cat hpc/settings.csv | awk 'FNR==4 {print $2}')
ARTIST=$(cat hpc/settings.csv | awk 'FNR==5 {print $2}')

# Check for NGRAM specific DTM, create if not found
if [ ! -e $PROJDIR/data/inputs/songs_n$NGRAMS_dtm.rds ]
then
    Rscript $PROJDIR/code/4a_cast_dtm.r $NGRAMS
fi

Rscript $PROJDIR/code/4b_lda.r $NGRAMS $SONG $ARTIST
