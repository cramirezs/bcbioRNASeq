#' Methods for Coercing an Object to a Class
#'
#' @name coerce
#' @aliases as
#' @family S4 Object
#' @author Michael Steinbaugh
#'
#' @inherit bcbioBase::coerce
#'
#' @seealso
#' - [methods::as()].
#' - [methods::coerce()].
#'
#' @examples
#' # DESeqDataSet ====
#' x <- as(bcb_small, "DESeqDataSet")
#' names(S4Vectors::mcols(x))
#' class(x)
#' show(x)
#'
#' # RangedSummarizedExperiment ====
#' x <- as(bcb_small, "RangedSummarizedExperiment")
#' slotNames(x)
#' show(x)
#'
#' # SummarizedExperiment ====
#' # Coerce to RangedSummarizedExperiment first.
#' x <- as(bcb_small, "RangedSummarizedExperiment")
#' x <- as(x, "SummarizedExperiment")
#' class(x)
#' slotNames(x)
#' show(x)
NULL



# Methods ======================================================================
#' @rdname coerce
#' @name coerce-bcbioRNASeq-DESeqDataSet
setAs(
    from = "bcbioRNASeq",
    to = "DESeqDataSet",
    function(from) {
        validObject(from)
        if (metadata(from)[["level"]] != "genes") {
            stop("Gene-level counts are required")
        }
        # Creating `DESeqDataSet` from `RangedSummarizedExperiment` is
        # preferable to `DESeqDataSetFromTximport` method because `rowRanges`
        # are defined, with richer metadata
        rse <- as(from, "RangedSummarizedExperiment")
        # Integer counts are required
        assay(rse) <- round(assay(rse))
        # Prepare using an empty design formula
        to <- DESeqDataSet(
            se = rse,
            design = ~ 1  # nolint
        )
        validObject(to)
        to
    }
)
