#!/bin/bash

## sbatch directives for Slurm scheduler

#SBATCH --account=aoml-hafs1
#SBATCH --job-name="testgrid"
#SBATCH -n 1
#SBATCH --tasks-per-node=6
#SBATCH --cpus-per-task=6
#SBATCH -o testgrid.%j.log
#SBATCH -e testgrid.%j.err
#SBATCH -t 00:59:00
#SBATCH --exclusive

set -ax
ulimit -s unlimited
ulimit -a

module purge

##
## load contrib environment
## load slurm utils (arbitrary.pl  layout.pl)
##
module use -a /contrib/sutils/modulefiles
module load sutils

##
## load programming environment
## this typically includes compiler, MPI and job scheduler
##
module load intel/18.0.5.274
module load impi/2018.0.4

##
## NCEP libraries (temporary version to match the CCPP requirements)
##
module use -a /scratch2/NCEPDEV/nwprod/NCEPLIBS/modulefiles
module load bacio/2.0.3
module load ip/3.0.2
module load nemsio/2.2.4
module load sp/2.0.3
module load w3emc/2.3.1
module load w3nco/2.0.7
module load g2/3.1.1
module load g2tmpl/1.6.0
module load crtm/2.2.6
module load jasper/1.900.1
module load png/1.2.44
module load z/1.2.11
## load modules for nceppost grib
module load post/8.0.6

##
## load ESMF library for above compiler / MPI combination
## use pre-compiled EMSF library for above compiler / MPI combination
##
module use -a /scratch1/NCEPDEV/nems/emc.nemspara/soft/modulefiles
module load hdf5_parallel/1.10.6
module load netcdf_parallel/4.7.4
module load esmf/8.0.0_ParallelNetCDF

module list

# include settings for grid generation
. settings_sys.sh
. ${WORKhafs}/settings_grid.sh

# run shell script containing calls to grid-based executables
./run_grid.sh
./run_mosaic.sh
#./run_orog_list.sh
#wait

# temporary: For nested configs, these aren't necessary.
#./run_filtertopo.sh
#./run_shave.sh

