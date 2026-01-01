#!/usr/bin/env nextflow

process BEDTOOLS_REMOVE {
    label 'process_low'
    container 'ghcr.io/bf528/bedtools:latest'
    publishDir "${params.outdir}/filtered_peaks", mode: 'copy'

    input:
    path peaks
    path blacklist

    output:
    path "intersect_peaks_filtered.bed", emit: filtered_peaks
    path "filtering_stats.txt", emit: stats
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

   """
    # Remove any peaks that overlap blacklisted regions (even 1bp overlap)
    # -A flag removes entire feature if ANY overlap with blacklist
    bedtools subtract \\
        -A \\
        -a ${peaks} \\
        -b ${blacklist} \\
        ${args} \\
        > intersect_peaks_filtered.bed
    
    # Generate filtering statistics
    echo "Blacklist Filtering Statistics" > filtering_stats.txt
    echo "===============================" >> filtering_stats.txt
    echo "" >> filtering_stats.txt
    echo "Peaks before filtering: \$(wc -l < ${peaks})" >> filtering_stats.txt
    echo "Peaks after filtering: \$(wc -l < intersect_peaks_filtered.bed)" >> filtering_stats.txt
    echo "Peaks removed: \$(awk -v before=\$(wc -l < ${peaks}) -v after=\$(wc -l < intersect_peaks_filtered.bed) 'BEGIN {print before - after}')" >> filtering_stats.txt
    echo "" >> filtering_stats.txt
    echo "Percentage retained: \$(awk -v after=\$(wc -l < intersect_peaks_filtered.bed) -v before=\$(wc -l < ${peaks}) 'BEGIN {printf "%.2f%%", (after/before)*100}')" >> filtering_stats.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bedtools: \$(bedtools --version | sed -e "s/bedtools v//g")
    END_VERSIONS
    """

    stub:
    """
    touch intersect_peaks_filtered.bed
    touch filtering_stats.txt
    touch versions.yml
    """
}