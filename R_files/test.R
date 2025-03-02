error_flag <- NA
tryCatch(1 / a, error = function(e) {
  # cat(paste0("error: ", e))
  assign("error_flag", "fs_failure\n", envir = .GlobalEnv)
  # error_flag <- "fs_failure\n"
})

# cat(error_flag)

if (!is.na(error_flag)) {
  cat(error_flag)
  quit()
}
