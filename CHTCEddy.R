#!/usr/bin/env Rscript
# Usage
# Rscript --vanilla CHTCEddy.R --csv Sample.csv --dag Sample.dag

# Initialization and options parsing.
rm(list = ls(all = T))
if(!require(optparse))
  install.packages('optparse')
library(optparse)

option_list = list(
  make_option(c("-c", "--csv"), 
              type = "character", 
              default = NULL, 
              help = "CSV file name", 
              metavar = "character"),
  make_option(c("-d", "--dag"), 
              type = "character", 
              default = "out.dag", 
              help = "output dag name [default = %default]", 
              metavar = "character")
)

opt_parser = OptionParser(option_list = option_list);
opt = parse_args(opt_parser)
if(is.null(opt$csv)){
  print_help(opt_parser)
  stop("A csv file with input information must be supplied.", 
       call. = F)
}
if(is.null(opt$dag))
  paste("Writing output dag to out.dag.")

csv = read.csv(opt$csv, stringsAsFactors = F)
submit = 'CHTCEddy.submit'
executable = 'CHTCEddy.sh'

# Writing the dag file.
sink(opt$dag)
for (i in 1:nrow(csv)){
  job = csv[i, 1]
  initialDir = paste0(csv[i, 2], '/logdir')
  try(system(paste('mkdir -p', initialDir)))
  
  transferInputFiles = paste0(csv[i, 2], '/',
                              csv[i, 3], ',',
                              csv[i, 4])
  transferOutputFiles = paste0(csv[i, 2], '/EddyOutputs')
  
  cat(paste("JOB", job, submit, "\n"))
  cat(paste0("VARS ", job, " executable = \"", executable, "\"\n"))
  cat(paste0("VARS ", job, " initialDir = \"", initialDir, "\"\n"))
  cat(paste0("VARS ", job, " logFile = \"", job, ".log\"\n"))
  cat(paste0("VARS ", job, " errFile = \"", job, ".err\"\n"))
  cat(paste0("VARS ", job, " outFile = \"", job, ".out\"\n"))
  cat(paste0("VARS ", job, " args = \"", csv[i, 3], "\"\n"))
  cat(paste0("VARS ", job, " transferInputFiles = \"", transferInputFiles, "\"\n"))
  cat(paste0("VARS ", job, " transferOutputFiles = \"", transferOutputFiles, "\"\n\n"))
}
sink()