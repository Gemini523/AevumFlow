run_analysis <- function(clock, ewas, selected_traits = NULL) {

  # Traits filtras
  if (!is.null(selected_traits) && length(selected_traits) > 0) {
    ewas <- ewas[ewas$trait %in% selected_traits, ]
  }

  # Skaičiavimas pagal kiekvieną trait+pmid kombinaciją
  groups <- split(ewas, list(ewas$trait, ewas$pmid), drop = TRUE)

  results <- do.call(rbind, lapply(groups, function(study) {

    common <- merge(clock, study, by = "cpg")

    if (nrow(common) == 0) return(NULL)

    data.frame(
      trait        = study$trait[1],
      pmid         = study$pmid[1],
      n_clock      = nrow(clock),
      n_study      = nrow(study),
      n_overlap    = nrow(common),
      pct_overlap  = round(nrow(common) / nrow(clock) * 100, 1),
      score        = round(sum(common$beta * common$coef, na.rm = TRUE), 6)
    )
  }))

  if (is.null(results)) return(data.frame(error = "Nėra persiklojančių CpG"))

  rownames(results) <- NULL
  results[order(-abs(results$score)), ]
}
