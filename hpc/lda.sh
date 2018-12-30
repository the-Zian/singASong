#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --time=8:00:00
#SBATCH --mem=72GB
#SBATCH --job-name=LDA
#SBATCH --mail-type=END
#SBATCH --mail-user=alanzchen@nyu.edu
#SBATCH --output=slurm/slurm_%j.out
  
module purge
module load r/intel/3.4.2
RUNDIR=$SCRATCH/singASong/run-${SLURM_JOB_ID/.*}
mkdir -p $RUNDIR

# User directory
NETID=$(cat hpc/settings.csv | awk 'FNR==2 {print $2}')
PROJDIR=/home/$NETID/singASong
cd $PROJDIR

# Model settings
NGRAMS=$(cat hpc/settings.csv | awk 'FNR==3 {print $2}')
DOCUMENT=$(cat hpc/settings.csv | awk 'FNR==4 {print$2}')

if [[ $DOCUMENT != 'artist' && $DOCUMENT != 'song' ]]
then
    echo "DOCUMENT must be 'artist' or 'song'"
    echo "check 'hpc/settings.csv'"
    exit 1
fi

# Check for DOCUMENT - NGRAM specific DTM, create if not found
if [ ! -e $PROJDIR/data/inputs/$DOCUMENT_n$NGRAMS_dtm.rds ]
then
    Rscript $PROJDIR/code/3a_cast_dtm.r $NGRAMS $DOCUMENT
fi

# Run LDA model for K topics
Ks=$(cat hpc/settings.csv | awk 'FNR==5 {print$2}')

Rscript $PROJDIR/code/3b_lda.r $NGRAMS $DOCUMENT $Ks
