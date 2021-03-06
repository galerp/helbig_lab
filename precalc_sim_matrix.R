library(tidyverse)
library(memoise)

start <- Sys.time()
source("hpo_dist_helpers.R")

message("\n  Sim score file is read. Permutation Analysis is to be followed \n  \n ")
rownames(sim_score) = names(sim_score)


num_iterations = input.yaml$num_of_iterations

n2_100k <- sim_pat_draw(sim_score, 2,num_iterations)
n3_100k <- sim_pat_draw(sim_score, 3,num_iterations)
n4_100k <- sim_pat_draw(sim_score, 4,num_iterations)
n5_100k <- sim_pat_draw(sim_score, 5,num_iterations)
n7_100k <- sim_pat_draw(sim_score, 7,num_iterations)


###########
#STEP 4: Generate P-values for Genes

###########

message("\n Permutation is done. p-value for the genes is calculated \n \n  ")

names(variant)[1] <- "famID"
variant <- variant %>% mutate(famID = gsub("-","_", famID))

famIDs_var <- variant$famID %>% unique  %>% as.data.frame %>% 
  dplyr::rename('famID' = '.') %>% dplyr::mutate(var = "variant")

famIDs_sim <- sim_score %>% rownames %>% as.data.frame %>% 
  dplyr::rename('famID' = '.') %>%  dplyr::mutate(sim = "sim_score")

fam_combined <- famIDs_sim %>%  dplyr::full_join(famIDs_var)


#Filtering data
##Trios without sim_scores and without variants
no_sim <- as.vector(fam_combined$famID[is.na(fam_combined$sim) == TRUE])
no_var <- as.vector(fam_combined$famID[is.na(fam_combined$var) == TRUE])
#Trios with sim_scores
all_sim <- as.vector(fam_combined$famID[is.na(fam_combined$sim) == FALSE])
variant_sim <- variant %>% filter(famID %in% all_sim)


denovo <- denovo_calc(variant_sim)

#Table of denovos with famID and gene
tab1 <- denovo %>%  dplyr::select(famID, Gene.refGene) %>% unique


#list of all genes
all_genes <- tab1 %>%  dplyr::count(Gene.refGene) %>% 
  dplyr::rename(gene = Gene.refGene, Freq = n) %>% 
  filter(Freq > 1)


#Creating dataframe of similarity comparisons with every combination of patient pairs 
##with the same denove gene

#initialize with first gene
pair_corrected <- gene_df(all_genes$gene[1])

#Create for all genes
for (i in 2:nrow(all_genes)){
  temp <- gene_df(all_genes$gene[i])
  pair_corrected <- pair_corrected %>% bind_rows(temp)
}



#Determine number of pairs per gene
gene_x <- unique(pair_corrected$gene)

gene_count <- as.data.frame(matrix(ncol=9,nrow=length(gene_x))) 

names(gene_count) <- c("gene","n_pats","pairs","av_sim","median_sim","mode_sim","p_av","p_median","p_mode")

gene_count <- gene_count %>% mutate(gene = gene_x)


#Finding the average, median, and mode similarity,for each gene in the cohort
#########
#Find the p_value for each gene's similarity
## using the average, median, and mode similarity,for each gene from gene_count table
#########

#loop through each gene for p_av, p_med
gene_stat = gene_compute(gene_count) 


write.csv(gene_stat,paste0(input.yaml$output_dir,"/gene_count.csv"),row.names = F)
message("\n  The Entire script is now run successfully. Please find the Final output file gene_count.csv in the output directory \n ")
stop = Sys.time()
stop - start

