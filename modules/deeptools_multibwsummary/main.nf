#!/usr/bin/env nextflow

process MULTIBWSUMMARY {
    label 'process_medium'
    container 'ghcr.io/bf528/deeptools:latest'
    publishDir "${params.outdir}/correlation", mode: 'copy'

    input:
    path bigwigs

    output:
    path "multibigwig_matrix.npz", emit: matrix
    path "raw_counts.tab", emit: counts
    path "versions.yml", emit: versions

    when: 
    task.ext.when == null || task.ext.when

    script:
    
    def args = task.ext.args ?: ''
    def bin_size = params.window ?: 2000
    """
    multiBigwigSummary bins \\
        --bwfiles ${bigwigs} \\
        --outFileName multibigwig_matrix.npz \\
        --outRawCounts raw_counts.tab \\
        --binSize ${bin_size} \\
        --numberOfProcessors ${task.cpus} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deeptools: \$(multiBigwigSummary --version | sed -e "s/multiBigwigSummary //g")
    END_VERSIONS
    """
    stub:
    """
    touch multibigwig_matrix.npz
    touch raw_counts.tab
    touch versions.yml
    """
}