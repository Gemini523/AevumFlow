library(plumber)

#* @get /health
function() {
  list(status = "AevumFlow API running")
}
