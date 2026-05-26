run_analysis <- function(clock, ewas, selected_traits = NULL, multiplier = NULL) {
  
  if (!is.null(selected_traits) && length(selected_traits) > 0) {
    ewas <- ewas[ewas$trait %in% selected_traits, ]
  }
  
  clock_clean   <- clock[!is.na(clock$coef), ]
  n_clock_total <- nrow(clock_clean)
  scale_factor  <- ifelse(is.null(multiplier), 1, multiplier)
  groups        <- split(ewas, list(ewas$trait, ewas$pmid), drop = TRUE)
  
  results <- do.call(rbind, lapply(groups, function(study) {
    
    common <- merge(clock_clean, study, by = "cpg")
    if (nrow(common) == 0) return(NULL)
    
    contrib   <- common$coef * common$beta
    direction <- ifelse(contrib > 0, "sendina", "jaunina")
    
    n_common <- nrow(common)
    pct      <- function(x) round(100 * x / n_clock_total, 1)
    
    data.frame(
      trait       = study$trait[1],
      pmid        = study$pmid[1],
      sample      = study$sample_size[1],
      cpg_study   = nrow(study),
      cpg_clock   = n_clock_total,
      cpg_overlap = n_common,
      pct_overlap = pct(n_common),
      cpg_sendina = sum(direction == "sendina"),
      cpg_jaunina = sum(direction == "jaunina"),
      pct_sendina = pct(sum(direction == "sendina")),
      pct_jaunina = pct(sum(direction == "jaunina")),
      score       = round(sum(contrib) * scale_factor, 6),
      stringsAsFactors = FALSE
    )
  }))
  
  if (is.null(results)) return(data.frame(error = "Nėra persiklojančių CpG"))
  rownames(results) <- NULL
  results[order(-abs(results$score)), ]
}

run_analysis_mean <- function(clock, ewas, selected_traits = NULL) {
  
  if (!is.null(selected_traits) && length(selected_traits) > 0) {
    ewas <- ewas[ewas$trait %in% selected_traits, ]
  }
  
  clock_clean <- clock[!is.na(clock$cpg), ]
  groups      <- split(ewas, list(ewas$trait, ewas$pmid), drop = TRUE)
  
  results <- do.call(rbind, lapply(groups, function(study) {
    
    common <- merge(clock_clean, study, by = "cpg")
    if (nrow(common) == 0) return(NULL)
    
    data.frame(
      trait       = study$trait[1],
      pmid        = study$pmid[1],
      sample      = study$sample_size[1],
      cpg_study   = nrow(study),
      cpg_clock   = nrow(clock_clean),
      cpg_overlap = nrow(common),
      pct_overlap = round(100 * nrow(common) / nrow(clock_clean), 1),
      cpg_sendina = NA,
      cpg_jaunina = NA,
      pct_sendina = NA,
      pct_jaunina = NA,
      score       = round(mean(common$beta, na.rm = TRUE), 6),
      stringsAsFactors = FALSE
    )
  }))
  
  if (is.null(results)) return(data.frame(error = "Nėra persiklojančių CpG"))
  rownames(results) <- NULL
  results[order(-abs(results$score)), ]
}
