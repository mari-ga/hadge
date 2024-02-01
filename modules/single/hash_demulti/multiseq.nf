#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

process multi_seq {
    publishDir "$projectDir/$params.outdir/$params.mode/hash_demulti/multiseq", mode:'copy'
    label 'small_mem'

    conda 'conda-forge::r-seurat conda-forge::r-argparse'

    input:
        each rdsObject
        each quantile
        each autoThresh
        each maxiter
        each qrangeFrom
        each qrangeTo
        each qrangeBy
        each verbose
        val assay
        val objectOutMulti
        val assignmentOutMulti

    output:
        path "multiseq_${task.index}"

    script:
        def autoThr = autoThresh != 'False' ? ' --autoThresh' : ''
        def verb = verbose != 'False' ? ' --verbose' : ''

        """
        mkdir multiseq_${task.index}
        MultiSeq.R --seuratObjectPath $rdsObject  --assay $assay --quantile $quantile $autoThr --maxiter $maxiter --qrangeFrom $qrangeFrom --qrangeTo $qrangeTo --qrangeBy $qrangeBy $verb --objectOutMulti $objectOutMulti --assignmentOutMulti $assignmentOutMulti --outputdir multiseq_${task.index}
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

workflow multiseq_hashing {
   take:
        rdsObject
   main:
        quantile = split_input(params.quantile_multi)
        autoThresh = split_input(params.autoThresh)
        maxIter = split_input(params.maxiter)
        qrangeFrom = split_input(params.qrangeFrom)
        qrangeTo = split_input(params.qrangeTo)
        qrangeBy = split_input(params.qrangeBy)
        verbose = split_input(params.verbose_multiseq)
        assay = params.assay
        objectOutMulti = params.objectOutMulti
        assignmentOutMulti = params.assignmentOutMulti
        multi_seq(rdsObject, quantile, autoThresh, maxIter, qrangeFrom, qrangeTo, qrangeBy, verbose, assay, objectOutMulti, assignmentOutMulti)
   emit:
        multi_seq.out.collect()
}
