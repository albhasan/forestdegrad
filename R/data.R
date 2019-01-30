#' @title Sample time-series of degradation in the Amazon forest. 
#'
#' @description A dataset containing a tibble with time series sampled of the
#' brazilian Amazon. The samples were taken using the photo collection of the 
#' FOTOTECA at INPE. The original samples were filtered using the Kohonen 
#' clustering from the SITS package at 80% similarity among samples. The 
#' original samples were collected by Rodrigo Anzolin Begotti.
#'
#' @docType data
#' @keywords datasets
#' @name degrad_samples
#' @usage data(degrad_samples)
#'
#' @format A tibble with 1 rows and 7 variables: (a) longitude: East-west coordinate of the time series sample (WGS 84);
#'   latitude (North-south coordinate of the time series sample in WGS 84), start_date (initial date of the time series),
#'   end_date (final date of the time series), label (the class label associated to the sample),
#'   coverage (the name of the coverage associated with the data),
#'   time_series (list containing a tibble with the values of the time series).
NULL
