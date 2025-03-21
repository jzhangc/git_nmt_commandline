error_flag <- NA
a <- 0
res <- NA

cat(paste0("this is the 1st message from R\n"))
tryCatch(
  {
    if (a == 0) {
      err <- simpleError("custome error: invalid value")
      class(err) <- c("custom_error", class(err))
      stop(err)
    }
    res <<- 1 / a
  }, custom_error = function(e){
    err <- conditionMessage(e)
    cat(paste0("error message: ", err, "\n"))
  }, error = function(e) {
    cat(paste0("error message: ", e, "\n"))
    error_flag <<- "fatal_error"
  }
)


if (!is.na(error_flag)) {
  cat(error_flag)
  quit()
} else {
  res
}
