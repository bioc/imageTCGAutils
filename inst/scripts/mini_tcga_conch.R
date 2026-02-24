## setwd("~/gh/imageTCGAutils/")

## read H5 dataset from CONCH
library(rhdf5)
h5file <- paste0(
    "~/data/CONCH/",
    "TCGA-XK-AAK1-01Z-00-DX1.5354527B-905C-4F39-B469-3A64D0BC56A2.h5"
)
h5new <- "inst/extdata/mini_tcga_conch.h5"
if (!dir.exists("inst/extdata"))
    dir.create("inst/extdata", recursive = TRUE)
file.create(h5new)
## file.remove(h5new)

h5ls(h5file, recursive = TRUE)

indx <- list(1:2, 1:10)

h1 <- h5read(h5file, "/coords", index = indx)
h5write(h1, h5new, "/coords")

h2 <- h5read(h5file, "/features", index = indx)
h5write(h2, h5new, "/features")

imageTCGAutils::CONCH("inst/extdata/mini_tcga_conch.h5")
