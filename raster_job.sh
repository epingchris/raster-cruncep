#! /bin/sh
#$ -S /bin/sh
#$ -N cruncep
#$ -cwd
#$ -M epingchris@gmail.com
#$ -m eas
#$ -o cruncep_output.o
#$ -e cruncep_error.e
#$ -pe mpi 24
#$ -l paraq
#$ -l mem_free=500M,h_vmem=96G
R CMD BATCH raster_paral.R