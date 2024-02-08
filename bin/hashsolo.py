#!/usr/bin/env python
from solo import hashsolo
import scanpy as sc
import matplotlib.pyplot as plt
import argparse
import pandas as pd

parser = argparse.ArgumentParser(description="Parser for HashSolo - Demultiplexing")

parser.add_argument(
    "--hto_data",
    help="Input directory containing hashing count matrix in 10x mtx format.",
)
parser.add_argument(
    "--priors",
    metavar="N",
    type=float,
    nargs=3,
    help="a list of prior for each hypothesis. \
                    The first element is prior for the negative hypothesis, \
                    second for the singlet hypothesis, third element for the doublet hypothesis",
    default=[0.01, 0.8, 0.19],
)
parser.add_argument(
    "--pre_existing_clusters",
    help="column in cell_hashing_adata.obs for how to break up demultiplexing",
    type=str,
    default=None,
)
parser.add_argument(
    "--clustering_data",
    help="input directory containing transcriptomic data in 10x mtx format.",
    type=str,
    default=None,
)
parser.add_argument(
    "--number_of_noise_barcodes",
    help="Number of barcodes to use to create noise distribution",
    type=int,
    default=None,
)
parser.add_argument(
    "--assignmentOutHashSolo",
    help="prefix name for CSV results",
    type=str,
    default="hash_solo",
)
parser.add_argument(
    "--plotOutHashSolo",
    help="prefix name for the JPG plot",
    type=str,
    default="hash_solo_plot",
)
parser.add_argument("--outputdir", help="Output directory")
args = parser.parse_args()
param_list = [
    ["hto_data", args.hto_data],
    ["prior_negative", args.priors[0]],
    ["prior_singlet", args.priors[1]],
    ["prior_doublet", args.priors[2]],
    ["pre_existing_clusters", args.pre_existing_clusters],
    ["clustering_data", args.clustering_data],
    ["number_of_noise_barcodes", args.number_of_noise_barcodes],
]

param_df = pd.DataFrame(param_list, columns=["Argument", "Value"])

if __name__ == "__main__":
    cell_hashing_data = sc.read_10x_mtx(args.hto_data, gex_only=False)
    if args.clustering_data is not None:
        trans_data = sc.read_10x_mtx(args.clustering_data)
        trans_data.var_names_make_unique()
        print("--------------------Get data-------------------------------")
        hashsolo.hashsolo(
            cell_hashing_data,
            priors=args.priors,
            clustering_data=trans_data,
            pre_existing_clusters=args.pre_existing_clusters,
            number_of_noise_barcodes=args.number_of_noise_barcodes,
        )
    else:
        print("--------------------Get data-------------------------------")
        hashsolo.hashsolo(
            cell_hashing_data,
            priors=args.priors,
            pre_existing_clusters=args.pre_existing_clusters,
            number_of_noise_barcodes=args.number_of_noise_barcodes,
        )
    print("--------------------Finished demultiplexing-------------------------------")

    print("------------------- Following Files are saved ----------------------------")
    print(args.assignmentOutHashSolo + "_res.csv")
    print(args.plotOutHashSolo + ".jpg")
    print("params.csv")
    cell_hashing_data.obs.to_csv(
        args.outputdir + "/" + args.assignmentOutHashSolo + "_res.csv"
    )
    hashsolo.plot_qc_checks_cell_hashing(cell_hashing_data)
    plt.savefig(args.outputdir + "/" + args.plotOutHashSolo + ".jpg", dpi=400)
    param_df.fillna("None", inplace=True)
    param_df.to_csv(args.outputdir + "/params.csv", index=False)
