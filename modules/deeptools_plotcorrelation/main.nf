#!/usr/bin/env nextflow

process PLOTCORRELATION {
    label 'process_low'
    container 'ghcr.io/bf528/deeptools:latest'
    publishDir "${params.outdir}/correlation", mode: 'copy'

    input:
    path matrix
    val corr_method
    val plot_type

    output:
    path "*.png" , emit: plot
    path "correlation_matrix.tab", emit: table
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:

    def args = task.ext.args ?: ''
    def method = corr_method ?: 'spearman'
    def type = plot_type ?: 'heatmap'
    def prefix = "correlation_${method}_${type}"

    """
    plotCorrelation \\
        --corData ${matrix} \\
        --corMethod ${method} \\
        --whatToPlot ${type} \\
        --plotFile ${prefix}.png \\
        --outFileCorMatrix correlation_matrix.tab \\
        --plotTitle "Sample Correlation (${method})" \\
        --removeOutliers \\
        --colorMap RdYlBu_r \\
        --plotNumbers \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deeptools: \$(plotCorrelation --version 2>&1 | sed -e "s/plotCorrelation //g")
    END_VERSIONS
    """

    stub:
    
    def method = corr_method ?: 'spearman'
    def type = plot_type ?: 'heatmap'
    def prefix = "correlation_${method}_${type}"
    
    """
    touch ${prefix}.png
    touch correlation_matrix.tab
    touch versions.yml
    """
}






