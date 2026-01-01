#!/usr/bin/env nextflow

process MULTIQC {
    label 'process_low'
    container 'ghcr.io/bf528/multiqc:latest'
    publishDir params.outdir, mode: 'copy'

    input:
    path fastqc_files, stageAs: 'fastqc_?/*'

    output:
    path 'multiqc_report.html', emit: html

    shell:
    """
    multiqc -f .
    """


    stub:
    """
    touch multiqc_report.html
    """
}