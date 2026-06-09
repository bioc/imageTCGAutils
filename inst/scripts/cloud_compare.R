library(imageTCGAutils)

cloud <- listHoverNet(format = "json", maxkeys = 11000L)
cloud <- cloud[!duplicated(cloud), ]

jsondir <- "/mnt/STORE1/imagetcga/hovernet/json"
local <- list.files(
    jsondir, "\\.json\\.gz$", full.names = TRUE
) |>
    file.info()

lnames <- rownames(local) |> basename()
cnames <- cloud[["Key"]] |> basename()

setdiff(cnames, lnames)
setdiff(lnames, cnames)

## remove uncompressed json file from repository
## dupfile <- cloud[endsWith(cnames, setdiff(cnames, lnames)), "Key"]
## glue::glue("rclone delete cf_u24_rw:waldronlab-image-features/{dupfile}") |>
##     system()

# missing local JSON files ------------------------------------------------

in_files <- file.path(
    jsondir,
    gsub("\\.gz$", "", lnames)
) |>
    file.exists()

lnames[!in_files] |>
    head()
