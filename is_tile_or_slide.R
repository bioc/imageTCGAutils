## script to identify file type from contents

slide_files <- list.files(
    path = "/mnt/STORE1/imagetcga/provgigapath/slide_level/",
    pattern = "\\.csv\\.gz",
    full.names = TRUE
)
is_slide_file <- vapply(
    slide_files,
    function(slide) {
        tryCatch({
            line <- readLines(slide, n = 1L)
            if (!length(line)) {
                warning("slide_file is empty: ", slide)
                NA
            } else {
                grepl("last_layer_embed", x = line, fixed = TRUE)
            }
        }, error = function(e) {
                FALSE
            }
        )
    },
    logical(1L)
)

## empty slide files
## /mnt/STORE1/imagetcga/provgigapath/slide_level//TCGA-25-2392-01Z-00-DX1.C37932E5-973F-444D-8CEB-1BED4279165E.csv.gz
## /mnt/STORE1/imagetcga/provgigapath/slide_level//TCGA-25-2396-01Z-00-DX1.3E755B49-EFC5-49B8-A381-0B06DAE56961.csv.gz
## /mnt/STORE1/imagetcga/provgigapath/slide_level//TCGA-42-2582-01Z-00-DX1.891d6182-c96b-4709-abeb-314d6874856a.csv.gz
## /mnt/STORE1/imagetcga/provgigapath/slide_level//TCGA-42-2593-01Z-00-DX1.9d506f1d-a5b3-4643-bd12-91c33fae4286.csv.gz
## /mnt/STORE1/imagetcga/provgigapath/slide_level//TCGA-57-1992-01Z-00-DX1.1022B1ED-3DC1-4F71-8635-0F8B28138B8C.csv.gz
## /mnt/STORE1/imagetcga/provgigapath/slide_level//TCGA-B8-4154-01Z-00-DX1.b74b690e-366d-4eff-b216-c01a75596902.csv.gz
## /mnt/STORE1/imagetcga/provgigapath/slide_level//TCGA-CZ-4862-01Z-00-DX1.67cc16d6-6589-4f7b-bc7e-642eae3d2779.csv.gz
## /mnt/STORE1/imagetcga/provgigapath/slide_level//TCGA-E8-A438-01Z-00-DX1.2A198CD7-4FC2-43DD-94DA-CF79EC06A2C5.csv.gz
## /mnt/STORE1/imagetcga/provgigapath/slide_level//TCGA-EM-A22K-01Z-00-DX1.7E55DD32-B9F2-40ED-B231-4839A68647CD.csv.gz
## /mnt/STORE1/imagetcga/provgigapath/slide_level//TCGA-EM-A2P1-01Z-00-DX1.FDE3FF4D-8EA8-411A-AF7D-165CFCFBFAD4.csv.gz
## /mnt/STORE1/imagetcga/provgigapath/slide_level//TCGA-EM-A3O7-01Z-00-DX1.D330057C-AC41-4701-88DC-6D5835B7F8EB.csv.gz
## /mnt/STORE1/imagetcga/provgigapath/slide_level//TCGA-EM-A3O8-01Z-00-DX1.B164A20B-7433-420A-B947-C78CEB49B7D2.csv.gz
## /mnt/STORE1/imagetcga/provgigapath/slide_level//TCGA-EM-A3OB-01Z-00-DX1.CCD73BD9-C5C0-4429-9F74-701DC8B54860.csv.gz
## /mnt/STORE1/imagetcga/provgigapath/slide_level//TCGA-EM-A3SU-01Z-00-DX2.C1AE2E5A-B09C-431E-95ED-20E5777F3C4B.csv.gz
## /mnt/STORE1/imagetcga/provgigapath/slide_level//TCGA-FY-A2QD-01Z-00-DX1.6E1E148E-4A94-4F4D-AFA4-3AE22473A960.csv.gz
## /mnt/STORE1/imagetcga/provgigapath/slide_level//TCGA-GK-A6C7-01Z-00-DX1.291DEE77-CD13-4D8E-BA35-6EC15F45D264.csv.gz

tile_files <- list.files(
    path = "/mnt/STORE1/imagetcga/provgigapath/tile_level/",
    pattern = "\\.csv\\.gz",
    full.names = TRUE
)
is_tile_file <- vapply(
    tile_files,
    function(tile) {
        readLines(tile_files[1L], n = 1L) |>
            grepl("tile_id", x = _, fixed = TRUE)
    },
    logical(1L)
)

uk_files <- list.files(
    path = "/mnt/STORE1/imagetcga/provgigapath/",
    pattern = "\\.csv\\.gz",
    recursive = FALSE,
    full.names = TRUE
)

is_slide_uk <- vapply(
    uk_files,
    function(slide) {
        tryCatch({
            line <- readLines(slide, n = 1L)
            if (!length(line)) {
                warning("slide_file is empty: ", slide)
                NA
            } else {
                grepl("last_layer_embed", x = line, fixed = TRUE)
            }
        }, error = function(e) {
                FALSE
            }
        )
    },
    logical(1L)
)

is_tile_uk <- vapply(
    uk_files,
    function(tile) {
        readLines(tile_files[1L], n = 1L) |>
            grepl("tile_id", x = _, fixed = TRUE)
    },
    logical(1L)
)
