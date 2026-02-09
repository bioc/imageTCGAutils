.BASE_URL <- "https://store.cancerdatasci.org"
.PROV_BASE_URL <- paste0(.BASE_URL, "/provgigapath")

#' @name listFiles
#'
#' @title List available HoVerNet and Prov-Giga-Path data for TCGA cancers
#'
#' @description Functions to list available HoverNet and ProvGiga data for TCGA
#'   cancers. HoverNet data is only available for TCGA-OV, while ProvGiga data
#'   is available for multiple TCGA cancer types at slide and tile levels. See
#'   the `TCGAcodesAvailable` dataset for a summary of available data. These
#'   functions return a `data.frame` with filenames and file sizes.
#'
#' @param format `character(1L)` One of "geojson", "h5ad", "json", or "thumb"
#'   specifying the desired HoverNet data format. Default is "h5ad".
#'
#' @param level `character(1L)` One of "slide_level" or "tile_level" specifying
#'   the desired ProvGiga data level. Default is "slide_level".
#'
#' @returns `listHoverNet`,`listProvGiga`: A `tibble` listing available HoverNet
#'   or ProvGigaPath files with `Filename`, `Modified`, and `Size` columns.
#'
#' @examplesIf interactive()
#' ## List available HoverNet data for TCGA-OV
#' listHoverNet(format = "h5ad")
#' @export
listHoverNet <- function(
    format = c("geojson", "h5ad", "json", "thumb")
) {
    format <- match.arg(format)
    hovernet_url <-
        paste(.BASE_URL, "hovernet", format, "", sep = "/")
    table <- .see_more_table(hovernet_url)
    table[!grepl("^\\.\\.", table[["Filename"]]), ]
}

#' @rdname listFiles
#'
#' @importFrom BiocBaseUtils isScalarCharacter
#'
#' @examplesIf interactive()
#' ## List available ProvGiga slide-level data for TCGA-BRCA
#' listProvGiga(level = "slide_level")
#' @export
listProvGiga <- function(
    level = c("slide_level", "tile_level")
) {
    level <- match.arg(level)

    tumor_type_url <- paste(
        .PROV_BASE_URL, level, "", sep = "/"
    )
    table <- .see_more_table(tumor_type_url)
    table[!grepl("^\\.\\.", table[["Filename"]]), ]
}
