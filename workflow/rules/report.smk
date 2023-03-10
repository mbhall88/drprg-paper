rule plot_phenotype_availability:
    output:
        upset_plots=report(
            multiext(str(PLOTS / "dst_availability/upset.{tech}"), ".png", ".svg"),
            category="DST availability",
            subcategory="Upset Plot",
            labels={"Technology": "{tech}"},
        ),
        barplots=report(
            multiext(str(PLOTS / "dst_availability/bar.{tech}"), ".png", ".svg"),
            category="DST availability",
            subcategory="Barplot",
            labels={"Technology": "{tech}"},
        ),
    log:
        LOGS / "plot_phenotype_availability/{tech}.log",
    resources:
        mem_mb=lambda wildcards, attempt: attempt * int(30*GB),
    conda:
        ENVS / "plot_phenotype_availability.yaml"
    params:
        samplesheet=(
            lambda wildcards: illumina_df if wildcards.tech == "illumina" else ont_df
        ),
    script:
        SCRIPTS / "plot_susceptibility_availability.py"


rule plot_sample_depth:
    input:
        qc=rules.qc_summary.output.summary,
    output:
        plots=report(
            multiext(str(PLOTS / "QC/{tech}.depth"), ".png", ".svg"),
            category="QC",
            subcategory="Depth",
            labels=dict(technology="{tech}")
        )
    log:
        LOGS / "plot_sample_depth/{tech}.log"
    conda:
        ENVS / "plot_predict_benchmark.yaml"
    script:
        SCRIPTS / "plot_sample_depth.py"

rule compare_sn_and_sp:
    input:
        summary_files=expand(
            str(RESULTS / "amr_predictions/{tool}/{{tech}}/summary.csv"), tool=TOOLS
        ),
        phenotypes=lambda wildcards: config[f"{wildcards.tech}_samplesheet"],
        qc=rules.qc_summary.output.summary,
    output:
        plots=report(
            multiext(str(PLOTS / "sn_sp/{tech}"), ".png", ".svg"),
            category="Sn/Sp",
            subcategory="Figure",
            labels={"Technology": "{tech}"},
        ),
        table=report(
            TABLES / "sn_sp/summary.{tech}.csv",
            category="Sn/Sp",
            subcategory="Tables",
            labels={"Technology": "{tech}", "Table": "Summary"},
        ),
        classification=report(
            TABLES / "sn_sp/classifications.{tech}.csv",
            category="Sn/Sp",
            subcategory="Tables",
            labels={"Technology": "{tech}", "Table": "Classifications"},
        ),
    log:
        LOGS / "compare_sn_and_sp/{tech}.log",
    resources:
        mem_mb=GB,
    params:
        minor_is_susceptible=False,
        unknown_is_resistant=False,
        failed_is_resistant=False,
        figsize=(13, 8),
        dpi=300,
        sn_marker="+",
        sp_marker="x",
        ignore_drugs=("ciprofloxacin", "all"),
        min_num_phenotypes=10,
        min_depth=15,
        max_contamination=0.05,
    conda:
        str(ENVS / "compare_sn_and_sp.yaml")
    script:
        str(SCRIPTS / "compare_sn_and_sp.py")


rule aggregate_predict_benchmarks:
    input:
        bench=infer_benchmark_reports,
    output:
        summary=BENCH / "predict/{tech}.summary.csv",
    log:
        LOGS / "aggregate_predict_benchmarks/{tech}.log",
    resources:
        mem_mb=GB,
    container:
        CONTAINERS["python"]
    params:
        delim=",",
    script:
        SCRIPTS / "aggregate_predict_benchmarks.py"


rule plot_predict_benchmark:
    input:
        summary=rules.aggregate_predict_benchmarks.output.summary,
    output:
        memory_plots=report(
            multiext(str(PLOTS / "benchmark/predict/memory.{tech}"), ".png", ".svg"),
            category="Benchmark",
            subcategory="Predict",
        ),
        runtime_plots=report(
            multiext(str(PLOTS / "benchmark/predict/runtime.{tech}"), ".png", ".svg"),
            category="Benchmark",
            subcategory="Predict",
        ),
    log:
        LOGS / "plot_predict_benchmark/{tech}.log",
    resources:
        mem_mb=GB,
    conda:
        str(ENVS / "plot_predict_benchmark.yaml")
    params:
        fontsize=14,
        palette="Set2",
        dpi=300,
        figsize=(13, 8),
        stats_test="Wilcoxon",
    script:
        str(SCRIPTS / "plot_predict_benchmark.py")
