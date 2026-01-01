#!/usr/bin/env nextflow

process SAMTOOLS_FLAGSTAT {
    label 'process_high'
    container 'ghcr.io/bf528/samtools:latest'
    publishDir params.outdir

    input:
    tuple val(sample_id), path (bam)

    output:
    tuple val(sample_id), path ("${sample_id}.flagstat.txt")

    script:
    """
    samtools flagstat $bam > ${sample_id}.flagstat.txt
    """

    stub:
    """
    touch ${sample_id}.flagstat.txt
    """
}