'''
My usage of singularity with snakemake isn't great: my python scripts execute
inside the singularity container, but my input and output files are seen outside
the container. This means that input and output file paths need to be specified
twice: once with external file paths (no binding, as input and output files) and
once with internal file paths to match container bindings (as parameters).

Ideally, internal and external file paths would be set identical to each other,
but not sure if this might break other parts of the pipeline.
'''

configfile: 'miptools_analysis_no_jupyter.yaml'
#singularity: config['sif_file']
output_folder=config['output_directory']
log_folder=output_folder+'/run_settings/check_run_stats'
import subprocess
subprocess.call(f'mkdir -p {log_folder}', shell=True)
rule all:
	input:
		snakefile=log_folder+'/02_check_run_stats.smk',
		repool_csv=output_folder+'/repool.csv',
		barcode_counts=output_folder+'/barcode_counts.csv',
		output_graph=output_folder+'/umi_heatmap.html'

rule copy_params:
	'''
	copies snakemake file, config file, profile, and python scripts to output
	folder
	'''
	input:
		snakefile='02_check_run_stats.smk',
		configfile='miptools_analysis_no_jupyter.yaml',
		profile='singularity_profile',
		scripts='scripts'
	output:
		snakefile=log_folder+'/02_check_run_stats.smk',
		configfile=log_folder+'/miptools_analysis_no_jupyter.yaml',
		profile=directory(log_folder+'/singularity_profile'),
		scripts=directory(log_folder+'/scripts')
	resources:
		log_dir=log_folder
	shell:
		'''
		cp {input.snakefile} {output.snakefile}
		cp {input.configfile} {output.configfile}
		cp -r {input.profile} {output.profile}
		cp -r {input.scripts} {output.scripts}
		'''

rule modify_ozkan_settings:
	'''
	copies Ozkan's default settings, plus any user updated settings, to an
	output folder alongside the data for later reference.
	'''
	params:
		template_settings='/opt/resources/templates/analysis_settings_templates/settings.txt',
		processor_number=config['processor_number'],
		bwa_extra=config['bwa_extra'],
		species=config['species'],
		probe_sets_used=config['probe_sets_used'],
		freebayes_threads=config['freebayes_threads'],
		min_haplotype_barcodes=config['min_haplotype_barcodes'],
		min_haplotype_samples=config['min_haplotype_samples'],
		min_haplotype_sample_fraction=config['min_haplotype_sample_fraction'],
		wdir='/opt/analysis'
	output:
		user_settings=output_folder+'/settings.txt'
	singularity: config['sif_file']
	resources:
		log_dir=log_folder
	script:
		'scripts/modify_ozkan_settings.py'

rule parse_info_file:
	'''
	parses the original info file into multiple sub-files
	'''
	input:
		user_settings=output_folder+'/settings.txt'
	output:
		data=output_folder+'/data.tsv',
		samples=output_folder+'/samples.tsv',
		unique_haplotypes=output_folder+'/unique_haplotypes.csv'
	params:
		wdir='/opt/analysis',
		settings_file='settings.txt',
		info_files=['/opt/data/'+config['wrangled_file']],
		sample_sheets='/opt/data/sample_sheet.tsv',
		sample_groups=config['sample_groups']
	resources:
		log_dir=log_folder
	singularity: config['sif_file']
	script:
		'scripts/parse_info_file.py'

rule map_haplotypes:
	'''
	maps haplotypes against the reference genome and outputs several tables
	showing these mappings and whether they are on target.
	'''
	input:
		data=output_folder+'/data.tsv',
		samples=output_folder+'/samples.tsv',
		unique_haplotypes=output_folder+'/unique_haplotypes.csv'
	params:
		wdir='/opt/analysis',
		settings_file='settings.txt',
	output:
		fastq_haps=output_folder+'/haplotypes.fq',
		haps_sam=output_folder+'/haplotypes_bwa.sam',
		aligned_haps=output_folder+'/aligned_haplotypes.csv',
		all_haps=output_folder+'/all_haplotypes.csv',
		mapped_haps=output_folder+'/mapped_haplotypes.csv',
		offtarget_haps=output_folder+'/offtarget_haplotypes.csv',
		metadata=output_folder+'/run_meta.csv',
		barcode_counts=output_folder+'/barcode_counts.csv',
		haplotype_counts=output_folder+'/haplotype_counts.csv',
		sample_summary=output_folder+'/sample_summary.csv'
	#resources below are currently not utilized - haven't figured out a way to
	#get singularity profile, slurm profile, and high ulimits all at once.
	resources:
		mem_mb=200000,
		time_min=4320,
		nodes=20,
		log_dir=log_folder
	singularity: config['sif_file']
	script:
		'scripts/map_haplotypes.py'

rule graph_barcodes:
	'''
	graphs the barcodes that worked and the barcodes that failed
	'''
	input:
		barcode_counts=output_folder+'/barcode_counts.csv',
	params:
		wdir='/opt/analysis',
	output:
		output_graph=output_folder+'/umi_heatmap.html'
	resources:
		log_dir=log_folder
	singularity: config['sif_file']
	script:
		'scripts/graph_barcodes.py'

rule make_repool_table:
	'''
	creates a table that recommends (for each sample) whether it needs to be
	repooled or recaptured based on some user-defined thresholds
	'''
	input:
		output_folder+'/run_meta.csv'
	params:
		high_barcode_threshold=config['high_barcode_threshold'],
		low_coverage_action=config['low_coverage_action'],
		target_coverage_count=config['target_coverage_count'],
		target_coverage_fraction=config['target_coverage_fraction'],
		target_coverage_key=config['target_coverage_key'],
		barcode_coverage_threshold=config['barcode_coverage_threshold'],
		barcode_count_threshold=config['barcode_count_threshold'],
		assessment_key=config['assessment_key'],
		good_coverage_quantile=config['good_coverage_quantile'],
		repool_csv='/opt/analysis/repool.csv'
	resources:
		log_dir=log_folder
	output:
		repool_csv=output_folder+'/repool.csv'
	singularity: config['sif_file']
	script:
		'scripts/make_repool_table.py'
