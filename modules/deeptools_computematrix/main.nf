#!/usr/bin/env nextflow

process COMPUTEMATRIX {
    label 'process_medium'
    container 'ghcr.io/bf528/deeptools:latest'
    publishDir "${params.outdir}/gene_profiles", mode: 'copy'

    input:
    tuple val(sample_id), path(bigwig)
    path gene_bed

    output:
    tuple val(sample_id), path("${sample_id}_matrix.gz"), emit: matrix
    path "${sample_id}_matrix.tab" , emit: matrix_tab
    path "versions.yml", emit: versions 

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    computeMatrix scale-regions \\
        --regionsFileName ${gene_bed} \\
        --scoreFileName ${bigwig} \\
        --outFileName ${sample_id}_matrix.gz \\
        --outFileNameMatrix ${sample_id}_matrix.tab \\
        --beforeRegionStartLength ${params.window} \\
        --afterRegionStartLength ${params.window} \\
        --regionBodyLength 5000 \\
        --numberOfProcessors ${task.cpus} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deeptools: \$(computeMatrix --version | sed -e "s/computeMatrix //g")
    END_VERSIONS
    """

    stub:
    """
    touch ${sample_id}_matrix.gz
    touch ${sample_id}_matrix.tab
    touch versions.yml
    """
}