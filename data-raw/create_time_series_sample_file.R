# create binary files of the best timeseries samples.

library(tidyverse)
library(kohonen)
library(sits)
library(ensurer)

setwd("/home/alber/Documents/data/experiments/amazon_degradation/Rpackage/forestdegrad")
devtools::load_all()

# setup ----
base_path <- "/home/alber/Documents/data/experiments/amazon_degradation"

# where to store partial results
file_samples_koh          <- file.path(base_path, "tmp", "file_samples_koh.Rdata")
file_koh_evaluate_samples <- file.path(base_path, "tmp", "file_koh_evaluate_samples.Rdata")
file_koh_plot             <- file.path(base_path, "tmp", "file_koh_plot.png")
set.seed(666)
# - - - -

# load samples
samples_tb <- readRDS(system.file("extdata", "samples.rds", package = "forestdegrad"))

#Create cluster with Self-organizing maps (kohonen)
xd <- 25
yd <- 25
rl = 100
stopifnot(xd * yd < nrow(samples_tb))
time_series.ts <- samples_tb %>% sits::sits_values(format = "bands_cases_dates")
samples_koh <- sits::sits_kohonen(data.tb = samples_tb,
                                  time_series = time_series.ts,
                                  grid_xdim = xd,
                                  grid_ydim = yd,
                                  rlen = rl,
                                  dist.fcts = "euclidean",
                                  alpha = 1,
                                  neighbourhood.fct = "gaussian")
koh_evaluate_samples <- sits::sits_evaluate_samples(data.tb = samples_tb,
                                                    time_series = time_series.ts,
                                                    grid_xdim = xd,
                                                    grid_ydim = yd,
                                                    rlen = rl,
                                                    distance = "euclidean",
                                                    mode = "pbatch",
                                                    iteration = 100)

# save partial results
save(samples_koh, file = file_samples_koh)
save(koh_evaluate_samples, file = file_koh_evaluate_samples)

# check the distribution of the smaples
sits::sits_plot_kohonen(samples_koh)
ggplot2::ggsave(filename = file_koh_plot)

# remove confused samples
degrad_samples <- dplyr::left_join(samples_koh$info_samples, koh_evaluate_samples$metrics_by_samples, by = "id_sample") %>%
    dplyr::filter(label == neuron_label.x, percentage > 80) %>%
    dplyr::select(longitude:time_series)

# print
message(sprintf("Original number of samples %s", nrow(samples_tb)))
message(sprintf("Konohen  number of samples %s", nrow(degrad_samples)))
message(sprintf("Rate Konohen / Original %s", round(nrow(degrad_samples)/nrow(samples_tb), digits = 2)))

message("Number of original samples")
stat_tb <- samples_tb %>% dplyr::group_by(label) %>% dplyr::summarise(n_original = n())
degrad_samples %>% dplyr::group_by(label) %>% 
    dplyr::summarise(n_kohonen = n()) %>% 
    dplyr::full_join(stat_tb, by = "label") %>%
    dplyr::mutate(ratio = n_kohonen / n_original) %>%
    print()

# further validation of samples through k-folds (see confusion matrix)
print("Kohonen validation using k-folds and SVM")
degrad_samples %>% sits::sits_kfold_validate(ml_method = sits::sits_svm()) %>%
    sits::sits_conf_matrix() %>% print()

# save the samples to the package
devtools::use_data(degrad_samples, overwrite = TRUE)

print("Finished!")

