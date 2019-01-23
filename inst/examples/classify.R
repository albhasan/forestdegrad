# classify a SITS brick using the degradation samples provided by 
# Rodrigo Anzolin Begotti <rodrigo_anz@yahoo.com.br> on 2019-01-23

library(sits)
library(tidyverse)
library(devtools)
library(sits.prodes)

setwd("/home/alber/Documents/data/experiments/amazon_degradation/Rpackage/forestdegrad")
devtools::load_all()

# script setup ----
tiles <- "h11v09"
bands <- c("ndvi", "evi", "nir", "mir", "red", "blue")
years <- 2000:2018
cores <- floor(parallel::detectCores() * 3/4)
mem <- 64

brick_type <- "mod13"

base_path <- "/home/alber/Documents/data/experiments/amazon_degradation"
result_path <- file.path(base_path, "results")
stopifnot(all(vapply(c(base_path, result_path), dir.exists, logical(1))))

path_to_bricks <- c(
   mod13 = file.path(base_path, "data", "raster", "bricks_modis")
)

# gather brick metadata
brick_path <- path_to_bricks[brick_type]
if (brick_type == "mod13") {
  data("timeline_2000_2017", package = "sits")
  cov_timeline <- timeline_2000_2017
  rm(timeline_2000_2017)
  years <- 2000
}
brick_tb <- brick_path %>% list.files(full.names = TRUE, pattern = '*tif') %>%
    ensurer::ensure_that(length(.) > 0, err_desc = "Bricks not found!") %>%
    sits.prodes:::get_brick_md() %>% dplyr::as_tibble() %>%
    dplyr::filter(pathrow %in% tiles, year %in% years, band %in% bands) %>%
    ensurer::ensure_that(identical(sort(.$band), sort(bands)), 
                         err_desc = "Some bands are unavailable")

# train
samples_tb <- readRDS(system.file("extdata", "samples.rds", package = "forestdegrad"))
svm_model <- sits_train(samples_tb, sits_svm())


res <- lapply(brick_tb$pathrow, function(pr, years, brick_tb, cores, mem, sits_model){
    lapply(years, function(yr, pr, brick_tb, cores, mem, sits_model){
        bricks <- brick_tb %>% dplyr::filter(pathrow == pr, year == yr)
        if (stringr::str_detect(brick_type, "^l8mod.+"))
            cov_timeline <- seq(from = as.Date(unique(bricks$start_date)[1]), by = 16, length.out = 23)
        coverage_name <- paste(brick_type, pr, yr, sep = '_')
        scoverage <- sits::sits_coverage(files = bricks$path, name = coverage_name,
                                     timeline = cov_timeline, bands = bricks$band)
        result_filepath <- file.path(result_path, paste0(coverage_name, ".tif"))
        sits::sits_classify_raster(file = result_filepath,
                               coverage = scoverage,
                               ml_model = sits_model,
                               memsize = mem,
                               multicores = cores)
    }, pr = pr, brick_tb = brick_tb, cores = cores, mem = mem, sits_model = sits_model)
}, years = years, brick_tb = brick_tb, cores = cores, mem = mem, sits_model = svm_model)

print(res)

