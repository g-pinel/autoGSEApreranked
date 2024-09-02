#!/usr/bin/env Rscript

`%>%` <- magrittr::`%>%`

# Arguments parsing
args = commandArgs(trailingOnly=TRUE)

print(paste0("Number of provided arguments: ", length(args)))

if(length(args) < 5){
  stop("Call 'Rscript generateGSEAinputs' with the following arguments:
# arg1: whether to use dds or results table
# arg2: the dds object as RDS or the results table as csv
# arg3: output dir
# arg4: output file name
# arg5: the column used for ranking genes
# arg6 (optional): gene id format
# arg7 (optional): target gene id format
# arg8 (optional): species"
# arg9 (optional): biomart id equivalencies file as RDS,
       , call.=FALSE)
}

input_format = args[1]
input_file = args[2]
outdir = args[3]
outfile = args[4]
ranking_column = args[5]
id_type = args[6]

# If optional parameters are provided, set up gene id format translation
if(length(args) > 6){
  
  target_id_type = args[7]
  species = args[8]
  id_translation = TRUE
  
  if(toupper(species) %in% c("MM", "MOUSE")){
    species = "mmusculus_gene_ensembl"
  }else if(toupper(species) %in% c("HS", "HUMAN")){
    species = "hsapiens_gene_ensembl"
  }
}else{
  id_translation = FALSE
}

if(length(args) > 8){
  id_translation_file <- readRDS(args[9])
}

print("Arguments used:")
for(i in 1:length(args)){
  print(args[i])
}

# Load packages
# library(tidyverse)
# library(DESeq2)
# library(biomaRt)

# Function definition
getRNK <- function(input_table, outdir, filename){
  
  rnk <- input_table %>%
    tibble::rownames_to_column("gene_id") %>% 
    dplyr::distinct(gene_id, .keep_all = T) %>%
    dplyr::mutate(stat = ifelse(is.na(padj), 0, stat)) %>%  # Even with a large absolute statistic, those genes with a lot of variability (e.g. caused by an outlier) should be corrected to 0
    dplyr::select(c("gene_id", ranking_column)) %>% 
    dplyr::arrange_at(ranking_column)
  
  write.table(x = rnk, file = paste0(outdir, "/", filename), sep = "\t", row.names = F, col.names = F)
  
  #return(rnk)
}

# Input data preprocessing
if(input_format == "dds"){
  
  dds <- readRDS(input_file)
  res_input <- as.data.frame(DESeq2::results(dds))

  }else if(input_format == "table"){
    
    # Read file, format with first column as row names
    res_input <- data.table::fread(input_file)
    gene_ids_temp <- res_input %>% dplyr::pull(1)
    res_input <- res_input %>% dplyr::select(-1)
    rownames(res_input) <- gene_ids_temp
}

if(id_translation){
  
  print("Starting ID translation...")
  
  gene_ids <- rownames(res_input)

  if(length(args) > 8){
    translation_df <- id_translation_file
  }else{
    
    ensembl <- biomaRt::useEnsembl(biomart = "genes")
    ensembl <- biomaRt::useDataset(dataset = species, mart = ensembl)
    
    translation_df <- biomaRt::getBM(attributes=c(id_type, target_id_type),
                                filters = id_type, 
                                values = gene_ids,
                                mart = ensembl)
    
    saveRDS(translation_df, "translation_df.RDS")
  }

  res_input <- res_input %>% 
    tibble::rownames_to_column(id_type) %>%
    dplyr::left_join(translation_df, by = id_type) %>% 
    dplyr::distinct_at(ncol(.), .keep_all = TRUE) %>% # Remove duplicates
    dplyr::filter(!is.na(.[[ncol(.)]])) %>% # Remove NA
    tibble::column_to_rownames(target_id_type) %>% # Set target ids as rownames
    dplyr::select(-1)  # Remove old identifiers
}

getRNK(input_table = res_input, outdir = outdir, filename = outfile)
