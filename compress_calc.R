## NOTE. Compression Level is set to `-f GZIP=5`
infodf <- file.info(
    list.files(
        path = "/mnt/STORE1/imagetcga/hovernet/h5ad",
        pattern = "h5ad$",
        full.names = TRUE
    )
)

infogz <- file.info(
    paste0(rownames(infodf), ".gz")
)

identical(
    nrow(infodf), nrow(infogz)
)

identical(
    rownames(infodf),
    gsub(".gz", "", rownames(infogz))
)

infodf <- infodf[!is.na(infogz[["size"]]), ]
infogz <- infogz[!is.na(infogz[["size"]]), ]

sizedf <- cbind.data.frame(infodf[["size"]], infogz[["size"]])
sizem <- data.matrix(sizedf)
m12 <- colMeans(sizem)

## mean reduction of 52 MB
mean(sizedf[[1]] - sizedf[[2]]) / 10^6

## mean reduction of 52 MB
(m12[1] - m12[2]) / 10^6

## total reduction of 540 GB
(sum(sizedf[[1L]]) - sum(sizedf[[2L]])) / 10^9

## files that seem to have missing data
## "/mnt/STORE1/imagetcga/hovernet/h5ad/TCGA-06-1086-01Z-00-DX2.e1961f1f-a823-4775-acf7-04a46f05e15e.h5ad"
## "/mnt/STORE1/imagetcga/hovernet/h5ad/TCGA-44-7661-01Z-00-DX1.baf72abd-edb9-4f56-beb3-f5138aa50930.h5ad"
