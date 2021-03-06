context("Gene Expression Functions")

genes <- head(rownames(bcb_small), 4L)
gene2symbol <- gene2symbol(bcb_small)



# plotGenderMarkers ============================================================
test_that("plotGenderMarkers : bcbioRNASeq", {
    p <- plotGenderMarkers(bcb_small)
    expect_is(p, "ggplot")
})

test_that("plotGenderMarkers : DESeqDataSet", {
    p <- plotGenderMarkers(dds_small, interestingGroups = "treatment")
    expect_is(p, "ggplot")
})

test_that("plotGenderMarkers : DESeqTransform", {
    p <- plotGenderMarkers(rld_small, interestingGroups = "treatment")
    expect_is(p, "ggplot")
})



# plotGene =====================================================================
test_that("plotGene : bcbioRNASeq", {
    # facet
    p <- plotGene(bcb_small, genes = genes, return = "facet")
    expect_is(p, "ggplot")

    # wide
    p <- plotGene(bcb_small, genes = genes, return = "wide")
    expect_is(p, "ggplot")

    # grid
    p <- plotGene(bcb_small, genes = genes, return = "grid")
    expect_is(p, "ggplot")

    # markdown
    gene <- gene2symbol[1L, "geneName", drop = TRUE]
    output <- capture.output(
        plotGene(bcb_small, genes = genes, return = "markdown")
    )
    expect_identical(
        output[[3L]],
        paste("##", gene)
    )

    # list
    x <- plotGene(bcb_small, genes = genes, return = "list")
    expect_is(x, "list")
    expect_true(
        lapply(x, function(x) is(x, "ggplot")) %>%
            unlist() %>%
            all()
    )
})

test_that("plotGene : DESeqDataSet", {
    p <- plotGene(dds_small, genes = genes)
    expect_is(p, "ggplot")
})

test_that("plotGene : DESeqTransform", {
    p <- plotGene(rld_small, genes = genes)
    expect_is(p, "ggplot")
})



# plotHeatmap ==================================================================
test_that("plotHeatmap : bcbioRNASeq", {
    genes <- head(rownames(bcb_small), n = 100L)
    p <- plotHeatmap(bcb_small[genes, ])
    expect_identical(names(p), pheatmapNames)
})

test_that("plotHeatmap : DESeqDataSet", {
    genes <- head(rownames(dds_small), n = 20L)
    p <- plotHeatmap(dds_small[genes, ])
    expect_identical(names(p), pheatmapNames)
})
