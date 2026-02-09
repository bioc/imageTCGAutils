# if (!identical(Sys.getenv("NOT_CRAN"), "true")) {
#   exit_file("Skip online tests on CRAN")
# }

# Test listHoverNet
result <- listHoverNet()
expect_inherits(result, "data.frame")
expect_true(all(c("Filename", "Modified", "Size") %in% names(result)))
expect_true(nrow(result) > 0)
expect_false(any(grepl("^\\.\\.", result[["Filename"]])))

# Test different format - it takes too much time
# for (fmt in c("geojson", "h5ad", "json", "thumb")) {
#   result <- listHoverNet(format = fmt)
#   expect_inherits(result, "data.frame", info = fmt)
# }

# Test listProvGiga
result <- listProvGiga()
expect_inherits(result, "data.frame")
expect_true(all(c("Filename", "Modified", "Size") %in% names(result)))
