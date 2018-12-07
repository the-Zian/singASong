#!/bin/bash
#SBATCH --nodes=8
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=5:00:00
#SBATCH --mem=16GB
#SBATCH --job-name=LDA
#SBATCH --mail-type=END
#SBATCH --mail-user=alanzchen@nyu.edu
#SBATCH --output=slurm_%j.out
  
module purge
module load r/intel/3.4.2
RUNDIR=$SCRATCH/singASong/run-${SLURM_JOB_ID/.*}
mkdir -p $RUNDIR
  
PROJDIR=$home/azc211/singASong
cd $PROJDIR
rscript $DATADIR/code/lda.r
