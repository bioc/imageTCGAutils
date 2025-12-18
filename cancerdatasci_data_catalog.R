library(dplyr)
library(tibble)
setwd("/mnt/STORE1/imagetcga/")

# load imageTCGA internal catalog
db <- imageTCGA:::db |>
    as_tibble() |>
    mutate(
        fnsansext = tools::file_path_sans_ext(File.Name)
    )

# hovernet catalog --------------------------------------------------------

fullhovnames <- list.files("hovernet", full.names = TRUE, recursive = TRUE)

hov_cat <- fullhovnames |>
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
    ) |>
    dplyr::left_join(db, by = "fnsansext")

hov_cat |>
    readr::write_tsv(file = "~/data/hovernet_catalog.tsv")

# finalize and copy -------------------------------------------------------

col_types <-
    sapply(hov_cat, class) |> substr(x = _, 1L, 1L) |> paste(collapse = "")
col_types <- gsub("n", "d", col_types)

readr::read_tsv("~/data/hovernet_catalog.tsv", col_types = col_types)

# provgigapath catalog ----------------------------------------------------

fullgpnames <- list.files("provgigapath", full.names = TRUE, recursive = TRUE)

prov_cat <- fullgpnames |>
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
    ) |>
    dplyr::left_join(db, by = "fnsansext")

prov_cat |>
    readr::write_tsv(file = "~/data/provgigapath_catalog.tsv")

# provgigapath catalog ----------------------------------------------------

prov_cat |>
    readr::write_tsv(file = "~/data/provgigapath_catalog.tsv")

col_types <-
    sapply(prov_cat, class) |> substr(x = _, 1L, 1L) |> paste(collapse = "")
col_types <- gsub("n", "d", col_types)

readr::read_tsv("~/data/provgigapath_catalog.tsv", col_types = col_types)


# join both catalogs ------------------------------------------------------

full_cat <- dplyr::full_join(hov_cat, prov_cat)

col_types <-
    sapply(full_cat, class) |> substr(x=_, 1L, 1L) |> paste(collapse = "")
col_types <- gsub("n", "d", col_types)

full_cat |>
    readr::write_tsv(
        file = "~/data/store_cancerdatasci_catalog.tsv"
    )

readr::read_tsv(
    file = "~/data/store_cancerdatasci_catalog.tsv",
    col_types = col_types
)

# previous joined catalog -------------------------------------------------

## version 1
## saveRDS(result, "~/test/data_catalog_v0.Rds")
## version 2
## saveRDS(result, "~/data/cancerdatasci_catalog.Rds")

## latest
## saveRDS(result, "~/data/cancerdatasci_catalog_full.Rds")

## readRDS("~/data/cancerdatasci_catalog_full.Rds")
