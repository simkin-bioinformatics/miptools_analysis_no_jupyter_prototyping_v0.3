configfile: 'miptools_analysis_no_jupyter.yaml'
#singularity: config['sif_file']
output_folder=config['output_directory']

import yaml
import subprocess

freebayes_command_dict_yaml = open(output_folder+'/freebayes_command_dict.yaml','r')
freebayes_command_dict = yaml.safe_load(freebayes_command_dict_yaml)

rule all:
	input:
		#contig_vcf = expand(output_folder+"/contig_vcfs/{contig}.vcf.gz",
		#contig = freebayes_command_dict.keys())
		#variants=output_folder+'/variants.vcf.gz'
		ref_table=output_folder+'/reference_table.csv',
		cov_table=output_folder+'/coverage_table.csv',
		alt_table=output_folder+'/alternate_table.csv'

rule run_freebayes:
	output:
		contig_vcf = output_folder+"/contig_vcfs/{contig}.vcf.gz"
	params:
		freebayes_settings=config['freebayes_settings'],
		wdir='/opt/analysis',
		settings_file='settings.txt',
		freebayes_command_dict = freebayes_command_dict,
	#resources below are currently not utilized - haven't figured out a way to
	#get singularity profile, slurm profile, and high ulimits all at once.
	resources:
		mem_mb=200000,
		nodes=16,
		time_min=5760,
		#log_dir=log_folder
	singularity: config['sif_file']
	script:
		'scripts/run_freebayes.py'


rule concatenate_and_fix_vcf_headers:
	input:
		contig_vcf = expand(output_folder+"/contig_vcfs/{contig}.vcf.gz",
		contig = freebayes_command_dict.keys())
	output:
		#final_check_file = output_folder+'/freebayes_reheader_check.txt',
		variants=output_folder+'/variants.vcf.gz',
	params:
		freebayes_settings=config['freebayes_settings'],
		wdir='/opt/analysis',
		settings_file='settings.txt'
	#resources below are currently not utilized - haven't figured out a way to
	#get singularity profile, slurm profile, and high ulimits all at once.
	resources:
		mem_mb=200000,
		nodes=16,
		time_min=5760,
		#log_dir=log_folder
	singularity: config['sif_file']
	script:
		'scripts/call_variants_concatenate_vcf.py'

rule generate_tables:
	input:
		variants=output_folder+'/variants.vcf.gz',
	output:
		ref_table=output_folder+'/reference_table.csv',
		cov_table=output_folder+'/coverage_table.csv',
		alt_table=output_folder+'/alternate_table.csv'
	params:
		wdir='/opt/analysis',
		settings_file='settings.txt',
		geneid_to_genename=config['geneid_to_genename'],
		target_aa_annotation=config['target_aa_annotation'],
		aggregate_nucleotides=config['aggregate_nucleotides'],
		aggregate_aminoacids=config['aggregate_aminoacids'],
		target_nt_annotation=config['target_nt_annotation'],
		annotate=config['annotate'],
		decompose_options=config['decompose_options'],
		annotated_vcf=config['annotated_vcf'],
		aggregate_none=config['aggregate_none'],
		output_prefix=config['output_prefix']
	singularity: config['sif_file']
	script:
		'scripts/generate_tables.py'
