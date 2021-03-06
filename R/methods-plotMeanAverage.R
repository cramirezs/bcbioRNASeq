#' Plot Mean Average
#'
#' @name plotMeanAverage
#' @family Differential Expression Functions
#' @author Rory Kirchner, Michael Steinbaugh
#'
#' @inheritParams general
#'
#' @return `ggplot`.
#'
#' @seealso [DESeq2::plotMA()].
#'
#' @examples
#' gene2symbol <- gene2symbol(bcb_small)
#'
#' # DESeqResults ====
#' # Color DEGs in each direction separately
#' plotMeanAverage(
#'     object = res_small,
#'     sigPointColor = c(
#'         upregulated = "purple",
#'         downregulated = "orange"
#'     )
#' )
#'
#' # Label DEGs with a single color
#' plotMeanAverage(res_small, sigPointColor = "purple")
#'
#' # Directional support
#' plotMeanAverage(
#'     object = res_small,
#'     direction = "up",
#'     ntop = 5L,
#'     gene2symbol = gene2symbol
#' )
#' plotMeanAverage(
#'     object = res_small,
#'     direction = "down",
#'     ntop = 5L,
#'     gene2symbol = gene2symbol
#' )
#'
#' # Label genes manually
#' plotMeanAverage(
#'     object = res_small,
#'     genes = head(rownames(res_small)),
#'     gene2symbol = gene2symbol
#' )
NULL



# Methods ======================================================================
#' @rdname plotMeanAverage
#' @export
setMethod(
    "plotMeanAverage",
    signature("DESeqResults"),
    function(
        object,
        alpha,
        lfcThreshold = 0L,
        genes = NULL,
        gene2symbol = NULL,
        ntop = 0L,
        direction = c("both", "up", "down"),
        pointColor = "gray50",
        sigPointColor = c(
            upregulated = "purple",
            downregulated = "orange"
        ),
        return = c("ggplot", "data.frame")
    ) {
        validObject(object)
        if (missing(alpha)) {
            alpha <- metadata(object)[["alpha"]]
        }
        assert_is_a_number(alpha)
        assert_all_are_in_left_open_range(alpha, 0L, 1L)
        assert_is_a_number(lfcThreshold)
        assert_all_are_non_negative(lfcThreshold)
        assertFormalGene2symbol(object, genes, gene2symbol)
        direction <- match.arg(direction)
        assert_all_are_non_negative(ntop)
        assert_is_a_string(pointColor)
        assert_is_character(sigPointColor)
        if (is_a_string(sigPointColor)) {
            sigPointColor <- c(
                "upregulated" = sigPointColor,
                "downregulated" = sigPointColor
            )
        }
        assert_is_of_length(sigPointColor, 2L)
        return <- match.arg(return)

        # Check to see if we should use `sval` instead of `padj`
        if ("svalue" %in% names(object)) {
            testCol <- "svalue"
        } else {
            testCol <- "padj"
        }

        lfcCol <- "log2FoldChange"

        data <- object %>%
            as.data.frame() %>%
            rownames_to_column("geneID") %>%
            as_tibble() %>%
            camel() %>%
            # Remove genes with very low expression
            filter(!!sym("baseMean") >= 1L) %>%
            mutate(rankScore = abs(!!sym("log2FoldChange"))) %>%
            arrange(desc(!!sym("rankScore"))) %>%
            mutate(rank = row_number()) %>%
            .addIsDECol(
                testCol = testCol,
                alpha = alpha,
                lfcCol = lfcCol,
                lfcThreshold = lfcThreshold
            )

        if (direction == "up") {
            data <- data[data[[lfcCol]] > 0L, , drop = FALSE]
        } else if (direction == "down") {
            data <- data[data[[lfcCol]] < 0L, , drop = FALSE]
        }

        # Gene-to-symbol mappings
        if (is.data.frame(gene2symbol)) {
            assertIsGene2symbol(gene2symbol)
            labelCol <- "geneName"
            data <- left_join(data, gene2symbol, by = "geneID")
        } else {
            labelCol <- "geneID"
        }

        # Early return data frame, if desired
        if (return == "data.frame") {
            data <- data %>%
                as.data.frame() %>%
                column_to_rownames("geneID")
            return(data)
        }

        xFloor <- data[["baseMean"]] %>%
            min() %>%
            log10() %>%
            floor()
        xCeiling <- data[["baseMean"]] %>%
            max() %>%
            log10() %>%
            ceiling()
        xBreaks <- 10L ^ seq(from = xFloor, to = xCeiling, by = 1L)

        p <- ggplot(
            data = data,
            mapping = aes_string(
                x = "baseMean",
                y = lfcCol,
                color = "isDE"
            )
        ) +
            geom_hline(
                yintercept = 0L,
                size = 0.5,
                color = pointColor
            ) +
            geom_point(size = 1L) +
            scale_x_continuous(
                breaks = xBreaks,
                limits = c(1L, NA),
                trans = "log10"
            ) +
            scale_y_continuous(breaks = pretty_breaks()) +
            annotation_logticks(sides = "b") +
            guides(color = FALSE) +
            labs(
                title = contrastName(object),
                x = "mean expression across all samples",
                y = "log2 fold change"
            )

        if (is_a_string(pointColor) && is.character(sigPointColor)) {
            p <- p +
                scale_colour_manual(
                    values = c(
                        # nonsignificant
                        "0" = pointColor,
                        # upregulated
                        "1" = sigPointColor[[1L]],
                        # downregulated
                        "-1" = sigPointColor[[2L]]
                    )
                )
        }

        # Gene text labels =====================================================
        labelData <- NULL
        if (is.null(genes) && is_positive(ntop)) {
            genes <- data[1L:ntop, "geneID", drop = TRUE]
        }
        if (is.character(genes)) {
            assert_is_subset(genes, data[["geneID"]])
            labelData <- data[data[["geneID"]] %in% genes, , drop = FALSE]
            p <- p +
                bcbio_geom_label_repel(
                    data = labelData,
                    mapping = aes_string(
                        x = "baseMean",
                        y = lfcCol,
                        label = labelCol
                    )
                )
        }

        p
    }
)
