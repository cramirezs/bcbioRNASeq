#' Plot DEG PCA
#'
#' @name plotDEGPCA
#' @family Differential Expression Functions
#' @author Michael Steinbaugh
#'
#' @inherit plotPCA
#' @inheritParams general
#'
#' @examples
#' # DESeqResults, SummarizedExperiment ====
#' plotDEGPCA(
#'     results = res_small,
#'     counts = rld_small,
#'     label = TRUE
#' )
#'
#' # DESeqResults, bcbioRNASeq ====
#' plotDEGPCA(
#'     results = res_small,
#'     counts = bcb_small,
#'     label = TRUE
#' )
NULL



# Methods ======================================================================
#' @rdname plotDEGPCA
#' @export
setMethod(
    "plotDEGPCA",
    signature(
        results = "DESeqResults",
        counts = "SummarizedExperiment"
    ),
    function(
        results,
        counts,
        interestingGroups,
        alpha,
        lfcThreshold = 0L,
        direction = c("both", "up", "down"),
        color = NULL,
        label = FALSE,
        return = c("ggplot", "data.frame")
    ) {
        validObject(results)
        validObject(counts)
        if (missing(interestingGroups)) {
            interestingGroups <- bcbioBase::interestingGroups(counts)
        } else {
            interestingGroups(counts) <- interestingGroups
        }
        if (missing(alpha)) {
            alpha <- metadata(results)[["alpha"]]
        }
        assert_is_a_number(alpha)
        assert_is_a_number(lfcThreshold)
        assert_all_are_non_negative(lfcThreshold)
        assertIsColorScaleDiscreteOrNULL(color)
        direction <- match.arg(direction)
        assert_is_a_bool(label)
        return <- match.arg(return)

        # Get DEG vector using DEGreport
        if (direction == "both") {
            direction <- NULL
        }
        deg <- significants(
            results,
            padj = alpha,
            fc = lfcThreshold,
            direction = direction
        )

        # Early return if there are no DEGs
        if (!length(deg)) {
            return(invisible())
        }

        # Subset the counts
        counts <- counts[deg, , drop = FALSE]

        # SummarizedExperiment method
        rse <- as(counts, "RangedSummarizedExperiment")
        plotPCA(
            object = rse,
            genes = rownames(rse),
            interestingGroups = interestingGroups,
            label = label,
            title = contrastName(results),
            subtitle = paste(nrow(rse), "genes"),
            return = return
        )
    }
)



#' @rdname plotDEGPCA
#' @export
setMethod(
    "plotDEGPCA",
    signature(
        results = "DESeqResults",
        counts = "DESeqDataSet"
    ),
    function(
        results,
        counts,
        ...
    ) {
        validObject(counts)
        message("Using normalized counts")
        rse <- as(counts, "RangedSummarizedExperiment")
        assay(rse) <- counts(counts, normalized = TRUE)
        plotDEGPCA(
            results = results,
            counts = rse,
            ...
        )
    }
)



#' @rdname plotDEGPCA
#' @export
setMethod(
    "plotDEGPCA",
    signature(
        results = "DESeqResults",
        counts = "bcbioRNASeq"
    ),
    function(
        results,
        counts,
        normalized = c("vst", "rlog", "tmm", "tpm", "rle"),
        ...
    ) {
        validObject(counts)
        normalized <- match.arg(normalized)
        message(paste("Using", normalized, "counts"))
        rse <- as(counts, "RangedSummarizedExperiment")
        assay(rse) <- counts(counts, normalized = normalized)
        plotDEGPCA(
            results = results,
            counts = rse,
            ...
        )
    }
)
