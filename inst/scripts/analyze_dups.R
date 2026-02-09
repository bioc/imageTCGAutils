dups <- readLines("duplicated_fnames.txt")
dupfiles <- vapply(
    strsplit(dups, "\\."),
    function(x) paste(x[1:2], collapse = "."),
    character(1)
)

## pre mv catalog
result <- readRDS("~/test/data_catalog_v0.Rds")
dup_result <- result[result$fnsansext %in% dupfiles, ]

table(dup_result$Project.ID)
#' TCGA-READ
#'       937

## post mv catalog
catalog <- readRDS("~/data/cancerdatasci_catalog.Rds")
dup_catalog <- catalog[catalog$fnsansext %in% dupfiles, ]

table(dup_catalog$Project.ID)
#' TCGA-READ
#'       772

## difference of 165 files
