# Introduction

The scripts in this repository allow you to automatically perfom preranked GSEA runs using RNK files as input (see https://software.broadinstitute.org/cancer/software/gsea/wiki/index.php/Data_formats#RNK:_Ranked_list_file_format_.28.2A.rnk.29).  
In addition, you can automatically generate RNK files from DESeq2 DDS objects, or from differential expression results tables.

## Running preranked GSEA
The *runPrerankedGSEA.sh* script allows you to run preranked GSEA using all RNK files found in a directory. The following parameters are neded:  

--inputdir or -i: the directory containing the RNK files (recursive search, will return RNK files in subdirectories too).  
--geneset or -s: path to a gene set file in GMX or GMT format.  
--outdir or -o: path to the output folder where results will be saved.  
--gsea or -x: path to the *gsea.sh* script, included in GSEA desktop, available at https://www.gsea-msigdb.org/gsea/downloads.jsp  

Within the output directory, results folder named after their corresponding RNK file will be created. In addition, a CSV file summarising the RNK file, gene set file, analysis name and output directory for each run will be generated.  
The gene identifier format in RNK files needs to match that of the gene set file.

## Generating RNK files
The *generateGSEAinputs.R* script allows generating a RNK file from a DESeq2 DDS object, or a table containing differential expression results. It uses the following parameters (positional arguments):  
Dependencies: R packages 'magrittr', 'biomaRt', 'dplyr' and 'tibble'.  
  
1) Whether to use a DDS object in RDS format (type 'dds') or a table in CSV format (type 'table') as input. If using a table, gene names must be located in the first column.  
2) The path to the RDS or CSV file.  
3) The path to the output directory where the RNK file will be saved.  
4) The desired file name for the RNK file.  
5) The column used for gene ranking (e.g. 'stat').  
  
The following arguments are **optional** and are only needed if you wish to translate from one gene ID format to another, for which the 'biomaRt' R package will be used. This is useful if you have downloaded a gene set that contains gene identifiers in a different format to your results. Currenlty, only mouse and human gene IDs are supported for automatic translation (see parameter 9) to provide your own).  
6) The used gene ID format. Any format available in mmusculus_gene_ensembl and hsapiens_gene_ensembl biomaRt datasets are accepted. Popular examples are *ensembl_gene_id*, *external_gene_name* (gene symbols), or *entrezgene_id* (NCBI gene identifiers).  
7) The desired gene ID format.  
8) Species. 'mm', 'Mm' or 'mouse' for *Mus musculus* and 'hs', 'Hs' or 'human' for *Homo sapiens*.  
9) If you want to supply your own translation file instead, add the path to a data.frame saved as an RDS object as the 9th parameter. This data frame must contain a column named like the 7th argument.  

## Generating multiple RNK files
If you want to generate multiple RNK files from DDS objects or results tables, the *multi_generateGSEAinputs.sh* script allows you to do so. It uses the following parameters:  
  
--inputdir or -i: the directory containing the DDS objects in RDS format or the results tables (recursive search).  
--outdir or -o: the directory where the RNK files will be saved.  
--rankcol or -r: the name of the column used for ranking.  
  
Optional parameters: only for gene ID format translation.  
--idformat or -f: the input gene ID format.  
--targetidformat or -t: the desired gene ID format.  
--species: 'mm', 'Mm' or 'mouse' for *Mus musculus* and 'hs', 'Hs' or 'human' for *Homo sapiens*.  
--idfile: If you want to supply your own translation file instead, add the path to a data.frame saved as an RDS object. This data frame must contain a column named like the --idformat argument.  
