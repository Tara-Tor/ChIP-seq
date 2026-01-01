#!/usr/bin/env nextflow

process TRIM {
    label 'process_medium'
    container 'ghcr.io/bf528/trimmomatic:latest'
    publishDir params.outdir

    input:
    tuple val(sample_id), path(read)
    val adapter_file

    output:
    tuple val(sample_id),
        path("${sample_id}.trimmed.fastq.gz"), emit: out,
        path("${sample_id}.trim.log")
          
          

    script:
    """
    trimmomatic SE \
        -threads ${task.cpus} \
        $read \
        ${sample_id}.trimmed.fastq.gz \
        ILLUMINACLIP:${adapter_file}:2:30:10 \
        LEADING:3 \
        TRAILING:3 \
        SLIDINGWINDOW:4:15 \
        MINLEN:36 \
        2> ${sample_id}.trim.log
    """

    stub:
    """
    touch ${sample_id}.trim.log
    touch ${sample_id}.trimmed.fastq.gz
    """
}
