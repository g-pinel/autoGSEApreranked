#!/usr/bin/env bash

# Count arguments (flags are also counted)
n_arguments=$#

id_translation_file=""

# Parsing arguments
for arg in "$@"; do
  shift
  case "$arg" in
    '--inputdir')   set -- "$@" '-i'   ;;
    '--outdir')     set -- "$@" '-o'   ;;
    '--rankcol')   set -- "$@" '-r'   ;;
    '--idformat')     set -- "$@" '-f'   ;;
    '--targetidformat')     set -- "$@" '-t'   ;;
    '--species')     set -- "$@" '-s'   ;;
    '--idfile')     set -- "$@" '-d'   ;;
    *)          set -- "$@" "$arg" ;;
  esac
done

while getopts 'i:o:r:f:t:s:d:' OPTION; do
	case "$OPTION" in
		i)
			inputdir="$OPTARG"
			echo "Input dir: $input_dir"
			;;
		o)
			outdir="$OPTARG"
            echo "Output will be saved in dir: $outdir"
			;;
		r)
			ranking_column="$OPTARG"
            echo "Ranking column: $ranking_column"
			;;
		f)
			id_type="$OPTARG"
            echo "Input Gene ID format: $id_type"
			;;
    	t)
			target_id_type="$OPTARG"
            echo "target Gene ID format: $target_id_type"
			;;
      	s)
			species="$OPTARG"
            echo "Species: $species"
			;;
		d)
			id_translation_file="$OPTARG"
            echo -e "Using gene id format translation file: $id_translation_file\n"
			;;
		?)
			echo "script usage: $basename $0) [-i --inputdir input_dir] [-o --outdir output_directory] [-r --rankcol ranking_column] [-f --idformat Gene_ID_format] [-t --targetidformat target_Gene_ID_format] [-s --species species (mm/Mm/mouse or hs/Hs/human)] [-d --idfile Gene_ID_translation_file (optional)]" >&2 # ">&2 redirects normal output to stderr"
			exit 1
			;;
	esac
done
shift "$(($OPTIND -1))"

# Get all CSV and RDS files
input_file_list=( $(find "$inputdir" -type f -name "*.rds" -o -name "*.RDS" -o -name "*.csv") )

# Get analysis names from file names
outfile_list=( $(find "$inputdir" -type f -name "*.rds" -o -name "*.RDS" -o -name "*.csv" | xargs -L1 basename | cut -d "." -f 1 | xargs -I {} echo {}.rnk) )

# Determine input_format from file extension
extensions_list=( $(find "$inputdir" -type f -name "*.rds" -o -name "*.RDS" -o -name "*.csv" | xargs -L1 basename | cut -d "." -f 2) )

# Create array with input formats
input_format_list=( )

for((i=0;i<${#extensions_list[@]};i++)); do
    if [[ ${extensions_list[i]^^} = "RDS" ]]; then
        input_format_list+=("dds")
    elif [[ ${extensions_list[i],,} = "csv" ]]; then
        input_format_list+=("table")
    fi
done

# If there is no id translation file, first run once using biomaRt to generate it, then run the rest reusing it
if test -z "$id_translation_file"; then

    # Run first instance with id translation or not depending on provided arguments
    if test ! -z "$target_id_type"; then

        echo "First run will generate gene id translation file..."

        Rscript generateGSEAinputs.R \
            ${input_format_list[0]} \
            ${input_file_list[0]} \
            $outdir \
            ${outfile_list[0]} \
            $ranking_column \
            $id_type \
            $target_id_type \
            $species
    else

        echo "Running first file without id translation..."

        Rscript generateGSEAinputs.R \
            ${input_format_list[0]} \
            ${input_file_list[0]} \
            $outdir \
            ${outfile_list[0]} \
            $ranking_column
    fi

    echo "Running the rest of files..."

    # Run rest reusing the id translation file generated in the first run
    if test ! -z "$target_id_type"; then

        id_translation_file="translation_df.RDS"

        for((i=1;i<${#extensions_list[@]};i++)); do

            echo "Running rest of files reusing the gene id translation file"

            Rscript generateGSEAinputs.R \
                ${input_format_list[i]} \
                ${input_file_list[i]} \
                $outdir \
                ${outfile_list[i]} \
                $ranking_column \
                $id_type \
                $target_id_type \
                $species \
                $id_translation_file
        done
    # or without translation if not indicated by arguments
    else
        for((i=1;i<${#extensions_list[@]};i++)); do

            Rscript generateGSEAinputs.R \
                ${input_format_list[i]} \
                ${input_file_list[i]} \
                $outdir \
                ${outfile_list[i]} \
                $ranking_column
        done
    fi

# If a translation file is already provided, use it since the beginning
else
    for((i=0;i<${#extensions_list[@]};i++)); do

        echo Using provided gene id translation file...

        Rscript generateGSEAinputs.R \
                ${input_format_list[i]} \
                ${input_file_list[i]} \
                $outdir \
                ${outfile_list[i]} \
                $ranking_column \
                $id_type \
                $target_id_type \
                $species \
                $id_translation_file
    done
fi
