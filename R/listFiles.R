.BASE_URL <- "https://nyu1.osn.mghpcc.org"
.OSN_BUCKET_NAME <- "waldronlab-image-features"

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
#'   specifying the desired HoverNet data format. Default is "geojson".
#'
#' @param level `character(1L)` One of "slide_level" or "tile_level" specifying
#'   the desired ProvGiga data level. Default is "slide_level".
#'
#' @param maxkeys `integer(1L)` Maximum number of files to return. Default is
#'   1000.
#'
#' @returns `listHoverNet`,`listProvGiga`: A `tibble` listing available HoverNet
#'   or ProvGigaPath files with `Filename`, `Modified`, and `Size` columns.
#'
#' @examplesIf interactive()
#' ## List available HoverNet data for TCGA-OV
#' listHoverNet(format = "geojson", maxkeys = 10)
#' @export
listHoverNet <- function(
    format = c("geojson", "h5ad", "json", "parquet", "thumb"),
    maxkeys = 1000L
) {
    checkInstalled("paws")

    format <- match.arg(format)

    .query_s3_prefix(
        prefix = paste0("hovernet/", format, "/"),
        maxkeys = maxkeys
    )
}

#' @rdname listFiles
#'
#' @importFrom BiocBaseUtils isScalarCharacter
#'
#' @examplesIf interactive()
#' ## List available ProvGiga slide-level data for TCGA-BRCA
#' listProvGiga(level = "slide_level", maxkeys = 10)
#' @export
listProvGiga <- function(
    level = c("slide_level", "tile_level"), maxkeys = 1000L
) {
    checkInstalled("paws")

    level <- match.arg(level)

    .query_s3_prefix(
        prefix = paste0("provgigapath/", level, "/"),
        maxkeys = maxkeys
    )
}

#' @importFrom utils head
.query_s3_prefix <- function(prefix, maxkeys) {
    s3 <- paws::s3(
        config = list(
            credentials = list(
                anonymous = TRUE
            ),
            endpoint = .BASE_URL,
            region = "us-east-1"
        )
    )

    res <- s3$list_objects_v2(
        Bucket = .OSN_BUCKET_NAME,
        MaxKeys = maxkeys,
        Prefix = prefix
    )

    cols <- c("Key", "LastModified", "ETag", "Size")
    dres <- res$Contents |>
        lapply(`[`, cols) |>
        dplyr::bind_rows()
    nobjects <- length(dres[["Key"]])
    if (!nobjects)
        stop(
            "No objects found for specified format. Contact maintainer."
        )

    while (!is.null(res$NextContinuationToken) && nobjects < maxkeys) {
        res <- s3$list_objects_v2(
            Bucket = .OSN_BUCKET_NAME,
            MaxKeys = 1000,
            Prefix = prefix,
            ContinuationToken = res$NextContinuationToken
        )
        newres <- res$Contents |>
            lapply(`[`, cols) |>
            dplyr::bind_rows()
        dres <- dplyr::bind_rows(dres, newres)
        nobjects <- length(dres[["Key"]])
    }
    dres[["ETag"]] <- gsub("\"", "", dres[["ETag"]], fixed = TRUE)
    head(dres, maxkeys)
}
