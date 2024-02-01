process preprocess {
    publishDir "$projectDir/$params.outdir/$params.mode/hash_demulti/preprocess", mode:'copy'
    label 'small_mem'

    conda 'conda-forge::r-seurat conda-forge::r-argparse'

    input:
        path hto_matrix, stageAs: 'hto_data'
        path umi_matrix, stageAs: 'rna_data'
        val hto_raw_or_filtered
        val rna_raw_or_filtered
        val ndelim
        each selection_method
        each number_features
        val assay
        each margin
        val normalisation_method
        val preprocess_out
        each gene_col

    output:
        path "preprocess_${task.index}_hto_${hto_raw_or_filtered}_rna_${rna_raw_or_filtered}"

    script:

    """
        mkdir preprocess_${task.index}_hto_${hto_raw_or_filtered}_rna_${rna_raw_or_filtered}
        pre_processing.R --fileUmi rna_data --fileHto hto_data --ndelim $ndelim \
                        --selectMethod $selection_method --numberFeatures $number_features --assay $assay \
                        --margin $margin --normalisationMethod $normalisation_method --OutputFile $preprocess_out \
                        --outputdir preprocess_${task.index}_hto_${hto_raw_or_filtered}_rna_${rna_raw_or_filtered} --gene_col $gene_col
    """

}

def split_input(input) {
    if (input =~ /;/) {
        Channel.from(input).map { return it.tokenize(';') }.flatten()
    }
    else {
        Channel.from(input)
    }
}

workflow preprocessing_hashing {
    take:
        hto_matrix
        rna_matrix
        hto_raw_or_filtered
        rna_raw_or_filtered
    main:
        sel_method = split_input(params.sel_method)
        ndelim = params.ndelim
        n_features = split_input(params.n_features)
        assay = params.assay
        margin = split_input(params.margin)
        norm_method = split_input(params.norm_method)
        out_file = params.preprocessOut
        gene_col = split_input(params.gene_col)
        preprocess(hto_matrix, rna_matrix, hto_raw_or_filtered, rna_raw_or_filtered, ndelim, sel_method, n_features, assay, margin, norm_method, out_file, gene_col)
    emit:
        preprocess.out.collect()
}
