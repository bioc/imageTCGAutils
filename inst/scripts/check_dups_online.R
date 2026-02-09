library(ImageFeatureTCGA)
data("TCGAcodesAvailable", package = "ImageFeatureTCGA")

# checking slide_level duplicates -----------------------------------------

slide_codes <- TCGAcodesAvailable[
    TCGAcodesAvailable[["slide_level_available"]], "diseaseCodes"
]

all_slides <- lapply(
    slide_codes,
    function(code) {
        listProvGiga(diseaseCode = code, level = "slide_level")
    }
) |> dplyr::bind_rows()

anyDuplicated(all_slides[["Filename"]])

all_codes <- dplyr::pull(TCGAcodesAvailable, "diseaseCodes")
all_code_slides <- lapply(
    all_codes,
    function(code) {
        tryCatch(
            {
                message("Processing ", code)
                listProvGiga(diseaseCode = code, level = "slide_level")
            },
            error = function(e) {
                tibble::tribble(
                    ~Filename, ~Modified, ~Size
                )
            }
        )
    }
) |> dplyr::bind_rows()


# checking tile_level duplicates ------------------------------------------
tile_codes <- TCGAcodesAvailable[
    TCGAcodesAvailable[["tile_level_available"]], "diseaseCodes"
]

all_tiles <- lapply(
    tile_codes,
    function(code) {
        tryCatch(
            {
                message("Processing ", code)
                listProvGiga(diseaseCode = code, level = "tile_level") |>
                    dplyr::mutate(Project = code)
            },
            error = function(e) {
                tibble::tribble(
                    ~Filename, ~Modified, ~Size, ~Project
                )
            }
        )
    }
) |> dplyr::bind_rows()

anyDuplicated(all_tiles[["Filename"]])
dups <- all_tiles[duplicated(all_tiles[["Filename"]]), "Filename", drop = TRUE]
fndups <- gsub("\\.csv\\.gz$", "", dups)
svsdups <- paste0(fndups, ".svs")

all_tiles[all_tiles[["Filename"]] %in% dups, ] |>
    dplyr::group_by(Project) |>
    dplyr::summarise(n = dplyr::n())

db <- imageTCGA:::db

dupframe <- db[db[["Project.ID"]] %in% c("TCGA-READ", "TCGA-CHOL"), ]
dupframe[, "File.Name"] |>
    anyDuplicated()

dupframe[dupframe[, "File.Name"] %in% svsdups, ]
