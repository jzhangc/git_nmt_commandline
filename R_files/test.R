cat(paste0("this is the 1st message from R\n"))
error_flag <- NA

tryCatch(1/a, error = function(e) {
  cat(paste0("error message: ", e, "\n"))
  assign("error_flag", "fatal_error", envir = .GlobalEnv)
  })

if (!is.na(error_flag)) {
  cat(error_flag)
  quit()
}
