run_analysis <- function(coefs, ewas, selected_traits = NULL) {

	if (!is.null(selected_traits)) {
	    ewas_db <- ewas_db[ewas_db$trait %in% selected_traits, ]
	  }

	merged <- merge(user_cpgs_df, ewas_db, by = "cpg_id")
	  
	if (nrow(merged) == 0) {
	  return(list(error = "Nė vienas CpG nepersiklojo su EWAS duomenimis"))
	}

	results <- do.call(rbind, lapply(split(merged, merged$trait), function(df) {
	    data.frame(
	      trait        = df$trait[1],
	      n_overlap    = nrow(df),            # kiek CpG persiklojo
	      pct_overlap  = nrow(df) / nrow(user_cpgs_df) * 100,
	      weighted_r   = sum(df$coefficient * df$effect_size, na.rm = TRUE)
	    )
	  }))
	  
	  results[order(-abs(results$weighted_r)), ]

	  
}
