snakemake -s setup_run.smk --cores 4
snakemake -s check_run_stats.smk --profile singularity_profile
snakemake -s generate_contigs.smk --profile singularity_profile
snakemake -s run_freebayes.smk --profile singularity_profile
