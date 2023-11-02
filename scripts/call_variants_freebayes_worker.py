import sys
import yaml
import subprocess
import gzip
sys.path.append("/opt/src")
import mip_functions_freebayes_call_edit as mip
contig_dict_list_yaml = open("/opt/analysis/contig_dict_list.yaml",'r')
contig_dict_list = yaml.safe_load(contig_dict_list_yaml)
check_file = open("/opt/analysis/freebayes_check_file.txt",'w')

results = []
errors = []

'''
for contig_dict in contig_dict_list:
    """Run freebayes program with the specified options.

    Run freebayes program with the specified options and return a
    subprocess.CompletedProcess object.
    """
    #options = contig_dict["options"]
    #command = ["freebayes"]
    command=contig_dict
    #command.extend(options)

    print(command)
    # run freebayes command piping the output
    fres = subprocess.run(command, stderr=subprocess.PIPE)
    # check the return code of the freebayes run. if succesfull continue
    if fres.returncode == 0:
        # bgzip the vcf output, using the freebayes output as bgzip input
        vcf_path = contig_dict["vcf_path"]
        gres = subprocess.run(["bgzip", "-f", vcf_path],
                              stderr=subprocess.PIPE)
        # make sure bgzip process completed successfully
        if gres.returncode == 0:
            # index the vcf.gz file
            vcf_gz_path = contig_dict["vcf_gz_path"]
            ires = subprocess.run(["bcftools", "index", "-f", vcf_gz_path],
                                  stderr=subprocess.PIPE)
            # return the CompletedProcess objects
            #return (fres, gres, ires)
            results.extend('√')
    # if freebayes call failed, return the completed process object
    # instead of attempting to zip the vcf file which does not exist if
    # freebayes failed.
    else:
        #return (fres, )
        errors.extend('x')
print(f"{str(len(results))} {str(len(errors))} {str(len(contig_dict_list))}")
check_file.write(f"results: {str(len(results))}\nerrors: {str(len(errors))}\ncontig dict list length: {str(len(contig_dict_list))}")
'''


