#!/usr/bin/env nextflow

process PLOTPROFILE {
    label 'process_low'
    container 'ghcr.io/bf528/deeptools:latest'
    publishDir "${params.outdir}/gene_profiles", mode: 'copy'

     input:
    tuple val(sample_id), path(matrix)
    
    output:
    tuple val(sample_id), path("${sample_id}_profile.png"), emit: plot
    path "${sample_id}_profile_data.tab", emit: data
    path "versions.yml", emit: versions
    
    when:
    task.ext.when == null || task.ext.when
    
    script:
    def args = task.ext.args ?: ''
    """
    plotProfile \\
        --matrixFile ${matrix} \\
        --outFileName ${sample_id}_profile.png \\
        --outFileNameData ${sample_id}_profile_data.tab \\
        --plotTitle "Gene Body Coverage - ${sample_id}" \\
        --yAxisLabel "Read Coverage" \\
        --colors blue \\
        --plotHeight 10 \\
        --plotWidth 12 \\
        ${args}
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deeptools: \$(plotProfile --version | sed -e "s/plotProfile //g")
    END_VERSIONS
    """


    stub:
    """
    touch ${sample_id}_profile.png
    touch ${sample_id}_profile_data.tab
    touch versions.yml
    """
}