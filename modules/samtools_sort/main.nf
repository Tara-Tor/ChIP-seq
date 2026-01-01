#!/usr/bin/env nextflow

process SAMTOOLS_SORT {
    label 'process_single'
    container 'ghcr.io/bf528/samtools:latest'
    publishDir params.outdir, mode: 'copy'

    input:
    tuple val(sample_id), path(bam)

    output:
    tuple val(sample_id), path("*sorted.bam"), emit: sorted

    script:
    """
    samtools sort $bam > ${sample_id}.sorted.bam
    """

    stub:
    """
    touch ${sample_id}.stub.sorted.bam
    """
}