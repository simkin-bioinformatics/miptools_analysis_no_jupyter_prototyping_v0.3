'''
creates a singularity profile with bindings for remaining steps
'''
configfile: 'miptools_analysis_no_jupyter.yaml'

rule all:
	input:
		profile='singularity_profile/config.yaml'
rule create_profile:
	params:
		project_resources=config['project_resources'],
		species_resources=config['species_resources'],
		wrangler_directory=config['wrangler_directory'],
		output_directory=config['output_directory'],
		miptools_directory=config['miptools_directory']
	output:
		profile='singularity_profile/config.yaml'
	script:
		'scripts/create_profile.py'
