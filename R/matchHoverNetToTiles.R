utils::globalVariables(c(".", "N", "x1", "xmax", "xmin", "y1", "ymax", "ymin"))

#' Compute scale factor between nuclei and tile coordinate systems
#' @noRd
.computeScaleFactor <- function(cell_meta, tiles, tile_x, tile_y) {
    sx <- diff(range(cell_meta$x, na.rm = TRUE)) /
        diff(range(tiles[[tile_x]], na.rm = TRUE))
    sy <- diff(range(cell_meta$y, na.rm = TRUE)) /
        diff(range(tiles[[tile_y]], na.rm = TRUE))
    list(scale_factor = mean(c(sx, sy), na.rm = TRUE), sx = sx, sy = sy)
}

#' Extract nuclei coordinates and cell type from a SpatialExperiment
#' @noRd
.extractNucleiMeta <- function(hovernet, cell_x, cell_y, cell_type) {
    coords    <- SpatialExperiment::spatialCoords(hovernet)
    cell_data <- SummarizedExperiment::colData(hovernet)
    data.frame(
        x    = coords[, cell_x],
        y    = coords[, cell_y],
        type = cell_data[[cell_type]]
    )
}

#' Assign nuclei to tiles via non-equi join and return per-tile cell type counts
#' @noRd
.assignNucleiToTiles <- function(cell_meta_scaled, tiles, tile_x, tile_y,
                                tile_id, tile_size) {
    dt_tiles       <- data.table::as.data.table(tiles)
    dt_tiles$xmin  <- dt_tiles[[tile_x]]
    dt_tiles$xmax  <- dt_tiles[[tile_x]] + tile_size
    dt_tiles$ymin  <- dt_tiles[[tile_y]]
    dt_tiles$ymax  <- dt_tiles[[tile_y]] + tile_size

    dt_nuc <- data.table::data.table(
        x1        = cell_meta_scaled$x,
        x2        = cell_meta_scaled$x,
        y1        = cell_meta_scaled$y,
        y2        = cell_meta_scaled$y,
        cell_type = cell_meta_scaled$type
    )

    assigned <- dt_tiles[
        dt_nuc,
        on      = .(xmin <= x1, xmax >= x1, ymin <= y1, ymax >= y1),
        nomatch = 0L
    ]

    tile_counts <- assigned[, .N, by = c(tile_id, "cell_type")]
    data.table::setnames(tile_counts, "cell_type", "cell_type_label")
    tile_counts
}

#' Derive dominant cell type per tile from count table
#' @noRd
.dominantCellType <- function(tile_counts, tile_id) {
    dominant <- tile_counts[
        tile_counts[, .I[which.max(N)], by = tile_id]$V1
    ]
    data.table::setnames(dominant, "cell_type_label", "dominant_cell_type")
    dominant
}

#' Validate inputs for matchHoverNetToTiles
#' @noRd
.validateMatchInputs <- function(hovernet, tiles, cell_x, cell_y,
                                tile_x, tile_y, tile_id, cell_type) {
    if (!methods::is(hovernet, "SpatialExperiment") &&
        !methods::is(hovernet, "SpatialFeatureExperiment"))
        stop("'hovernet' must be a SpatialExperiment or ",
            "SpatialFeatureExperiment object.")
    if (!is.data.frame(tiles))
        stop("'tiles' must be a data.frame or tibble.")
    coords    <- SpatialExperiment::spatialCoords(hovernet)
    cell_data <- SummarizedExperiment::colData(hovernet)
    if (!all(c(cell_x, cell_y) %in% colnames(coords)))
        stop("Spatial coordinates '", cell_x, "' and '", cell_y,
            "' not found in spatialCoords.")
    if (!cell_type %in% colnames(cell_data))
        stop("Cell type column '", cell_type, "' not found in colData.")
    if (!all(c(tile_x, tile_y, tile_id) %in% colnames(tiles)))
        stop("Required tile columns not found: ",
            paste(c(tile_x, tile_y, tile_id), collapse = ", "))
}


#' Match HoverNet Nuclei to ProvGigaPath Tiles
#'
#' @description Assigns HoverNet nuclei to ProvGigaPath tiles by computing a
#'   scale factor to align coordinate systems, then performing spatial matching.
#'   Returns tile-level cell type counts and dominant cell types.
#'
#' @param hovernet A `SpatialExperiment` or `SpatialFeatureExperiment` object
#'   containing HoverNet nuclei data with spatial coordinates and cell type
#'   information.
#' @param tiles A `data.frame` or `tibble` containing ProvGigaPath tile data
#'   with tile coordinates and embeddings.
#' @param tile_size Numeric. Size of tiles in pixels. Default is `224`.
#' @param cell_x Character. Name of the x-coordinate column in HoverNet data.
#'   Default is `"x_centroid"` for h5ad data.
#' @param cell_y Character. Name of the y-coordinate column in HoverNet data.
#'   Default is `"y_centroid"` for h5ad data.
#' @param tile_x Character. Name of the tile x-coordinate column in tiles data.
#'   Default is `"tile_x"`.
#' @param tile_y Character. Name of the tile y-coordinate column in tiles data.
#'   Default is `"tile_y"`.
#' @param tile_id Character. Name of the tile ID column in tiles data.
#'   Default is `"tile_id"`.
#' @param cell_type Character. Name of the cell type column in HoverNet data.
#'   Default is `"type"`.
#'
#' @return A list with three elements:
#'   \describe{
#'     \item{tiles_with_nuclei}{A `data.frame` with original tile data plus
#'       cell type counts (`N`) and labels (`cell_type_label`) for each tile.}
#'     \item{tiles_dominant}{A `data.frame` with tile IDs and their dominant
#'       (most frequent) cell type.}
#'     \item{scale_factor}{A list containing the computed scale factor, and
#'       separate x and y scale factors.}
#'   }
#'
#' @details The function performs the following steps:
#'   1. Computes a scale factor to align nuclei coordinates with
#'   tile coordinates
#'   2. Scales nuclei coordinates using the computed scale factor
#'   3. Creates bounding boxes for each tile based on tile_size
#'   4. Assigns nuclei to tiles using spatial overlap
#'   5. Counts cell types per tile
#'   6. Identifies the dominant cell type for each tile
#'   7. Merges results back to the original tiles data
#'
#'   The scale factor is computed as the mean of x and y scale factors, where
#'   each is the ratio of coordinate ranges between nuclei and tiles.
#'
#' @importFrom SpatialExperiment spatialCoords
#' @importFrom SummarizedExperiment colData
#' @importFrom data.table data.table as.data.table setnames .N := .I
#' @importFrom dplyr mutate
#' @importFrom methods is
#' @importFrom rlang .data
#'
#' @examplesIf interactive()
#' library(imageFeatureTCGA)
#' hov_file <- paste0(
#'     "https://store.cancerdatasci.org/hovernet/h5ad/",
#'     "TCGA-23-1021-01Z-00-DX1.F07C221B-D401-47A5-9519-10DE59CA1E9D.h5ad.gz"
#' )
#' hn_spe <- HoverNet(hov_file, outClass = "SpatialExperiment") |> import()
#'
#' tile_prov_url <- paste0(
#'     "https://store.cancerdatasci.org/provgigapath/tile_level/",
#'     "TCGA-23-1021-01Z-00-DX1.F07C221B-D401-47A5-9519-10DE59CA1E9D.csv.gz"
#' )
#' pg_spe <- ProvGiga(tile_prov_url) |> import()
#'
#' result         <- matchHoverNetToTiles(hn_spe, pg_spe)
#' tiles_matched  <- result$tiles_with_nuclei
#' dominant_types <- result$tiles_dominant
#' scale_info     <- result$scale_factor
#' @export
matchHoverNetToTiles <- function(
        hovernet,
        tiles,
        tile_size = 224,
        cell_x    = "x_centroid",
        cell_y    = "y_centroid",
        tile_x    = "tile_x",
        tile_y    = "tile_y",
        tile_id   = "tile_id",
        cell_type = "type"
) {
    .validateMatchInputs(hovernet, tiles, cell_x, cell_y,
                        tile_x, tile_y, tile_id, cell_type)

    cell_meta    <- .extractNucleiMeta(hovernet, cell_x, cell_y, cell_type)
    sf_list      <- .computeScaleFactor(cell_meta, tiles, tile_x, tile_y)

    cell_meta_scaled <- dplyr::mutate(
        cell_meta,
        x = .data$x / sf_list$scale_factor,
        y = .data$y / sf_list$scale_factor
    )

    tile_counts  <- .assignNucleiToTiles(
        cell_meta_scaled, tiles, tile_x, tile_y, tile_id, tile_size
    )
    tile_dominant <- .dominantCellType(tile_counts, tile_id)

    tiles_with_nuclei <- merge(
        as.data.frame(tiles), as.data.frame(tile_counts),
        by = tile_id, all.x = TRUE
    )
    tiles_with_nuclei <- merge(
        tiles_with_nuclei,
        as.data.frame(tile_dominant)[, c(tile_id, "dominant_cell_type")],
        by = tile_id, all.x = TRUE
    )

    list(
        tiles_with_nuclei = tiles_with_nuclei,
        tiles_dominant    = as.data.frame(tile_dominant),
        scale_factor      = sf_list
    )
}
