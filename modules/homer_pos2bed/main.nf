#!/usr/bin/env nextflow

process POS2BED {
    label 'process_high'
    container 'ghcr.io/bf528/homer_samtools:latest'
    publishDir params.outdir

    input:
    path exon_files

    output:
    path "verse_concat.csv"

    script:
    """
    verse_concat.py -i ${exon_files.join(' ')} -o verse_concat.csv
    """


    stub:
    """
    touch ${homer_txt.baseName}.bed
    """
}


