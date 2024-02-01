#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process souporcell{
    publishDir "$projectDir/$params.outdir/$params.mode/gene_demulti/souporcell", mode: 'copy'
    label 'big_mem'
    
    container "shub://wheaton5/souporcell"
    
    input:
        each bam
        each barcodes
        each fasta
        each threads
        each clusters
        each ploidy
        each min_alt
        each min_ref
        each max_loci
        each restarts
        each common_variants
        each use_known_genotype
        each known_genotypes
        each known_genotypes_sample_names
        each skip_remap
        each ignore
        each souporcell_out

    output:
        path "souporcell_${task.index}"
    
    script:
        def bamfile = "-i $bam"
        def barcode = "-b $barcodes"
        def fastafile = "-f $fasta"
        def thread = "-t $threads"
        def cluster = "-k $clusters"
        def ploi = "--ploidy $ploidy"
        def minalt = "--min_alt ${min_alt}"
        def minref = "--min_ref ${min_ref}"
        def maxloci = "--max_loci ${max_loci}"
        def restart = restarts != 'None' ? "--restarts $restarts" : ''
     
        def commonvariant = (common_variants != 'None' & use_known_genotype != "True" & known_genotypes == 'None' )? "--common_variants ${common_variants}" : ''
        def commonvariant_name = (common_variants != 'None' & use_known_genotype != "True" & known_genotypes == 'None' ) ? file(common_variants).baseName : 'no_common_variants'

        def knowngenotype = (use_known_genotype == "True" & known_genotypes != 'None') ? "--known_genotypes ${known_genotypes}" : ''
        def knowngenotype_name = (use_known_genotype == "True" & known_genotypes != 'None') ? file(known_genotypes).baseName : 'no_known_genotypes'

        def knowngenotypes_sample = known_genotypes_sample_names != 'None' ? "--known_genotypes_sample_names ${known_genotypes_sample_names}" : ''
        def knowngenotype_sample_name = known_genotypes_sample_names != 'None' ? file(known_genotypes_sample_names).baseName : 'no_knowngenotypes_sample_names'

        def skipremap = skip_remap != 'False' ? "--skip_remap True" : ''
        def ign = ignore != 'False' ? "--ignore True" : ''
        def out = "souporcell_${task.index}/${souporcell_out}"
        
        """
        mkdir souporcell_${task.index}
        mkdir $out
        touch souporcell_${task.index}/params.csv
        echo -e "Argument,Value \n bamfile,${bam} \n barcode,${barcodes} \n fasta,${fasta} \n threads,${threads} \n clusters,${clusters} \n ploidy,${ploidy} \n min_alt,${min_alt} \n min_ref,${min_ref} \n max_loci,${max_loci} \n restarts,${restarts} \n common_variant,${commonvariant_name} \n known_genotype,${knowngenotype_name} \n known_genotype_sample,${knowngenotype_sample_name} \n skip_remap,${skip_remap} \n ignore,${ignore} " >> souporcell_${task.index}/params.csv
        souporcell_pipeline.py $bamfile $barcode $fastafile $thread $cluster $ploi $minalt $minref $maxloci $restart $commonvariant $knowngenotype $knowngenotypes_sample $skipremap $ign -o $out
        """
}


def split_input(input){
    if (input =~ /;/ ){
        Channel.from(input).map{ return it.tokenize(';')}.flatten()
    }
    else{
        Channel.from(input)
    }
}


workflow demultiplex_souporcell{
    take:
        bam
    main:
        barcodes = split_input(params.barcodes)
        fasta = split_input(params.fasta)
        threads = split_input(params.threads)
        clusters = split_input(params.nsamples_genetic)

        ploidy = split_input(params.ploidy)
        min_alt = split_input(params.min_alt)
        min_ref = split_input(params.min_ref)
        max_loci = split_input(params.max_loci)
        restarts = split_input(params.restarts)

        common_variants = split_input(params.common_variants_souporcell)
        use_known_genotype = split_input(params.use_known_genotype)
        known_genotypes = split_input(params.vcf_donor)
        known_genotypes_sample_names = split_input(params.known_genotypes_sample_names)
        skip_remap = split_input(params.skip_remap)
        ignore = split_input(params.ignore)
        souporcell_out = params.souporcell_out
     
        souporcell(bam, barcodes, fasta, threads, clusters, ploidy, min_alt, min_ref, max_loci, restarts, 
            common_variants, use_known_genotype, known_genotypes, known_genotypes_sample_names, skip_remap, 
            ignore, souporcell_out)
            
    emit:
        souporcell.out.collect()
}
