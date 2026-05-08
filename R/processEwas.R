# COMMENTS

ewas <- readRDS("../ewas/ewasatlas_blood.rds")

ewas$trait <- iconv(ewas$trait, from = "latin1", to = "UTF-8", sub = "?")

ewas <- ewas[ewas$sample_size >= 100 & !is.na(ewas$effect_size), ]

names(ewas)[names(ewas) == "id"] <- "cpg"
