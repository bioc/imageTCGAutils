
# imageTCGAutils

# Introduction

`imageTCGAutils` provides utility functions for integrating and analyzing
multi-modal whole-slide image (WSI) data from 
[The Cancer Genome Atlas (TCGA)](https://cancer.gov/ccg/research/genome-sequencing/tcga).
It is designed to work alongside `imageFeatureTCGA`, which handles data
import of precomputed features derived from histopathology
foundation models, including HoVerNet
and Prov-GigaPath.


In this vignette, we demonstrate how to work with tile-level embeddings
derived from whole-slide images (WSIs). Each tile corresponds to a patch
of the tissue, and its embedding is a high-dimensional vector capturing
visual and morphological features extracted from Prov-GigaPath.

We begin by importing the tile-level data using imageFeatureTCGA. Next,
we perform principal component analysis (PCA) to reduce the
high-dimensional embeddings to two principal components, which
facilitates visualization and preliminary exploration of the data. We
then visualize the spatial layout of the tiles on the tissue slide,
coloring by the principal components to examine patterns in the
embedding space.

# Loading packages

``` r
library(BiocStyle)
library(imageFeatureTCGA)
library(imageTCGAutils)
library(ggplot2)
library(dplyr)
library(sfdep)
library(spdep)
library(SpatialExperiment)
library(data.table)
```

# Import Prov-GigaPath tile level embeddings

``` r
## filter with catalog
getCatalog("provgigapath") |> 
    dplyr::filter(Project.ID == "TCGA-OV") |> 
    dplyr::pull(filename)

# select Ovarian Cancer Slide as an example
tile_prov_url <- paste0(
    "https://store.cancerdatasci.org/provgigapath/tile_level/",
    "TCGA-23-1021-01Z-00-DX1.F07C221B-D401-47A5-9519-10DE59CA1E9D.csv.gz"
)

example_slide <- ProvGiga(tile_prov_url) |>
    import()
```

# Embedding PCA

``` r
# Extract embedding numbers for pca
embedding_cols <- grep("^[0-9]+$", names(example_slide), value = TRUE)

# Run PCA
pca_res <- prcomp(example_slide[, embedding_cols], scale. = TRUE)

pca_example_slide <- bind_cols(
    example_slide,
    as_tibble(pca_res$x)[, 1:2] |> rename(PC1 = "PC1", PC2 = "PC2")
)
```

``` r
ggplot(pca_example_slide, aes(PC1, PC2)) +
    geom_point(alpha = 0.6, size = 1) +
    theme_minimal() +
    labs(title = "Tile-level PCA Ovarian Cancer Embedding: Single Slide")
```

<img src="/home/mramos/gh/imageTCGAutils/README_files/figure-gfm/visualize PC-1.png" alt="" width="100%" />

``` r


ggplot(pca_example_slide, aes(tile_x, tile_y, color = PC1)) +
    geom_point(size = 1) +
    scale_color_viridis_c() +
    coord_equal() +
    theme_minimal() +
    labs(title = "Tissue layout colored by PC1")
```

<img src="/home/mramos/gh/imageTCGAutils/README_files/figure-gfm/visualize PC-2.png" alt="" width="100%" />

# Spatial Patterns

To investigate spatial patterns in the tissue, we use the PCA-reduced
embeddings for each tile. Each tile has a physical location (tile_x,
tile_y) on the slide, which allows us to explore how similar embedding
values cluster across space. We construct a k-nearest neighbor graph to
define which tiles are spatially “connected,” and then compute global
and local spatial autocorrelation metrics.

``` r
coords <- pca_example_slide[, c("tile_x", "tile_y")]
nb <- knn2nb(knearneigh(coords, k = 6))
lw <- nb2listw(nb, style = "W")
```

Next, we calculate global spatial autocorrelation using Moran’s I and
Geary’s C, which quantify the overall tendency of similar PC1 values to
cluster or disperse on the tissue slide. We also compute Local Moran’s I
(LISA) to detect local clusters of similar embedding values.

``` r
mi <- moran.test(pca_example_slide$PC1, lw)
gc <- geary.test(pca_example_slide$PC1, lw)
lisa <- localmoran(pca_example_slide$PC1, lw)
pca_example_slide$localI <- lisa[, "Ii"]
pca_example_slide$localI_pval <- lisa[, "Pr(z != E(Ii))"]

mi
#> 
#>  Moran I test under randomisation
#> 
#> data:  pca_example_slide$PC1  
#> weights: lw    
#> 
#> Moran I statistic standard deviate = 71.599, p-value < 2.2e-16
#> alternative hypothesis: greater
#> sample estimates:
#> Moran I statistic       Expectation          Variance 
#>      6.134724e-01     -2.347418e-04      7.347018e-05
gc
#> 
#>  Geary C test under randomisation
#> 
#> data:  pca_example_slide$PC1 
#> weights: lw   
#> 
#> Geary C statistic standard deviate = 71.784, p-value < 2.2e-16
#> alternative hypothesis: Expectation greater than statistic
#> sample estimates:
#> Geary C statistic       Expectation          Variance 
#>      3.657367e-01      1.000000e+00      7.806998e-05
```

We visualize the spatial patterns. The Moran scatterplot shows the
relationship between each tile’s PC1 value and the mean of its
neighbors, while the LISA plot highlights local clusters (“hotspots”) of
high or low PC1 values across the tissue slide.

``` r
moran.plot(pca_example_slide$PC1, lw, labels = FALSE,
                main = "Moran scatterplot of PC1")
```

<img src="/home/mramos/gh/imageTCGAutils/README_files/figure-gfm/metrics 2-1.png" alt="" width="100%" />

``` r

# LISA visualization
df_lisa <- data.frame(coords, Ii = lisa[, "Ii"])
ggplot(df_lisa, aes(x = tile_x, y = tile_y, color = Ii)) +
    geom_point(size = 0.5) +
    scale_color_viridis_c() +
    coord_equal() +
    theme_minimal() +
    ggtitle("Local Moran's I (LISA) for PC1")
```

<img src="/home/mramos/gh/imageTCGAutils/README_files/figure-gfm/metrics 2-2.png" alt="" width="100%" />

# Adding HoverNet Nuclei Features

You can import HoVerNet segmentation results as a `SpatialExperiment` or
`SpatialFeatureExperiment`.

In this section we want show you hoe to integrate HoVerNet
classification and segmentation output with Prov-GigaPath embeddings.

``` r
# import HoVerNet
hov_file <- paste0(
    "https://store.cancerdatasci.org/hovernet/h5ad/",
    "TCGA-23-1021-01Z-00-DX1.F07C221B-D401-47A5-9519-10DE59CA1E9D.h5ad.gz"
)

hn_spe <- HoverNet(hov_file, outClass = "SpatialExperiment") |>
    import()

# import Prov-GigaPath
tile_prov_url <- paste0(
    "https://store.cancerdatasci.org/provgigapath/tile_level/",
    "TCGA-23-1021-01Z-00-DX1.F07C221B-D401-47A5-9519-10DE59CA1E9D.csv.gz"
)

pg_spe<- ProvGiga(tile_prov_url) |>
    import()
```

``` r
# Extract cell coordinates from HoVerNet
cell_coords <- spatialCoords(hn_spe)

# Extract nuclei metadata 
cell_meta <- colData(hn_spe)
cell_meta$x <-cell_coords[,1]
cell_meta$y <-cell_coords[,2]
```

# Visualizing Hovernet nuclei vs tile coordinates to see that they do not match

perfectly. You can use matchHoverNetToTiles to compute the scaling
factor.

``` r
plot(cell_meta$x, cell_meta$y, pch=16, col="#0000FF20")
points(pca_example_slide$tile_x, 
        pca_example_slide$tile_y, 
        pch=16, 
        col="#FF000020")
```

<img src="/home/mramos/gh/imageTCGAutils/README_files/figure-gfm/plotting hovernet vs tiles PCA-1.png" alt="" width="100%" />

# Scale factor between nuclei coordinates and tile coordinates

``` r
match_hv_pg <- matchHoverNetToTiles(hn_spe, pg_spe)
```

``` r
ggplot(match_hv_pg$tiles_with_nuclei, aes(tile_x, tile_y, 
                                    color = cell_type_label, 
                                    size = N)) +
    geom_point(alpha = 0.7) +
    coord_equal() +
    theme_minimal() +
    labs(title = "All HoverNet cell types per tile")
#> Warning: Removed 389 rows containing missing values or values outside the scale range
#> (`geom_point()`).
```

<img src="/home/mramos/gh/imageTCGAutils/README_files/figure-gfm/visualizing tile level with hovernet-1.png" alt="" width="100%" />

``` r

ggplot(match_hv_pg$tiles_with_nuclei, aes(tile_x, tile_y, 
                                    color = dominant_cell_type)) +
    geom_point(size = 2) +
    coord_equal() +
    theme_minimal() +
    labs(title = "Per-tile dominant HoverNet cell type")
```

<img src="/home/mramos/gh/imageTCGAutils/README_files/figure-gfm/visualizing tile level with hovernet-2.png" alt="" width="100%" />

# Session Info

``` r
sessionInfo()
#> R Under development (unstable) (2025-10-28 r88973)
#> Platform: x86_64-pc-linux-gnu
#> Running under: Ubuntu 24.04.4 LTS
#> 
#> Matrix products: default
#> BLAS/LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so;  LAPACK version 3.12.0
#> 
#> locale:
#>  [1] LC_CTYPE=en_US.UTF-8       LC_NUMERIC=C               LC_TIME=en_US.UTF-8       
#>  [4] LC_COLLATE=en_US.UTF-8     LC_MONETARY=en_US.UTF-8    LC_MESSAGES=en_US.UTF-8   
#>  [7] LC_PAPER=en_US.UTF-8       LC_NAME=C                  LC_ADDRESS=C              
#> [10] LC_TELEPHONE=C             LC_MEASUREMENT=en_US.UTF-8 LC_IDENTIFICATION=C       
#> 
#> time zone: America/New_York
#> tzcode source: system (glibc)
#> 
#> attached base packages:
#> [1] stats4    stats     graphics  grDevices utils     datasets  methods   base     
#> 
#> other attached packages:
#>  [1] data.table_1.18.2.1         SpatialExperiment_1.21.0    SingleCellExperiment_1.33.0
#>  [4] SummarizedExperiment_1.41.0 Biobase_2.71.0              GenomicRanges_1.63.1       
#>  [7] Seqinfo_1.1.0               IRanges_2.45.0              S4Vectors_0.49.0           
#> [10] BiocGenerics_0.57.0         generics_0.1.4              MatrixGenerics_1.23.0      
#> [13] matrixStats_1.5.0           spdep_1.4-1                 sf_1.0-24                  
#> [16] spData_2.3.4                sfdep_0.2.5                 dplyr_1.1.4                
#> [19] ggplot2_4.0.1               BiocStyle_2.39.0            imageFeatureTCGA_0.99.56   
#> [22] imageTCGAutils_0.99.11      colorout_1.3-2             
#> 
#> loaded via a namespace (and not attached):
#>   [1] RColorBrewer_1.1-3   wk_0.9.5             sys_3.4.3            rstudioapi_0.18.0   
#>   [5] jsonlite_2.0.0       magrittr_2.0.4       TH.data_1.1-5        magick_2.9.0        
#>   [9] farver_2.1.2         rmarkdown_2.30       fs_1.6.6             BiocIO_1.21.0       
#>  [13] vctrs_0.6.5          memoise_2.0.1        askpass_1.2.1        htmltools_0.5.9     
#>  [17] S4Arrays_1.11.1      BiocBaseUtils_1.13.0 usethis_3.2.1        curl_7.0.0          
#>  [21] Rhdf5lib_1.33.0      s2_1.1.9             LearnBayes_2.15.2    SparseArray_1.11.10 
#>  [25] rhdf5_2.55.12        KernSmooth_2.23-26   desc_1.4.3           sandwich_3.1-1      
#>  [29] httr2_1.2.2          zoo_1.8-15           cachem_1.1.0         igraph_2.2.1        
#>  [33] lifecycle_1.0.4      pkgconfig_2.0.3      Matrix_1.7-4         R6_2.6.1            
#>  [37] fastmap_1.2.0        anndataR_1.1.0       selectr_0.5-1        digest_0.6.39       
#>  [41] ps_1.9.1             TENxIO_1.13.3        pkgload_1.4.1        RSQLite_2.4.5       
#>  [45] labeling_0.4.3       filelock_1.0.3       spatialreg_1.4-2     httr_1.4.7          
#>  [49] abind_1.4-8          compiler_4.6.0       proxy_0.4-29         remotes_2.5.0       
#>  [53] bit64_4.6.0-1        withr_3.0.2          S7_0.2.1             DBI_1.2.3           
#>  [57] rjsoncons_1.3.2      pkgbuild_1.4.8       MASS_7.3-65          openssl_2.3.4       
#>  [61] rappdirs_0.3.4       DelayedArray_0.37.0  sessioninfo_1.2.3    rjson_0.2.23        
#>  [65] classInt_0.4-11      tools_4.6.0          chromote_0.5.1       units_1.0-0         
#>  [69] BiocAddins_0.99.26   otel_0.2.0           glue_1.8.0           dbscan_1.2.3        
#>  [73] nlme_3.1-168         rhdf5filters_1.23.3  promises_1.5.0       grid_4.6.0          
#>  [77] rsconnect_1.7.0      gtable_0.3.6         tzdb_0.5.0           class_7.3-23        
#>  [81] websocket_1.4.4      hms_1.1.4            sp_2.2-0             xml2_1.5.1          
#>  [85] XVector_0.51.0       stringr_1.6.0        pillar_1.11.1        vroom_1.6.6         
#>  [89] later_1.4.4          splines_4.6.0        BiocFileCache_3.1.0  lattice_0.22-7      
#>  [93] survival_3.8-6       bit_4.6.0            deldir_2.0-4         tidyselect_1.2.1    
#>  [97] knitr_1.51           xfun_0.56            devtools_2.4.6       credentials_2.0.3   
#>  [ reached 'max' / getOption("max.print") -- omitted 30 entries ]
```
