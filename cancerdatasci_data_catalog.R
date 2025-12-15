library(dplyr)
library(tibble)
setwd("/mnt/STORE1/imagetcga/")

# separate catalog by technology due to folder permissions ----------------

# hovernet catalog --------------------------------------------------------

fullhovnames <- list.files("hovernet", recursive = TRUE, full.names = TRUE)

hovdf <- fullhovnames |>
    strsplit("/", fixed = TRUE) |>
    do.call(rbind.data.frame, args = _) |>
    bind_cols(fullpath = fullhovnames) |>
    as_tibble() |>
    rename(pipeline = 1, format = 2, filename = 3) |>
    mutate(
        fnsansext =  vapply(
            strsplit(filename, "\\."),
            function(x) paste(x[1:2], collapse = "."),
            character(1L)
        ),
        tcga_barcode = vapply(
            strsplit(filename, ".", fixed = TRUE),
            head,
            character(1L),
            1L
        )
    )

db <- imageTCGA:::db |>
    as_tibble() |>
    mutate(
        fnsansext = tools::file_path_sans_ext(File.Name)
    )

hov_cat <- dplyr::left_join(hovdf, db, by = "fnsansext")

hov_cat |>
    readr::write_tsv(file = "~/data/hovernet_catalog.tsv")

col_types <-
    sapply(hov_cat, class) |> substr(x = _, 1L, 1L) |> paste(collapse = "")
col_types <- gsub("n", "d", col_types)

readr::read_tsv("~/data/hovernet_catalog.tsv", col_types = col_types)

file.copy(
    from = "~/data/hovernet_catalog.tsv",
    to =  "/mnt/STORE1/imagetcga/hovernet/",
    overwrite = TRUE
)

# provgigapath catalog ----------------------------------------------------

fullgpnames <- list.files("provgigapath", recursive = TRUE, full.names = TRUE)

gpdf <- fullgpnames |>
    strsplit("/", fixed = TRUE) |>
    do.call(rbind.data.frame, args = _) |>
    bind_cols(fullpath = fullgpnames) |>
    as_tibble() |>
    rename(pipeline = 1, level = 2, filename = 3) |>
    mutate(
        format = gsub("\\.gz$", "", filename) |>
            tools::file_ext(),
        fnsansext = vapply(
            strsplit(filename, "\\."),
            function(x) paste(x[1:2], collapse = "."),
            character(1L)
        ),
        tcga_barcode = vapply(
            strsplit(filename, ".", fixed = TRUE),
            head,
            character(1L),
            1L
        )
    )

prov_cat <- dplyr::left_join(gpdf, db, by = "fnsansext")

prov_cat |>
    readr::write_tsv(file = "~/data/provgigapath_catalog.tsv")

col_types <-
    sapply(prov_cat, class) |> substr(x = _, 1L, 1L) |> paste(collapse = "")
col_types <- gsub("n", "d", col_types)

readr::read_tsv("~/data/provgigapath_catalog.tsv", col_types = col_types)

file.copy(
    from = "~/data/provgigapath_catalog.tsv",
    to =  "/mnt/STORE1/imagetcga/provgigapath/",
    overwrite = TRUE
)

# previous joined catalog -------------------------------------------------

## version 1
## saveRDS(result, "~/test/data_catalog_v0.Rds")
## version 2
## saveRDS(result, "~/data/cancerdatasci_catalog.Rds")

## latest
## saveRDS(result, "~/data/cancerdatasci_catalog_full.Rds")

## readRDS("~/data/cancerdatasci_catalog_full.Rds")

## col_types <-
##     sapply(result, class) |> substr(x=_, 1L, 1L) |> paste(collapse = "")
## col_types <- gsub("n", "d", col_types)

## readr::write_tsv(result, file = "~/data/store_cancerdatasci_catalog.tsv")

## readr::read_tsv(
##     file = "~/data/store_cancerdatasci_catalog.tsv",
##     col_types = col_types
## )

