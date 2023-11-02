configfile: 'miptools_analysis_no_jupyter.yaml'
#singularity: config['sif_file']
output_folder=config['output_directory']
log_folder=config['output_directory']+'/run_settings/generate_contigs_and_run_freebayes'
import subprocess
subprocess.call(f'mkdir {log_folder}', shell=True)

rule all:
	input:
		freebayes_command_dict=output_folder+'/freebayes_command_dict.yaml',
		snakefile=log_folder+'/generate_contigs.smk',
		#final_check_file = output_folder+'/freebayes_reheader_check.txt',
		#check_file = output_folder+'/freebayes_check_file.txt',
		#contig_vcfs=directory(output_folder+'/contig_vcfs'),
		#cov_table=output_folder+'/coverage_table.csv'
#		targets_vcf=output_folder+'/targets.vcf.gz'

rule copy_params:
	'''
	copies snakemake file, config file, profile, and python scripts to output
	folder
	'''
	input:
		generate_contigs_snakefile='generate_contigs.smk',
		run_freebayes_snakefile = 'run_freebayes.smk',
		configfile='miptools_analysis_no_jupyter.yaml',
		profile='singularity_profile',
		scripts='scripts'
	output:
		generate_contigs_snakefile=log_folder+'/generate_contigs.smk',
		run_freebayes_snakefile = log_folder+'/run_freebayes.smk',
		configfile=log_folder+'/miptools_analysis_no_jupyter.yaml',
		profile=directory(log_folder+'/singularity_profile'),
		scripts=directory(log_folder+'/scripts')
	resources:
		log_dir=log_folder
	shell:
		'''
		cp {input.generate_contigs_snakefile} {output.generate_contigs_snakefile}
		cp {input.run_freebayes_snakefile} {output.run_freebayes_snakefile}
		cp {input.configfile} {output.configfile}
		cp -r {input.profile} {output.profile}
		cp -r {input.scripts} {output.scripts}
		'''

rule generate_contigs:
	'''
	calls variants with freebayes and produces a VCF output file
	'''
	input:
		output_folder+'/aligned_haplotypes.csv'
	output:
		#contig_vcfs=directory(output_folder+'/contig_vcfs'),
		padded_bams=directory(output_folder+'/padded_bams'),
		padded_fastqs=directory(output_folder+'/padded_fastqs'),
		freebayes_command_dict=output_folder+'/freebayes_command_dict.yaml'
		#variants_index=output_folder+'/variants.vcf.gz.csi',
		#variants=output_folder+'/variants.vcf.gz',
		#unfixed_variants=output_folder+'/unfixed.vcf.gz',
		#new_header=output_folder+'/new_vcf_header.txt',
		#warnings=output_folder+'/freebayes_warnings.txt',
		#errors=output_folder+'/freebayes_errors.txt',
		#targets_index=output_folder+'/targets.vcf.gz.tbi',
		#targets_vcf=output_folder+'/targets.vcf.gz'
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
		log_dir=log_folder
	singularity: config['sif_file']
	script:
		'scripts/generate_contigs.py'
'''
rule run_freebayes_worker:
	input:
		contig_dict_list_yaml=output_folder+'/contig_dict_list.yaml'
	output:
		check_file = output_folder+'/freebayes_check_file.txt'
		#contig_vcfs=directory(output_folder+'/contig_vcfs')
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
		log_dir=log_folder
	singularity: config['sif_file']
	script:
		'scripts/call_variants_freebayes_worker.py'

rule concatenate_and_fix_vcf_headers:
	input:
		check_file = output_folder+'/freebayes_check_file.txt'
	output:
		final_check_file = output_folder+'/freebayes_reheader_check.txt',
		variants=output_folder+'/variants.vcf.gz',
		#contig_vcfs=directory(output_folder+'/contig_vcfs')
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
		log_dir=log_folder
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
'''