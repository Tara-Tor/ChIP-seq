#!/usr/bin/env nextflow

process ANNOTATE {
    label 'process_medium'
    container 'ghcr.io/bf528/homer_samtools:latest'
    publishDir "${params.outdir}/peak_annotation", mode: 'copy'

    input:
    path peaks
    path genome_fasta
    path gtf


    output:
    path "annotated_peaks.txt", emit: annotations
    path "annotation_stats.txt", emit: stats
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    
   """
    # Annotate peaks using custom genome FASTA and GTF
    annotatePeaks.pl \\
        ${peaks} \\
        ${genome_fasta} \\
        -gtf ${gtf} \\
        -annStats annotation_stats.txt \\
        ${args} \\
        > annotated_peaks.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        homer: \$(echo \$(homer 2>&1) | grep -o 'v[0-9.]*' | sed 's/v//')
    END_VERSIONS
    """

    stub:
    """
    touch annotated_peaks.txt
    touch annotation_stats.txt
    touch versions.yml
    """
}



