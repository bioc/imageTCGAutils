#' @importFrom rvest html_nodes html_table html_element html_attr read_html
#' @importFrom httr2 request req_perform resp_body_string
.see_more_table <- function(u24_url, verbose = TRUE) {
    results <- list()
    current_url <- u24_url
    page_count <- 1

    while (!is.null(current_url)) {
        page_html <- request(current_url) |>
            req_perform() |>
            resp_body_string() |>
            read_html()

        table_data <- page_html |>
            html_nodes("table") |>
            html_table(fill = TRUE)

        results[[page_count]] <- table_data

        cursor_node <- page_html |>
            html_element("a:contains('see more')")

        if (!is.na(cursor_node)) {
            query_string <- html_attr(cursor_node, "href")
            current_url <- paste0(u24_url, query_string)
            page_count <- page_count + 1
        } else {
            current_url <- NULL
            if (verbose)
                message("Total pages fetched: ", page_count)
        }
    }
    dplyr::bind_rows(
        unlist(results, recursive = FALSE)
    )
}
