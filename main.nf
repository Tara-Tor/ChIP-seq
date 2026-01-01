#!/usr/bin/env nextflow

include {BEDTOOLS_INTERSECT} from './modules/bedtools_intersect'
include {BEDTOOLS_REMOVE} from './modules/bedtools_remove'
include {BOWTIE2_ALIGN} from './modules/bowtie2_align'
include {BOWTIE2_BUILD} from './modules/bowtie2_build'
include {BAMCOVERAGE} from './modules/deeptools_bamcoverage'
include {COMPUTEMATRIX} from './modules/deeptools_computematrix'
include {MULTIBWSUMMARY} from './modules/deeptools_multibwsummary'
include {PLOTCORRELATION} from './modules/deeptools_plotcorrelation'
include {PLOTPROFILE} from './modules/deeptools_plotprofile'
include {FASTQC} from './modules/fastqc'
include {ANNOTATE} from './modules/homer_annotatepeaks'
include {FIND_MOTIFS_GENOME} from './modules/homer_findmotifsgenome'
include {FINDPEAKS} from './modules/homer_findpeaks'
include {HOMER_PEAKCALLING} from './modules/homer_findpeaks/main.nf'
include {TAGDIR} from './modules/homer_maketagdir'
include {POS2BED} from './modules/homer_pos2bed'
include {MULTIQC} from './modules/multiqc'
include {SAMTOOLS_FLAGSTAT} from './modules/samtools_flagstat'
include {SAMTOOLS_IDX} from './modules/samtools_idx'
include {SAMTOOLS_SORT} from './modules/samtools_sort'
include {TRIM} from './modules/trimmomatic'

workflow {

    
    //Here we construct the initial channels we need
    
    Channel.fromPath(params.samplesheet)
    | splitCsv( header: true )
    | map{ row -> tuple(row.name, file(row.path)) }
    | set { read_ch }

    FASTQC(read_ch)

    BOWTIE2_BUILD(params.genome)

    adapter_ch = Channel.value(params.adapter_fa)

    TRIM(read_ch, adapter_ch)
    
    // Extract trimmed reads (remove log file from tuple)
    TRIM.out
        .map { sample_id, trimmed, log -> tuple(sample_id, trimmed) }
        .set { trimmed_reads_ch }

    BOWTIE2_ALIGN(trimmed_reads_ch, BOWTIE2_BUILD.out).set { bowtie2_align_ch }

    SAMTOOLS_FLAGSTAT(bowtie2_align_ch)

    SAMTOOLS_SORT( bowtie2_align_ch)

    SAMTOOLS_IDX(SAMTOOLS_SORT.out)

    FASTQC.out.zip
        .map { sample_id, zip -> zip }
        .mix(SAMTOOLS_FLAGSTAT.out
            .map{ sample_id, file -> file }
            )
        .mix(TRIM.out
            .map{ sample_id, trimmed, log -> log}
            )
        .collect()
        .set{multiqc_ch}

    MULTIQC(multiqc_ch)   
    multiqc_ch.view()

    BAMCOVERAGE(SAMTOOLS_IDX.out)

    bigwigs_ch = BAMCOVERAGE.out.bigwig
    .map { sample_id, bw -> bw }
    .collect() // collect all bigWig files

    //


    BAMCOVERAGE.out //collect and filter bigwig files for only IP samples
        .filter { sample_id, bigwig -> 
            sample_id.contains('IP_') && !sample_id.contains('subset')
        }
        .set { bigwigs_ip_ch }

    // Run computeMatrix for each IP sample
    COMPUTEMATRIX(
        bigwigs_ip_ch,
        params.ucsc_genes
    )
    
    // Run plotProfile on EACH matrix separately (no collect!)
    PLOTPROFILE(COMPUTEMATRIX.out.matrix)

    //

    MULTIBWSUMMARY(bigwigs_ch)

    PLOTCORRELATION(MULTIBWSUMMARY.out.matrix , 'spearman', 'heatmap') // Choosing Spearman Correlation because ChIP-seq data is usually not normally distributed, Spearman can handle non-linear relationships caused by seq depth differences, and PCR amp bias. Spearman can also handle extreme values better from high read counts at strong binding sights.

    TAGDIR( bowtie2_align_ch)
    
    HOMER_PEAKCALLING(TAGDIR.out.tagdir)
    // POS2BED(...) // The FINDPEAKS module already converts the peak output to bed format
    
    HOMER_PEAKCALLING.out.bed
        .map { sample_id, bed -> bed }
        .collect()
        .set { bed_ch }
    
    BEDTOOLS_INTERSECT(bed_ch) // I chose a reciprocal overlap approach that looks for a minimum of 50% of overlap between features in file A and file B (-f 0.50) and making the 50% overlap reciprocal, going in both directions (-r). This approach filters out false positives and artifacts while the recipricol nature prevents biases in peak differences between samples.
    
    BEDTOOLS_REMOVE(BEDTOOLS_INTERSECT.out.peaks, params.blacklist) // filter peaks through blacklist

    //
    ANNOTATE(BEDTOOLS_REMOVE.out.filtered_peaks, params.genome, params.gtf) // annotate peaks

    final_annotations = ANNOTATE.out.annotations // filtered and annotated peaks
    //

    FIND_MOTIFS_GENOME(BEDTOOLS_REMOVE.out.filtered_peaks, params.genome) // motif enrichment on filtered peaks

    motif_results = FIND_MOTIFS_GENOME.out.results_dir
}