library(duckdb)
library(BiocParallel)

geodir <- "/mnt/STORE1/imagetcga/hovernet/geojson/"

convert_to_parquet <- function(dfile, overwrite = FALSE) {
    pdir <- "/mnt/STORE1/imagetcga/hovernet/parquet/"
    pfile <- file.path(
        pdir,
        gsub("\\.geojson$", ".parquet", basename(dfile))
    )

    if (!overwrite && file.exists(pfile)) {
        message("Skipping (already exists): ", basename(pfile))
        return(pfile)
    }

    # Each worker gets its own connection — duckdb connections are not fork-safe
    con <- duckdb::dbConnect(duckdb::duckdb())
    on.exit(duckdb::dbDisconnect(con, shutdown = TRUE))

    DBI::dbExecute(
        con,
        glue::glue(
            "COPY (SELECT * FROM read_json_auto('{dfile}')) TO '{pfile}' (FORMAT parquet);"
        )
    )

    message("Converted: ", basename(pfile))
    pfile
}


dfiles <- list.files(geodir, "\\.geojson$", full.names = TRUE)
subdfiles <- dfiles[1:10]
bp <- MulticoreParam(workers = 10L)

pfiles <-
    bplapply(subdfiles, convert_to_parquet, overwrite = FALSE, BPPARAM = bp)

