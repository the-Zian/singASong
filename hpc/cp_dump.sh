# !/bin/bash

USER=$(cat hpc/settings.csv | awk 'FNR==2 {print $2}')
scp prince:/home/$USER/singASong/dump/* dump/
