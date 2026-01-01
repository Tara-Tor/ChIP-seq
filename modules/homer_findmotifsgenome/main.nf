#!/usr/bin/env nextflow

process FIND_MOTIFS_GENOME {
    label 'process_high'
    container 'ghcr.io/bf528/homer_samtools:latest'
    publishDir "${params.outdir}/motif_enrichment", mode: 'copy'

    input:
    path peaks
    path genome_fasta

    output:
    path "motif_output", emit: results_dir
    path "motif_output/homerResults.html", emit: denovo_html
    path "motif_output/knownResults.html", emit: known_html
    path "motif_output/homerMotifs.all.motifs", emit: denovo_motifs
    path "motif_output/knownResults.txt", emit: known_results
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def motif_size = 200

   """
    # Create output directory
    mkdir -p motif_output
    
    # Run HOMER motif enrichment analysis
    findMotifsGenome.pl \\
        ${peaks} \\
        ${genome_fasta} \\
        motif_output \\
        -size ${motif_size} \\
        -mask \\
        -p ${task.cpus} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        homer: \$(echo \$(homer 2>&1) | grep -o 'v[0-9.]*' | sed 's/v//')
    END_VERSIONS
    """


    stub:
    """
    mkdir -p motif_output
    touch motif_output/homerResults.html
    touch motif_output/knownResults.html
    touch motif_output/homerMotifs.all.motifs
    touch motif_output/knownResults.txt
    touch versions.yml
    """
}


