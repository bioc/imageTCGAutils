## before mv
## saveRDS(fullgpnames, "~/data/prov_prev_fnames.Rds")
tnames <- readRDS("~/data/prov_prev_fnames.Rds") |>
    grepv("tile_level", x = _) |>
    basename()

## after mv
acttnames <- list.files(
    path = "/mnt/STORE1/imagetcga/provgigapath/tile_level/",
    pattern = "\\.csv\\.gz$",
    recursive = TRUE
)

c(length(tnames), length(acttnames))

anyDuplicated(tnames)

tnames[duplicated(tnames)]
