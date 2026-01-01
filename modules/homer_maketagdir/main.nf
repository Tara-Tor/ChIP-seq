#!/usr/bin/env nextflow

process TAGDIR {
    label 'process_medium'
    container 'ghcr.io/bf528/homer_samtools:latest'
    publishDir "${params.outdir}/homer/tagdirs", mode: 'copy'

    input:
    tuple val(sample_id), path(bam)

    output:
    tuple val(sample_id), path("${sample_id}_tagdir"), emit: tagdir
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def format = '-format sam'
    
    """
    makeTagDirectory \\
        ${sample_id}_tagdir \\
        ${bam} \\
        ${format} \\
        ${args}
        
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        homer: \$(echo \$(homer 2>&1) | grep -o 'v[0-9.]*' | sed 's/v//')
    END_VERSIONS
    """


    stub:
    """
    mkdir -p ${sample_id}_tagdir
    touch ${sample_id}_tagdir/tagInfo.txt
    touch versions.yml
    """
}


