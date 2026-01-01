#!/usr/bin/env nextflow

process BEDTOOLS_INTERSECT {
    label 'process_low'
    container 'ghcr.io/bf528/bedtools:latest'
    publishDir "${params.outdir}/reproducible_peaks", mode: 'copy'

    input:
    path bed_files

    output:
    path "reproducible_peaks.bed", emit: peaks
    path "peak_stats.txt", emit: stats
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def beds = bed_files instanceof List ? bed_files : [bed_files]
    def bed1 = bed_files[0]
    def bed2 = bed_files[1]
    
    """
     # Clean BED files: skip header lines and ensure proper format
    # Skip lines starting with # or containing header keywords
    awk 'BEGIN{OFS="\\t"} 
        !/^#/ && !/^Peak/ && NF>=6 && \$2~/^[0-9]+\$/ && \$3~/^[0-9]+\$/ {
            print \$1, \$2, \$3, \$4, \$5, \$6
        }' ${bed1} > clean_bed1.bed
    
    awk 'BEGIN{OFS="\\t"} 
        !/^#/ && !/^Peak/ && NF>=6 && \$2~/^[0-9]+\$/ && \$3~/^[0-9]+\$/ {
            print \$1, \$2, \$3, \$4, \$5, \$6
        }' ${bed2} > clean_bed2.bed
    
    # Check if files have content
    if [ ! -s clean_bed1.bed ] || [ ! -s clean_bed2.bed ]; then
        echo "Error: One or both cleaned BED files are empty" >&2
        exit 1
    fi
    
     # Reciprocal overlap approach
    bedtools intersect \\
        -a clean_bed1.bed \\
        -b clean_bed2.bed \\
        -f 0.50 \\
        -r \\
        ${args} \\
        > reproducible_peaks.bed
    
    # Generate statistics
    echo "Peak Reproducibility Statistics" > peak_stats.txt
    echo "=================================" >> peak_stats.txt
    echo "" >> peak_stats.txt
    echo "Replicate 1 peaks: \$(wc -l < clean_bed1.bed)" >> peak_stats.txt
    echo "Replicate 2 peaks: \$(wc -l < clean_bed2.bed)" >> peak_stats.txt
    echo "Reproducible peaks: \$(wc -l < reproducible_peaks.bed)" >> peak_stats.txt
    echo "" >> peak_stats.txt
    echo "Reproducibility rate: \$(awk -v rep=\$(wc -l < reproducible_peaks.bed) -v total=\$(wc -l < clean_bed1.bed) 'BEGIN {printf "%.2f%%", (rep/total)*100}')" >> peak_stats.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bedtools: \$(bedtools --version | sed -e "s/bedtools v//g")
    END_VERSIONS
    """

    stub:
    """
    touch intersect.bed
    touch peak_stats.txt
    touch versions.yml
    """
}