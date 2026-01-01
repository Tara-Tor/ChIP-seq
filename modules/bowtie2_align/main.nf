#!/usr/bin/env nextflow

process BOWTIE2_ALIGN {
    label 'process_high'
    container 'ghcr.io/bf528/bowtie2:latest'
    publishDir params.outdir, mode:'copy'

    input:
    tuple val(sample_id), path(reads)
    tuple val(consensus), path(index_dir)

    output:
    tuple val(sample_id), path("${sample_id}.bam"), emit: out

    script:
    """ 
   bowtie2 \
        -x ${index_dir}/${consensus} \
        -U ${reads} \
    | samtools view -bS - \
    > ${sample_id}.bam
    """

    stub:
    """
    touch ${sample_id}.bam
    """
}