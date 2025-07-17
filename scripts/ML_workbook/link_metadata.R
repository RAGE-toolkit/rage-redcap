## Code to link sequence names to metadata
### not straightforward because sequence names sometimes assigned before sample ids are designated so there are a range of possible ids. Need to match sequence ids to sample id, which is the central identifier

######
library(seqinr)
library(ape)
library(stringr)
library(dplyr)
#######

######## Sequences in fasta file
#sequences
seq=read.fasta("data/sequences/TZA_pre2018_fasta/multi_fasta/TZA_pre2018.fasta")
names(seq)
#extract seq ids
names(seq)= gsub("_.*","",names(seq))
names(seq)=gsub(".v1","",names(seq))
names(seq)=toupper(names(seq))

######## Metadata
#lab data
lab=read.csv("data/metadata/lab_data/WM_lab_newFormat_2023.csv", header=T, strip.white=T) 

#wisemonkey contact tracing data
wm=read.csv("data/metadata/contact_tracing/Tanzania_Animal_Contact_Tracing_20230605142322.csv", header=T, strip.white=T)


## standardise names e.g. remove whitespace, punctuation etc
lab$sample_id=toupper(lab$sample_id); wm$Sample.ID=toupper(wm$Sample.ID);lab$sample_labid=toupper(lab$sample_labid); lab$apha_sub=toupper(lab$apha_sub);lab$apha_rv=toupper(lab$apha_rv); lab$ngs_sampleid=toupper(lab$ngs_sampleid)
lab$sample_id=str_replace_all(lab$sample_id, fixed(" "), "")
lab$sample_id=str_replace_all(lab$sample_id, fixed("/"), "")
lab$sample_id=str_replace_all(lab$sample_id, fixed("."), "")
lab$ngs_sampleid=str_replace_all(lab$ngs_sampleid, fixed(" "), "")
lab$ngs_sampleid=str_replace_all(lab$ngs_sampleid, fixed("/"), "")
lab$ngs_sampleid=str_replace_all(lab$ngs_sampleid, fixed("."), "")
lab$apha_sub=str_replace_all(lab$apha_sub, fixed(" "), "")
lab$apha_rv=str_replace_all(lab$apha_rv, fixed(" "), "")
lab$sample_labid=str_replace_all(lab$sample_labid, fixed(" "), "")
lab$sample_id=str_replace_all(lab$sample_id, fixed("/"), "")
wm$Sample.ID=str_replace_all(wm$Sample.ID, fixed(" "), "")
wm$Sample.ID=str_replace_all(wm$Sample.ID, fixed("/"), "")


##### Connect sequences to lab data
# check for best id column
sum(names(seq) %in% lab$ngs_sampleid) 
sum(names(seq) %in% lab$sample_id) 
sum(names(seq) %in% lab$sample_labid) ###most matches
sum(names(seq) %in% lab$apha_sub) 
sum(names(seq) %in% lab$apha_rv) 
sum(names(seq) %in% lab$ngs_sampleid) 

## 2 stage match, first by sample lab id
lab1=lab[match(names(seq),lab$sample_labid,nomatch =0),]
reduce1=names(seq)[which(!names(seq) %in% lab$sample_labid)]

## then by ngs sample id
sum(reduce1%in% lab$ngs_sampleid)
lab2=lab[match(reduce1,lab$ngs_sampleid,nomatch =0),]
reduce2=reduce1[which(!reduce1 %in% lab$ngs_sampleid)]
length(reduce2) # captures all

# combine lab data
seq_lab=rbind(lab1,lab2)

## manual correction SD648, one row should be the metagenomic sample data
sd648meta=lab[which(lab$sample_id=="SD648" & lab$ngs_library_type=="metagenomic"),]
seq_lab=seq_lab[-(which(seq_lab$sample_id=="SD648")[1]),]
seq_lab_final=rbind(seq_lab,sd648meta)

write.csv(seq_lab_final,"outputs/n302_metadata/n302_lab_metadata.csv", row.names = F)

##### Connect sequences to epi (contact tracing) data
## link lab to epi data
sum(seq_lab_final$sample_id %in% wm$Sample.ID)

## 2 stages
wm1=wm[match(seq_lab_final$sample_id,wm$Sample.ID,nomatch =0),]
lab.reduce=seq_lab_final$sample_id[which(!seq_lab_final$sample_id%in% wm$Sample.ID)] ## only sample replicates left i.e. if salivary gland and brain samples taken then lab sample id has SG appended, or A for brain


# remove the SG/A to search, then add back in again as sample id in CT
wm2=wm[match(gsub("SG", "",lab.reduce),wm$Sample.ID,nomatch =0),]
wm2$Sample.ID=paste0(wm2$Sample.ID,"SG")
lab.reduce2=lab.reduce[which(!gsub("SG|A", "",lab.reduce)%in% wm$Sample.ID)] 

# only SD311A left with no match, which has a long descriptive id in WM: SD311 (SD311A and SD311B also, one is salivary glands in RNAlater)
# add manually
wm3=wm[grep("SD311",wm$Sample.ID),]

## combine WM data
all_wm=rbind(wm1,wm2,wm3)
write.csv(all_wm,"outputs/n302_metadata/n302_epi_metadata.csv", row.names = F)

## combined epi and lab data:
wm_lab=left_join(seq_lab_final,wm, by = c("sample_id" = "Sample.ID"))
write.csv(wm_lab,"outputs/n302_metadata/n302_labepi_metadata.csv", row.names = F)


