snakemake -s 01_setup_run.smk --cores 4
snakemake -s 02_check_run_stats.smk --profile singularity_profile
snakemake -s 03_generate_contigs.smk --profile singularity_profile
snakemake -s 04_run_freebayes.smk --profile singularity_profile
