#!/usr/bin/env bash

# Parsing arguments
for arg in "$@"; do
  shift
  case "$arg" in
    '--inputdir')   set -- "$@" '-i'   ;;
    '--geneset')   set -- "$@" '-s'   ;;
    '--outdir')     set -- "$@" '-o'   ;;
    '--gsea')     set -- "$@" '-x'   ;;
    *)          set -- "$@" "$arg" ;;
  esac
done

while getopts 'i:s:o:x:' OPTION; do
	case "$OPTION" in
		i)
			input_dir="$OPTARG"
			echo "RNK input dir: $input_dir"
			;;
		s)
			geneset="$OPTARG"
            echo "Using gene set file $geneset"
			;;

		o)
			outdir="$OPTARG"
            echo "Output will be saved in dir: $outdir"
			;;
		x)
			GSEA_script="$OPTARG"
            echo -e "Using GSEA script: $GSEA_script\n"
			;;
		?)
			echo "script usage: $basename $0) [-i --inputdir input_dir] [-s --geneset gene_set_file] [-o --outdir output_directory] [-x --gsea gsea_script_path]" >&2 # ">&2 redirects normal output to stderr"
			exit 1
			;;
	esac
done
shift "$(($OPTIND -1))"

# Some gene sets (e.g. KEGG) contain slashes, which cause errors when creating output
# Get gene set file extension

geneset_extension=$(basename $geneset | rev | cut -d "." -f 1 | rev)

sed 's/\//-/g' $geneset > $outdir/processed_geneset.$geneset_extension

# Exclude .rnk files inside edb/ folders, which are result folders
rnk_list=( $(find $input_dir -name "*.rnk" | grep -wv "edb") )
n_comparisons=${#rnk_list[@]}
echo "Found $n_comparisons rnk files."

# Use RNK file names minus the extension as analysis names
# xargs -L1 passes 1 argument at a time
analysis_names=( $(find $input_dir -name "*.rnk" | grep -wv "edb" | xargs -L1 basename | cut -d "." -f 1) )

# Build a CSV file with the paths of all input files for each run
echo "Building CSV file with inputs..."
echo "rnk,gene_set,analysis_name,outdir" > $outdir/gsea_parameters.csv

for((i=0;i<$n_comparisons;i++)); do  
	echo "$(readlink -f "${rnk_list[i]}"),$(readlink -f "$outdir/processed_geneset.$geneset_extension"),"${analysis_names[i]}",$(readlink -f "$outdir")" >> $outdir/gsea_parameters.csv
done

echo -e "\nParameters file generated correctly, starting GSEA runs..."
n_lines=$(wc -l < $outdir/gsea_parameters.csv)
n_runs=$(($n_lines-1))
echo "$n_runs GSEA preranked runs will be processed"

for ((i=2;i<=$n_lines;i++))
do
	RNK=$(cat $outdir/gsea_parameters.csv | awk -v line=$i -F, 'FNR == line {print $1}')
	GENESET=$(cat $outdir/gsea_parameters.csv | awk -v line=$i -F, 'FNR == line {print $2}')
	NAME=$(cat $outdir/gsea_parameters.csv | awk -v line=$i -F, 'FNR == line {print $3}')
	GSEA_OUTDIR=$(cat $outdir/gsea_parameters.csv | awk -v line=$i -F, 'FNR == line {print $4}')

	echo "Running GSEA preranked with the following inputs:"
    echo "RNK: $RNK"
    echo "Gene set: $GENESET"
    echo "Analysis name: $NAME"
    echo "Output dir: $GSEA_OUTDIR"

	bash "$GSEA_script" GSEAPreranked \
		-gmx "$GENESET" \
		-collapse No_Collapse \
		-mode Abs_max_of_probes \
		-norm meandiv \
        -nperm 1000 \
		-rnd_seed timestamp \
		-rnk "$RNK" \
		-rpt_label "$NAME" \
		-create_svgs false \
		-include_only_symbols true \
		-make_sets true \
		-plot_top_x 20 \
		-set_max 500 \
		-set_min 15 \
		-zip_report false \
		-out "$GSEA_OUTDIR"
done