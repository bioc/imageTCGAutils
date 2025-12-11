dups <- readLines("duplicated_fnames.txt")
dupfiles <- vapply(
    strsplit(dups, "\\."),
    function(x) paste(x[1:2], collapse = "."),
    character(1)
)

catalog <- readRDS("~/data/cancerdatasci_catalog.Rds")

dup_catalog <- catalog[catalog$fnsansext %in% dupfiles, ]

table(dup_catalog$Project.ID)
#' TCGA-READ
#'       772
