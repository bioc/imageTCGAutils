library(dplyr)
library(tibble)
setwd("/mnt/STORE1/imagetcga/")

fullhovnames <- list.files("hovernet", recursive = TRUE, full.names = TRUE)

hovdf <- fullhovnames |>
    strsplit("/", fixed = TRUE) |>
    do.call(rbind.data.frame, args = _) |>
    bind_cols(fullpath = fullhovnames) |>
    as_tibble() |>
    rename(pipeline = 1, format = 2, filename = 3)

hovdf <- dplyr::bind_cols(
    hovdf,
    tcga_barcode = vapply(
        strsplit(hovdf[["filename"]], ".", fixed = TRUE),
        head,
        character(1L),
        1L
    )
)

fullgpnames <- list.files("provgigapath", recursive = TRUE, full.names = TRUE)
gpdf <- fullgpnames |>
    strsplit("/", fixed = TRUE) |>
    do.call(rbind.data.frame, args = _) |>
    bind_cols(fullpath = fullgpnames) |>
    as_tibble() |>
    rename(pipeline = 1, level = 2, filename = 3) |>
    mutate(
        format = gsub("\\.gz$", "", filename) |>
            tools::file_ext()
    )

gpdf <- dplyr::bind_cols(
    gpdf,
    tcga_barcode = vapply(
        strsplit(gpdf[["filename"]], ".", fixed = TRUE),
        head,
        character(1L),
        1L
    )
)
gpdf

alldata <- dplyr::full_join(hovdf, gpdf)
alldata[["fnsansext"]] <- vapply(
    strsplit(alldata[["filename"]], "\\."),
    function(x) paste(x[1:2], collapse = "."),
    character(1L)
)

db <- imageTCGA:::db |>
    as_tibble() |>
    mutate(
        fnsansext = tools::file_path_sans_ext(File.Name)
    )

result <- dplyr::full_join(alldata, db, by = "fnsansext")

## version 1
## saveRDS(result, "~/test/data_catalog_v0.Rds")
## version 2
## saveRDS(result, "~/data/cancerdatasci_catalog.Rds")

## latest
## saveRDS(result, "~/data/cancerdatasci_catalog_full.Rds")

readRDS("~/data/cancerdatasci_catalog_full.Rds")

col_types <-
    sapply(result, class) |> substr(x=_, 1L, 1L) |> paste(collapse = "")
col_types <- gsub("n", "d", col_types)

## readr::write_tsv(result, file = "~/data/store_cancerdatasci_catalog.tsv")

readr::read_tsv(
    file = "~/data/store_cancerdatasci_catalog.tsv",
    col_types = col_types
)

file.copy(
    from = "~/data/store_cancerdatasci_catalog.tsv",
    to =  "/mnt/STORE1/imagetcga/"
)
