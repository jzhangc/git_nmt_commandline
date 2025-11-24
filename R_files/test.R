setwd("/Users/jingzhang/Documents/git_repo/git_nmt_commandline/data/")


library(RBioFS)

SAMPLEID_VAR <- "subjectid"
GROUP_VAR <- "groupid"

config_list <- list(
  SAMPLEID_VAR = as.numeric("123"),
  LOGIC = eval(parse(text = "TRUE")),
  GROUP_VAR = "groupid"
)


raw_csv <- read.csv("/Users/jingzhang/Documents/git_repo/git_nmt_commandline/data/freq_4_beta_power.csv", stringsAsFactors = FALSE)
sample_group <- factor(raw_csv[, GROUP_VAR], levels = unique(raw_csv[, GROUP_VAR]))
sampleid <- raw_csv[, SAMPLEID_VAR]


CONTRAST <- c("PTSD-TC, mTBI-TC, PTSD-NTC, mTBI-NTC")
CONTRAST <- c("PTSD-TC")
contra_string <- unlist(strsplit(CONTRAST, split = ","))
contra_string <- gsub(" ", "", contra_string, fixed = TRUE) # remove all the white space
pasted_contrast <- paste0(contra_string, collapse = "-")
contrast_group <- unique(unlist(strsplit(pasted_contrast, split = "-", fixed = TRUE)))
if (!all(contrast_group  %in% as.character(unique(raw[, "groupid"])))) {
  cat("contrast_none_existent")
}


sample_group 



newo <- order(factor(sample_group, levels = contrast_group, ordered = TRUE))

raw_csv[newo, ]$groupid
