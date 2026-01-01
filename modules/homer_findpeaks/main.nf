#!/usr/bin/env nextflow

process FINDPEAKS {
    label 'process_medium'
    container 'ghcr.io/bf528/homer_samtools:latest'
    publishDir "${params.outdir}/homer/peaks", mode: 'copy'

    input:
    tuple val(ip_sample_id), path(ip_tagdir)
    tuple val(control_sample_id), path(control_tagdir)

    output:
    tuple val(ip_sample_id), path("${ip_sample_id}_peaks.txt"), emit: peaks
    tuple val(ip_sample_id), path("${ip_sample_id}_peaks.bed"), emit: bed
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def style = '-style factor'
    def control_cmd = control_tagdir ? "-i ${control_tagdir}" : ''

    """
    findPeaks \\
        ${ip_tagdir} \\
        ${style} \\
        ${control_cmd} \\
        -o ${ip_sample_id}_peaks.txt \\
        ${args}

    # Convert to proper 6-column BED format
    # Skip header (NR>1), output exactly 6 tab-separated columns
    awk 'BEGIN{OFS="\\t"} NR>1 {print \$2, \$3, \$4, \$1, \$6, \$5}' \\
        ${ip_sample_id}_peaks.txt | \\
        awk 'BEGIN{OFS="\\t"} {print \$1, \$2, \$3, \$4, \$5, \$6}' \\
        > ${ip_sample_id}_peaks.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        homer: \$(echo \$(homer 2>&1) | grep -o 'v[0-9.]*' | sed 's/v//')
    END_VERSIONS
    """



    stub:
    """
    touch ${ip_sample_id}_peaks.txt
    touch ${ip_sample_id}_peaks.bed
    touch versions.yml
    """
}


workflow HOMER_PEAKCALLING {
    take:
    tagdirs
    
    main:
    ch_versions = Channel.empty()
    
    tagdirs
        .branch {
            ip: it[0].contains('IP_')
            input: it[0].contains('INPUT_')
        }
        .set { separated_tagdirs }
    
    separated_tagdirs.ip
        .map { sample_id, tagdir ->
            def replicate = (sample_id =~ /rep(\d+)/)[0][1]
            tuple(replicate, sample_id, tagdir)
        }
        .set { ip_with_rep }
    
    separated_tagdirs.input
        .map { sample_id, tagdir ->
            def replicate = (sample_id =~ /rep(\d+)/)[0][1]
            tuple(replicate, sample_id, tagdir)
        }
        .set { input_with_rep }
    
    ip_with_rep
        .join(input_with_rep, by: 0)
        .multiMap { replicate, ip_id, ip_tagdir, input_id, input_tagdir ->
            ip: tuple(ip_id, ip_tagdir)
            input: tuple(input_id, input_tagdir)
        }
        .set { paired_channels }
    
    FINDPEAKS(
        paired_channels.ip,
        paired_channels.input
    )
    ch_versions = ch_versions.mix(FINDPEAKS.out.versions.first())
    
    emit:
    peaks    = FINDPEAKS.out.peaks
    bed      = FINDPEAKS.out.bed
    versions = ch_versions
}