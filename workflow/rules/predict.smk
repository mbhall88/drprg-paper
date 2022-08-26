

rule mykrobe_predict:
    input:
        reads=rules.extract_decontaminated_reads.output.reads,
    output:
        report=RESULTS
        / "amr_predictions/mykrobe/{tech}/{proj}/{sample}/{run}.mykrobe.json.gz",
    shadow:
        "shallow"
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 4 * GB,
    container:
        CONTAINERS["mykrobe"]
    log:
        LOGS / "mykrobe_predict/{tech}/{proj}/{sample}/{run}.log",
    params:
        opts=" ".join(
            [
                "--force",
                "-A",
                "-O json",
                "-D 0.20",
                "--species tb",
                "--sample {run}",
            ]
        ),
        tech_opts=infer_mykrobe_tech_opts,
        base_json=lambda wildcards, output: Path(output.report).with_suffix(""),
    threads: 2
    shell:
        """
        mykrobe predict {params.tech_opts} {params.opts} -o {params.base_json} \
            -i {input.reads} -t {threads} -m {resources.mem_mb}MB > {log} 2>&1
        gzip {params.base_json} 2>> {log}
        """


rule combine_mykrobe_reports:
    input:
        reports=infer_mykrobe_reports,
    output:
        report=RESULTS / "amr_predictions/mykrobe/{tech}/summary.csv",
    log:
        LOGS / "combine_mykrobe_reports/{tech}.log",
    container:
        CONTAINERS["python"]
    script:
        str(SCRIPTS / "combine_mykrobe_reports.py")


# ==========
# DRPRG
# ==========
rule drprg_predict:
    input:
        reads=rules.extract_decontaminated_reads.output.reads,
        index=RESULTS / f"drprg/index/w{W}/k{K}",
    output:
        report=RESULTS / "amr_predictions/drprg/{tech}/{proj}/{sample}/{run}.drprg.json",
        vcf=RESULTS / "amr_predictions/drprg/{tech}/{proj}/{sample}/{run}.drprg.bcf",
    shadow:
        "shallow"
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 4 * GB,
    container:
        CONTAINERS["drprg"]
    log:
        LOGS / "drprg_predict/{tech}/{proj}/{sample}/{run}.log",
    params:
        opts=" ".join(
            [
                "--sample {run}",
                "--verbose",
                "--failed",
            ]
        ),
        tech_opts=infer_drprg_tech_opts,
        filters=drprg_filter_args,
        outdir=lambda wildcards, output: Path(output.report).parent,
    threads: 2
    shell:
        """
        drprg predict {params.opts} {params.tech_opts} {params.filters} \
            -i {input.reads} -o {params.outdir} -x {input.index} -t {threads} 2> {log}
        """