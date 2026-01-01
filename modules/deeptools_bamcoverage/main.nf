#!/usr/bin/env nextflow

process BAMCOVERAGE {
    label 'process_medium'
    container 'ghcr.io/bf528/deeptools:latest'
    publishDir params.outdir, mode: 'copy'

    input:
    tuple val(sample_id), path(bam), path(bai)

    output:
    tuple val(sample_id), path("${sample_id}.bw"), emit: bigwig

    script:
    """
    bamCoverage \
        -b $bam \
        -o ${sample_id}.bw \
        -bs 50 \
        -p ${task.cpus}
    """


    stub:
    """
    touch ${sample_id}.bw
    """
}