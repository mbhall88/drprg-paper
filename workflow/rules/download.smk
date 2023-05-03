rule download_data:
    output:
        outdir=temp(directory(RESULTS / "download/{tech}/{proj}/{sample}/{run}")),
        run_info=temp(RESULTS / "download/{tech}/{proj}/{sample}/{run}/fastq-run-info.json"),
    log:
        LOGS / "download_data/{tech}/{proj}/{sample}/{run}.log",
    container:
        CONTAINERS["fastq_dl"]
    resources:
        mem_mb=lambda wildcards, attempt: attempt * int(2 * GB),
    params:
        db="sra",
        opts="--verbose"
    group:
        "qc"
    shadow:
        "shallow"
    shell:
        """
        /usr/local/bin/_entrypoint.sh 2> {log}
        fastq-dl {params.opts} --outdir {output.outdir} -a {wildcards.run} --provider {params.db} 2>> {log}
        """


rule validate_run_info:
    input:
        info=rules.download_data.output.run_info,
    output:
        run_info=RESULTS / "validate/{tech}/{proj}/{sample}/{run}/run_info.tsv",
    log:
        LOGS / "validate_run_info/{tech}/{proj}/{sample}/{run}.log",
    params:
        delim="\t",
    container:
        CONTAINERS["python"]
    group:
        "qc"
    script:
        str(SCRIPTS / "validate_run_info.py")
