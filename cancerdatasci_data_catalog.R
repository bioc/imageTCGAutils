library(dplyr)
setwd("/mnt/STORE1/imagetcga/")

fullhovnames <- list.files("hovernet", recursive = TRUE, full.names = TRUE)

hovdf <- fullhovnames |>
    strsplit("/", fixed = TRUE) |>
    do.call(rbind.data.frame, args = _) |>
    dplyr::bind_cols(fullpath = fullhovnames) |>
    tibble::as_tibble()
names(hovdf)[1:3] <- c("pipeline", "format", "filename")

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
    dplyr::bind_cols(fullpath = fullgpnames) |>
    tibble::as_tibble()

names(gpdf)[1:3] <- c("pipeline", "level", "filename")

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

## saveRDS(result, "~/test/data_catalog_v0.Rds")
saveRDS(result, "~/data/cancerdatasci_catalog.Rds")

## readRDS("~/data/cancerdatasci_catalog.Rds")
