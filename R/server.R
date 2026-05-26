Sys.setlocale("LC_ALL", "en_US.UTF-8")
options(shiny.usecairo = TRUE)
library(shiny)
options(shiny.maxRequestSize = 50 * 1024^2)  # 50 MB upload limit
library(DT)
library(pheatmap)
library(openxlsx)
library(ape)
source("R/calculations.R")
source("R/ui.R")

JACCARD_WHITELIST <- readRDS("data/jaccard_whitelist.rds")

EWAS_SOURCES <- list(
  atlas   = readRDS("data/ewas_atlas.rds"),
  catalog = readRDS("data/ewas_catalog.rds"),
  custom  = readRDS("data/ewas_custom.rds"),
  all     = readRDS("data/ewas_all.rds")
)

EWAS_FULL <- list(
  atlas   = readRDS("data/ewas_atlas_full.rds"),
  catalog = readRDS("data/ewas_catalog_full.rds"),
  custom  = readRDS("data/ewas_custom_full.rds"),
  all     = readRDS("data/ewas_all_full.rds")
)

CLOCKS <- list(
  adaptage        = readRDS("input/adaptage.rds"),
  causage         = readRDS("input/causage.rds"),
  damage          = readRDS("input/damage.rds"),
  hannum          = readRDS("input/hannum.rds"),
  horvath         = readRDS("input/horvath.rds"),
  intrinclock     = readRDS("input/intrinclock.rds"),
  icage           = readRDS("input/icage.rds"),
  phenoage        = readRDS("input/phenoage.rds"),
  retroelementV1  = readRDS("input/retroelementV1.rds"),
  retroelementV2  = readRDS("input/retroelementV2.rds"),
  skinandblood    = readRDS("input/skinandblood.rds"),
  epitoc          = readRDS("input/epitoc.rds"),
  epitoc2         = readRDS("input/epitoc2.rds"),
  miage           = readRDS("input/miage.rds")
)

CLOCKS_PC <- list(
  pc_dnamtl       = readRDS("input/pc_dnamtl.rds"),
  pc_grimage      = readRDS("input/pc_grimage.rds"),
  pc_hannum       = readRDS("input/pc_hannum.rds"),
  pc_horvath      = readRDS("input/pc_horvath.rds"),
  pc_phenoage     = readRDS("input/pc_phenoage.rds"),
  pc_skinandblood = readRDS("input/pc_skinandblood.rds")
)

CLOCK_COLORS <- c(
  adaptage        = "#E7298A",
  causage         = "#1B9444",
  damage          = "#1B9E77",
  hannum          = "#7B2D8B",
  horvath         = "#66C2A5",
  intrinclock     = "#D6A520",
  icage           = "#4D4D4D",
  phenoage        = "#F46D43",
  retroelementV1  = "#7570B3",
  retroelementV2  = "#9590C3",
  skinandblood    = "#4393C3",
  pc_dnamtl       = "#377EB8",
  pc_grimage      = "#FC8D62",
  pc_hannum       = "#FFD92F",
  pc_horvath      = "#A6D854",
  pc_phenoage     = "#E5C494",
  pc_skinandblood = "#B3B3B3",
  epitoc          = "#FF6B6B",
  epitoc2         = "#6BCB77",
  miage           = "#600007"
)

CLOCK_LABELS <- c(
  adaptage        = "AdaptAge",
  causage         = "CauseAge",
  damage          = "DamAge",
  hannum          = "Hannum",
  horvath         = "Horvath",
  intrinclock     = "Intrinclock",
  icage           = "ICage",
  phenoage        = "PhenoAge",
  retroelementV1  = "RetroElementV1",
  retroelementV2  = "RetroElementV2",
  skinandblood    = "Skinandblood",
  pc_dnamtl       = "PCDnamTL",
  pc_grimage      = "PCGrimAge",
  pc_hannum       = "PCHannum",
  pc_horvath      = "PCHorvath",
  pc_phenoage     = "PCPhenoage",
  pc_skinandblood = "PCskinAndBlood",
  epitoc          = "EpiToc",
  epitoc2         = "EpiToc2",
  miage           = "MiAge"
)

TRAIT_GROUPS <- list(
  "Senėjimas" = c(
    "aging", "facial aging"
    
  ),
  "Su motina susiję veiksniai" = c(
    "maternal smoking", "maternal smoking during pregnancy",
    "maternal body mass index", "maternal pre-pregnancy obesity",
    "maternal pre-pregnancy body mass index", "maternal rheumatoid arthritis",
    "maternal haemoglobin levels during pregnancy",
    "maternal education at the time of pregnancy",
    "gestational age", "gestational diabetes mellitus",
    "birthweight", "parity",
    "a lifestyle intervention in pregnant women with obesity"
  ),
  "Svoris / nutukimas" = c(
    "body mass index", "bmi", "obesity", "childhood obesity",
    "waist circumference", "waist circumfrence",
    "waist circumference-to-hip ratio",
    "hypertriglyceridemic waist",
    "paternal body mass index",
    "liver fat", "weight loss",
    "adiponectin levels"
  ),
  "Medžiagų apykaita" = c(
    "type 2 diabetes", "type ii diabetes",
    "fasting glucose", "fasting insulin", "fasting plasma glucose",
    "hba1c", "blood triglyceride levels", "metabolic trait",
    "serum liver enzyme levels", "diabetic kidney disease",
    "diabetic kidney disease (dkd)",
    "diet quality alternative healthy eating index 2010 (ahei-2010)",
    "vitamin b6 intake", "Vitamin C intake",
    "ratio of oxidised glutathione to reduced glutathione"
  ),
  "Širdis / kraujagyslės" = c(
    "diastolic blood pressure", "systolic blood pressure",
    "myocardial infarction", "acute myocardial infarction",
    "c-reactive protein", "c-reactive protein (crp) levels",
    "cardiovascular disease risk", "coronary heart disease",
    "risk of CVD", "sTNFR2"
  ),
  "Imuniniai / uždegiminiai" = c(
    "systemic lupus erythematosus",
    "autoantibody production in systemic lupus erythematosus",
    "primary Sjorgens syndrome", "primary sjvgren's syndrome",
    "inflammatory bowel disease", "crohn's disease",
    "serum immunoglobulin e  levels", "rheumatoid arthritis",
    "behcet's disease", "mixed connective tissue disease",
    "igg4-related cholangitis", "allergic sensitization"
  ),
  "Neurologiniai / psichiatriniai" = c(
    "schizophrenia", "psychosis", "autism spectrum disorders",
    "aggressive behavior", "lifetime cannabis use",
    "post-traumatic stress disorder", "depression",
    "polygenic risk scores for major depressive disorder",
    "tic disorders", "fluid type general intelligence", "cognitive function"
  ),
  "Infekcijos" = c(
    "HIV", "hiv infection", "HIV and antiretroviral therapy",
    "perinatally-acquired hiv", "COVID-19",
    "creutzfeldt\026jakob disease"
  ),
  "Rūkymo poveikiai" = c(
    "smoking"
  ),
  
  "Genetiniai / sindromai" = c(
    "downs syndrome", "kabuki syndrome",
    "apoe e2 vs e4", "genetic risk score",
    "perimembranous ventricular septal defect"
  ),
  "Socialiniai veiksniai" = c(
    "educational attainment", "migration in Italy",
    "childhood adversity", "childhood sexual victimization",
    "sexual abuse", "gender"
  ),
  "Kita" = c(
    "breast cancer", "b-cell chronic lymphocytic leukemia",
    "lung cancer", "malignant pleural mesothelioma",
    "fev1", "lung function", "tooth mobility",
    "air pollution",
    "particulate matter <2.5um (pm2.5)", "nitrogen dioxide exposure",
    "arsenic exposure", "urinary cadmium",
    "polychlorinated biphenyls (PCBs) exposure",
    "trihalomethanes", "trihalomethanes  exposure",
    "alcohol consumption", "alcohol consumption per day",
    "aclohol use disorder", "death risk", "mortality", "old-age mortality"
  )
)

{
  assigned <- unique(unlist(TRAIT_GROUPS))
  all_known <- sort(unique(unlist(lapply(EWAS_SOURCES, function(x) x$trait))))
  unassigned <- setdiff(all_known, assigned)
  if (length(unassigned) > 0)
    TRAIT_GROUPS[["Kita"]] <- unique(c(TRAIT_GROUPS[["Kita"]], unassigned))
}

all_traits       <- sort(unique(unlist(lapply(EWAS_SOURCES, function(x) x$trait))))
clocks           <- c("intrinclock", "horvath", "pc_horvath", "skinandblood", "pc_skinandblood")
CLOCK_MULTIPLIER <- setNames(rep(21, length(clocks)), clocks)

safe_dist_rows <- function(mat) {
  tryCatch(
    as.dist(1 - cor(t(mat), use = "pairwise.complete.obs")),
    error   = function(e) "euclidean",
    warning = function(w) "euclidean"
  )
}
safe_dist_cols <- function(mat) {
  tryCatch(
    as.dist(1 - cor(mat, use = "pairwise.complete.obs")),
    error   = function(e) "euclidean",
    warning = function(w) "euclidean"
  )
}
make_heatmap <- function(df, title, na_col) {
  agg <- aggregate(score ~ trait + pmid + clock, data = df, FUN = sum)
  agg$trait_pmid <- paste0(agg$trait, " [", agg$pmid, "]")
  mat <- reshape(agg[, c("trait_pmid", "clock", "score")],
                 idvar = "trait_pmid", timevar = "clock", direction = "wide")
  rownames(mat)  <- mat$trait_pmid
  mat$trait_pmid <- NULL
  colnames(mat)  <- sub("score\\.", "", colnames(mat))
  mat            <- as.matrix(mat)
  mat[is.na(mat)] <- 0
  if (nrow(mat) == 0) return(NULL)
  
  all_clock_names <- c("adaptage","causage","damage","hannum","horvath",
                       "intrinclock","icage","phenoage","retroelementV1",
                       "retroelementV2","skinandblood","epitoc","epitoc2","miage",
                       "pc_dnamtl","pc_grimage","pc_hannum","pc_horvath",
                       "pc_phenoage","pc_skinandblood")
  missing_clocks <- setdiff(all_clock_names, colnames(mat))
  if (length(missing_clocks) > 0) {
    extra <- matrix(0, nrow = nrow(mat), ncol = length(missing_clocks),
                    dimnames = list(rownames(mat), missing_clocks))
    mat <- cbind(mat, extra)
  }
  mat <- mat[, all_clock_names[all_clock_names %in% colnames(mat)], drop = FALSE]
  
  row_trait   <- sub(" \\[.*\\]$", "", rownames(mat))
  group_order <- unlist(lapply(names(TRAIT_GROUPS), function(g)
    rownames(mat)[row_trait %in% TRAIT_GROUPS[[g]]]
  ))
  other_rows  <- setdiff(rownames(mat), group_order)
  mat         <- mat[c(group_order, other_rows), , drop=FALSE]
  mat_log <- sign(mat) * log(abs(mat) + 1)
  mat_log[is.nan(mat_log)]      <- 0
  mat_log[is.infinite(mat_log)] <- 0
  num_mat    <- matrix(sprintf("%.3f", mat), nrow(mat), ncol(mat), dimnames = dimnames(mat))
  cap        <- quantile(abs(mat_log[is.finite(mat_log) & mat_log != 0]), 0.95, na.rm = TRUE)
  if (is.na(cap) || !is.finite(cap)) cap <- 1
  clust_cols <- ncol(mat) > 1
  cellheight <- max(14, min(28, round(600  / nrow(mat))))
  list(mat_log = mat_log, num_mat = num_mat, cap = cap,
       clust_cols = clust_cols, cellheight = cellheight, mat = mat)
}

`%||%` <- function(a, b) if (!is.null(a)) a else b

# ── Base-R heatmap ──────────────────────────────────────────────────────────
draw_heatmap <- function(h, title, CW = 90, CH = 20) {
  mat  <- h$mat_log; nums <- h$num_mat; cap <- h$cap
  nr   <- nrow(mat); nc <- ncol(mat)
  col_pal <- colorRampPalette(c("#4575B4","#F7F7F7","#D73027"))(100)
  breaks  <- seq(-cap, cap, length.out = 101)
  cell_col <- function(v) {
    v <- max(breaks[1], min(breaks[length(breaks)], v))
    col_pal[findInterval(v, breaks, rightmost.closed = TRUE)]
  }
  row_labels <- rownames(mat); col_labels <- colnames(mat)
  col_label_h <- max(nchar(col_labels)) * CW * 0.055 + CW * 0.5
  top_m    <- CH * 1.5
  bot_m    <- col_label_h
  left_m   <- 8
  right_m  <- max(nchar(row_labels)) * CW * 0.085 + CW * 0.5
  legend_w <- CW * 1.8
  total_w  <- left_m + nc * CW + right_m + legend_w
  total_h  <- top_m  + nr * CH + bot_m
  par(mar = c(0,0,0,0), xaxs = "i", yaxs = "i")
  plot.new()
  plot.window(xlim = c(0, total_w), ylim = c(0, total_h))
  
  for (i in seq_len(nr)) {
    for (j in seq_len(nc)) {
      x0 <- left_m + (j-1)*CW; x1 <- x0 + CW
      y0 <- bot_m  + (nr-i)*CH; y1 <- y0 + CH
      rect(x0, y0, x1, y1, col = cell_col(mat[i,j]), border = "white", lwd = 0.5)
      text((x0+x1)/2, (y0+y1)/2, nums[i,j],
           cex = max(0.3, min(0.7, CH/28 * 0.65)), col = "black")
    }
  }
  
  for (j in seq_len(nc)) {
    x <- left_m + (j - 0.5) * CW
    text(x, bot_m - CH * 0.1, col_labels[j], srt = 45, adj = c(1, 0.5),
         cex = max(0.5, min(0.85, CW/100)), xpd = TRUE)
  }
  
  row_x <- left_m + nc * CW + CW * 0.3
  for (i in seq_len(nr)) {
    y <- bot_m + (nr - i + 0.5) * CH
    text(row_x, y, row_labels[i], adj = c(0, 0.5),
         cex = max(0.4, min(0.72, CH/22)), xpd = TRUE)
  }
  # title
  text(left_m + nc * CW / 2, bot_m + nr * CH + CH * 0.7,
       title, font = 2, cex = max(0.7, min(1.0, CW/90)), xpd = TRUE)
}

heatmap_canvas <- function(h, CW = 90, CH = 20) {
  nr <- nrow(h$mat_log); nc <- ncol(h$mat_log)
  rl <- max(nchar(rownames(h$mat_log)))
  list(w = ceiling(8 + nc*CW + rl*CW*0.085 + CW*0.5 + CW*1.8),
       h = ceiling(CH*1.5 + nr*CH + CW*0.85))
}

heatmap_cw <- function(nc) 60L
heatmap_ch <- function(nr) 40L

heatmap_save <- function(h, title, file) {
  CW <- 30; CH <- 20L
  cv <- heatmap_canvas(h, CW, CH)
  cairo_pdf(file, width=cv$w/72, height=cv$h/72)
  draw_heatmap(h, title, CW, CH)
  dev.off()
}

server <- function(input, output, session) {
  
  custom_clocks <- reactiveVal(list())
  active_ewas   <- reactiveVal(EWAS_SOURCES[["all"]])
  
  observeEvent(input$ewas_source, {
    req(input$ewas_source)
    active_ewas(EWAS_SOURCES[[input$ewas_source]])
  })
  
  clocks_all_selected <- reactiveVal(TRUE)
  observeEvent(input$toggle_all_clocks, {
    if (clocks_all_selected()) {
      updateCheckboxGroupInput(session, "clock_choice",    selected = character(0))
      updateCheckboxGroupInput(session, "clock_choice_pc", selected = character(0))
      updateActionButton(session, "toggle_all_clocks", label = "Pasirinkti visus")
      clocks_all_selected(FALSE)
    } else {
      updateCheckboxGroupInput(session, "clock_choice",    selected = names(CLOCKS))
      updateCheckboxGroupInput(session, "clock_choice_pc", selected = names(CLOCKS_PC))
      updateActionButton(session, "toggle_all_clocks", label = "Atžymėti visus")
      clocks_all_selected(TRUE)
    }
  })
  
  observeEvent(input$merge_ewas_btn, {
    req(input$custom_ewas_file)
    ext <- tools::file_ext(input$custom_ewas_file$name)
    df  <- tryCatch(
      if (ext == "xlsx") read.xlsx(input$custom_ewas_file$datapath)
      else               read.csv(input$custom_ewas_file$datapath),
      error = function(e) NULL
    )
    if (is.null(df)) { showNotification("Nepavyko įkelti failo", type="error"); return() }
    missing <- setdiff(c("cpg","trait","pmid","beta","sample_size"), names(df))
    if (length(missing) > 0) {
      showNotification(paste("Trūksta stulpelių:", paste(missing, collapse=", ")), type="error"); return()
    }
    current <- active_ewas()
    merged  <- rbind(current, as.data.frame(df))
    active_ewas(merged)
    showNotification(paste("Apjungta:", nrow(current), "+", nrow(df), "=", nrow(merged), "eilučių"), type="message")
  })
  
  traits_selected <- reactiveVal(FALSE)
  
  observeEvent(input$toggle_traits, {
    if (traits_selected()) {
      updateSelectizeInput(session, "selected_traits", selected = character(0))
      updateActionButton(session, "toggle_traits", label = "Pasirinkti visus veiksnius")
      traits_selected(FALSE)
    } else {
      updateSelectizeInput(session, "selected_traits", selected = all_traits)
      updateActionButton(session, "toggle_traits", label = "Atžymėti visus veiksnius")
      traits_selected(TRUE)
    }
  })
  
  observeEvent(input$add_clock_btn, {
    req(input$custom_clock_file, nchar(trimws(input$custom_clock_name)) > 0)
    ext <- tools::file_ext(input$custom_clock_file$name)
    df  <- tryCatch(
      if (ext == "xlsx") read.xlsx(input$custom_clock_file$datapath)
      else               read.csv(input$custom_clock_file$datapath),
      error = function(e) NULL
    )
    if (is.null(df) || !all(c("cpg","coef") %in% names(df))) {
      showNotification("Failas turi turėti 'cpg' ir 'coef' stulpelius", type="error"); return()
    }
    clock_id   <- gsub(" ", "_", tolower(trimws(input$custom_clock_name)))
    clocks_now <- custom_clocks()
    clocks_now[[clock_id]] <- as.data.frame(df)
    custom_clocks(clocks_now)
    choices_now <- setNames(names(clocks_now), gsub("_"," ", tools::toTitleCase(names(clocks_now))))
    updateCheckboxGroupInput(session, "clock_choice_custom", choices=choices_now, selected=names(clocks_now))
    showNotification(paste("Laikrodis", input$custom_clock_name, "pridėtas"), type="message")
  })
  
  observeEvent(input$add_ewas_btn, {
    req(input$custom_ewas_file)
    ext <- tools::file_ext(input$custom_ewas_file$name)
    df  <- tryCatch(
      if (ext == "xlsx") read.xlsx(input$custom_ewas_file$datapath)
      else               read.csv(input$custom_ewas_file$datapath),
      error = function(e) NULL
    )
    if (is.null(df)) { showNotification("Nepavyko įkelti failo", type="error"); return() }
    missing <- setdiff(c("cpg","trait","pmid","beta","sample_size"), names(df))
    if (length(missing) > 0) {
      showNotification(paste("Trūksta stulpelių:", paste(missing, collapse=", ")), type="error"); return()
    }
    active_ewas(as.data.frame(df))
    showNotification("EWAS duomenys įkelti", type="message")
  })
  
  observeEvent(input$reset_ewas_btn, {
    active_ewas(EWAS_SOURCES[[input$ewas_source]])
    showNotification("Grąžinti originalūs EWAS duomenys", type="message")
  })
  
  results <- eventReactive(input$run_btn, {
    clock_choice <- c(input$clock_choice, input$clock_choice_pc, input$clock_choice_custom)
    req(length(clock_choice) > 0)
    traits <- if (length(input$selected_traits) > 0) input$selected_traits else NULL
    all_clocks_combined <- c(CLOCKS, CLOCKS_PC, custom_clocks())
    withProgress(message = "Skaičiuojama...", value = 0, {
      res_list <- lapply(seq_along(clock_choice), function(i) {
        clock_name <- clock_choice[i]
        incProgress(1/length(clock_choice), detail = clock_name)
        mult <- if (clock_name %in% names(CLOCK_MULTIPLIER)) CLOCK_MULTIPLIER[[clock_name]] else NULL
        
        # filter by sample size
        ewas_filtered <- active_ewas()
        ewas_filtered <- ewas_filtered[ewas_filtered$sample_size >= 200, ]
        
        if (clock_name %in% colnames(JACCARD_WHITELIST)) {
          keep <- JACCARD_WHITELIST[JACCARD_WHITELIST[[clock_name]] == TRUE,
                                    c("trait", "pmid")]
          ewas_filtered <- ewas_filtered[
            paste(ewas_filtered$trait, as.integer(ewas_filtered$pmid)) %in%
              paste(keep$trait,          as.integer(keep$pmid)), ]
        }
        
        if (nrow(ewas_filtered) == 0) return(list(error = TRUE))
        
        res <- if (clock_name %in% c("epitoc","epitoc2","miage")) {
          run_analysis_mean(all_clocks_combined[[clock_name]], ewas_filtered, traits)
        } else {
          run_analysis(all_clocks_combined[[clock_name]], ewas_filtered, traits, mult)
        }
        if (!"error" %in% names(res)) res$clock <- clock_name
        res
      })
    })
    do.call(rbind, res_list[!sapply(res_list, function(x) "error" %in% names(x))])
  })
  
  output$results_tbl <- renderDT({
    req(results())
    df <- results()
    df$score <- round(df$score, 6)
    datatable(df, filter="top", rownames=FALSE, selection="multiple",
              options=list(pageLength=20, scrollX=TRUE, autoWidth=TRUE,
                           columnDefs=list(list(width="200px", targets=0),
                                           list(width="100px", targets=11),
                                           list(width="120px", targets=length(names(df))-1)))) |>
      formatStyle("score", color=styleInterval(0, c("#C0392B","#2471A3")), fontWeight="bold")
  })
  
  jaccard_results <- eventReactive(input$run_btn, {
    clock_choice        <- c(input$clock_choice, input$clock_choice_pc, input$clock_choice_custom)
    req(length(clock_choice) > 0)
    all_clocks_combined <- c(CLOCKS, CLOCKS_PC, custom_clocks())
    full_ewas <- EWAS_FULL[[input$ewas_source]]
    
    ewas_filtered <- active_ewas()
    if (length(input$selected_traits) > 0)
      ewas_filtered <- ewas_filtered[ewas_filtered$trait %in% input$selected_traits, ]
    
    groups <- split(ewas_filtered, list(ewas_filtered$trait, ewas_filtered$pmid), drop=TRUE)
    
    pc_clocks    <- intersect(clock_choice, names(CLOCKS_PC))
    nonpc_clocks <- setdiff(clock_choice, names(CLOCKS_PC))
    
    do.call(rbind, lapply(groups, function(study) {
      ewas_cpgs <- unique(study$cpg)
      raw       <- full_ewas[full_ewas$trait == study$trait[1] & full_ewas$pmid == study$pmid[1], ]
      n_ewas    <- length(unique(raw$cpg))
      if (n_ewas == 0) n_ewas <- length(ewas_cpgs)
      
      rows <- do.call(rbind, lapply(nonpc_clocks, function(clock_name) {
        clock_cpgs   <- unique(all_clocks_combined[[clock_name]]$cpg)
        intersection <- length(intersect(ewas_cpgs, clock_cpgs))
        union        <- length(union(unique(raw$cpg), clock_cpgs))
        data.frame(trait=study$trait[1], pmid=as.character(study$pmid[1]),
                   clock=clock_name, jaccard=round(intersection/union, 6))
      }))
      
      if (length(pc_clocks) > 0) {
        pc_jaccards <- sapply(pc_clocks, function(clock_name) {
          clock_cpgs   <- unique(all_clocks_combined[[clock_name]]$cpg)
          intersection <- length(intersect(ewas_cpgs, clock_cpgs))
          union        <- length(union(unique(raw$cpg), clock_cpgs))
          intersection / union
        })
        rows <- rbind(rows, data.frame(
          trait   = study$trait[1],
          pmid    = as.character(study$pmid[1]),
          clock   = "PC clocks",
          jaccard = round(mean(pc_jaccards), 6)
        ))
      }
      rows
    }))
  })
  
  output$jaccard_plot <- renderPlot({
    req(jaccard_results())
    df <- jaccard_results()
    df <- df[df$jaccard > 0, ]
    if (nrow(df) == 0) return(NULL)
    df$trait_pmid <- paste0(df$trait, " [", df$pmid, "]")
    studies <- sort(unique(df$trait_pmid))
    clocks  <- unique(df$clock)
    n_s     <- length(studies)
    n_c     <- length(clocks)
    df$x    <- match(df$clock,      clocks)
    df$y    <- match(df$trait_pmid, studies)
    max_j   <- max(df$jaccard, na.rm=TRUE)
    max_cs  <- 3.5
    right_margin <- max(12, ceiling(max(nchar(studies)) * 0.42))
    par(mar=c(8, 2, 3, right_margin), bg="white")
    plot(NA, xlim=c(0.5, n_c+0.5), ylim=c(0.5, n_s+0.5), xlab="", ylab="", axes=FALSE)
    abline(h=seq_len(n_s), col="#EEEEEE", lwd=0.8)
    abline(v=seq_len(n_c), col="#EEEEEE", lwd=0.8)
    symbols(df$x, df$y, circles=sqrt(df$jaccard/max_j)*max_cs,
            inches=max_cs/10, add=TRUE, bg="#4575B488", fg="#4575B4")
    axis(1, at=seq_len(n_c), labels=clocks, las=2, cex.axis=0.9, tick=FALSE)
    axis(4, at=seq_len(n_s), labels=studies, las=2, cex.axis=0.75, tick=FALSE, hadj=0)
    mtext("Jaccard indeksas (EWAS × laikrodis)", side=3, line=0.5, font=2, cex=1.0)
    box(col="gray60")
  }, height=function() {
    df <- jaccard_results(); if (is.null(df)) return(700)
    max(500, length(unique(paste(df$trait, df$pmid))) * 18 + 150)
  }, width=function() {
    df <- jaccard_results(); if (is.null(df)) return(900)
    right_m <- max(12, ceiling(max(nchar(paste0(unique(df$trait)," [",unique(df$pmid),"]")))*0.42))
    max(600, length(unique(df$clock)) * 80 + right_m * 8)
  }, res=120)
  
  output$dl_jaccard <- downloadHandler(
    filename = "jaccard.pdf",
    content  = function(file) {
      df <- jaccard_results()
      df <- df[df$jaccard > 0, ]
      df$trait_pmid <- paste0(df$trait, " [", df$pmid, "]")
      studies <- sort(unique(df$trait_pmid))
      clocks  <- unique(df$clock)
      n_s <- length(studies); n_c <- length(clocks)
      df$x <- match(df$clock, clocks); df$y <- match(df$trait_pmid, studies)
      max_j <- max(df$jaccard, na.rm=TRUE); max_cs <- 3.5
      right_margin <- max(12, ceiling(max(nchar(studies)) * 0.42))
      cairo_pdf(file, width=max(8, n_c*0.4+right_margin*0.3+2), height=max(8, n_s*0.25+3))
      par(mar=c(8, 2, 3, right_margin), bg="white")
      plot(NA, xlim=c(0.5, n_c+0.5), ylim=c(0.5, n_s+0.5), xlab="", ylab="", axes=FALSE)
      abline(h=seq_len(n_s), col="#EEEEEE", lwd=0.8)
      abline(v=seq_len(n_c), col="#EEEEEE", lwd=0.8)
      symbols(df$x, df$y, circles=sqrt(df$jaccard/max_j)*max_cs,
              inches=max_cs/10, add=TRUE, bg="#4575B488", fg="#4575B4")
      axis(1, at=seq_len(n_c), labels=clocks, las=2, cex.axis=0.9, tick=FALSE)
      axis(4, at=seq_len(n_s), labels=studies, las=2, cex.axis=0.95, tick=FALSE, hadj=0)
      mtext("Jaccard indeksas", side=3, line=0.5, font=2, cex=1.0)
      box(col="gray60")
      dev.off()
    }
  )
  
  output$heatmap_plot <- renderPlot({
    req(results())
    df <- results()
    h  <- make_heatmap(df, "Age shift by trait and clock", "#F7F7F7")
    if (is.null(h)) return(NULL)
    CW <- heatmap_cw(ncol(h$mat_log)); CH <- heatmap_ch(1L)
    draw_heatmap(h, "Age shift by trait and clock", CW, CH)
  }, height=function() {
    h <- make_heatmap(results(), "", ""); if (is.null(h)) return(700)
    CW <- heatmap_cw(ncol(h$mat_log)); CH <- heatmap_ch(1L)
    heatmap_canvas(h, CW, CH)$h
  }, width=function() {
    h <- make_heatmap(results(), "", ""); if (is.null(h)) return(900)
    CW <- heatmap_cw(ncol(h$mat_log)); CH <- heatmap_ch(1L)
    heatmap_canvas(h, CW, CH)$w
  }, res=120)
  
  render_heatmap_category <- function(category_name) {
    renderPlot({
      req(results())
      df <- results()[results()$trait %in% TRAIT_GROUPS[[category_name]], ]
      if (nrow(df) == 0) return(NULL)
      h <- make_heatmap(df, category_name, "#F7F7F7")
      if (is.null(h)) return(NULL)
      CW <- heatmap_cw(ncol(h$mat_log)); CH <- heatmap_ch(1L)
      draw_heatmap(h, category_name, CW, CH)
    }, height=function() {
      df <- results()[results()$trait %in% TRAIT_GROUPS[[category_name]], ]
      h  <- make_heatmap(df, "", ""); if (is.null(h)) return(400)
      CW <- heatmap_cw(ncol(h$mat_log)); CH <- heatmap_ch(1L)
      heatmap_canvas(h, CW, CH)$h
    }, width=function() {
      df <- results()[results()$trait %in% TRAIT_GROUPS[[category_name]], ]
      h  <- make_heatmap(df, "", ""); if (is.null(h)) return(600)
      CW <- heatmap_cw(ncol(h$mat_log)); CH <- heatmap_ch(1L)
      heatmap_canvas(h, CW, CH)$w
    }, res=120)
  }
  
  observe({
    req(results())
    df <- results()
    lapply(names(TRAIT_GROUPS), function(grp) {
      tab_id <- switch(grp,
                       "Senėjimas"                           = "Senėjimas",
                       "Su motina susiję veiksniai"          = "Su motina susij\u0119 veiksniai",
                       "Svoris / nutukimas"                  = "Svoris / nutukimas",
                       "Medžiagų apykaita"                   = "Med\u017eiag\u0173 apykaita",
                       "Širdis / kraujagyslės"               = "\u0160irdis / kraujagysl\u0117s",
                       "Imuniniai / uždegiminiai"            = "Imuniniai / u\u017edegiminiai",
                       "Neurologiniai / psichiatriniai"      = "Neurologiniai / psichiatriniai",
                       "Infekcijos"                          = "Infekcijos",
                       "Rūkymo poveikiai"                    = "R\u016bkymo poveikiai",
                       "Genetiniai / sindromai"              = "Genetiniai / sindromai",
                       "Socialiniai veiksniai"               = "Socialiniai veiksniai",
                       "Kita"                                = "Kita",
                       grp
      )
      has_data <- any(df$trait %in% TRAIT_GROUPS[[grp]])
      session$sendCustomMessage("setTabDisabled", list(tab=tab_id, disabled=!has_data))
    })
  })
  
  output$heatmap_plot_aging      <- render_heatmap_category("Senėjimas")
  output$heatmap_plot_maternal   <- render_heatmap_category("Su motina susiję veiksniai")
  output$heatmap_plot_weight     <- render_heatmap_category("Svoris / nutukimas")
  output$heatmap_plot_metabolism <- render_heatmap_category("Medžiagų apykaita")
  output$heatmap_plot_cardio     <- render_heatmap_category("Širdis / kraujagyslės")
  output$heatmap_plot_immune     <- render_heatmap_category("Imuniniai / uždegiminiai")
  output$heatmap_plot_neuro      <- render_heatmap_category("Neurologiniai / psichiatriniai")
  output$heatmap_plot_infect     <- render_heatmap_category("Infekcijos")
  output$heatmap_plot_smoking    <- render_heatmap_category("Rūkymo poveikiai")
  output$heatmap_plot_genetic    <- render_heatmap_category("Genetiniai / sindromai")
  output$heatmap_plot_social     <- render_heatmap_category("Socialiniai veiksniai")
  output$heatmap_plot_other      <- render_heatmap_category("Kita")
  
  # DENDROGRAM
  dendro_data <- reactive({
    req(results())
    df  <- results()
    agg <- aggregate(score ~ trait + pmid + clock, data=df, FUN=sum)
    agg$trait_pmid <- paste0(agg$trait, " [", agg$pmid, "]")
    mat <- reshape(agg[, c("trait_pmid","clock","score")],
                   idvar="trait_pmid", timevar="clock", direction="wide")
    rownames(mat) <- mat$trait_pmid; mat$trait_pmid <- NULL
    colnames(mat) <- sub("score\\.", "", colnames(mat))
    mat <- as.matrix(mat); mat[is.na(mat)] <- 0
    if (ncol(mat) < 2) return(NULL)
    mat_log <- sign(mat) * log(abs(mat) + 1)
    mat_log[!is.finite(mat_log)] <- 0
    cm <- tryCatch(cor(mat_log, use="pairwise.complete.obs"), error=function(e) NULL)
    if (is.null(cm)) return(NULL)
    cm[!is.finite(cm)] <- 0
    hc <- hclust(as.dist(1 - cm), method="complete")
    list(hc=hc, cm=cm)
  })
  
  color_dend_leaves <- function(dend, lcol) {
    dendrapply(dend, function(node) {
      if (is.leaf(node)) {
        lbl <- attr(node, "label")
        col <- if (!is.null(lbl) && lbl %in% names(lcol)) lcol[[lbl]] else "#555"
        attr(node, "nodePar") <- list(lab.col = col, pch = NA)
        attr(node, "edgePar") <- list(col = col, lwd = 1.8)
      }
      node
    })
  }
  
  CLOCK_FAM_COL <- c(
    epitoc="#cb181d", epitoc2="#cb181d", miage="#cb181d",
    adaptage="#6a51a3", causage="#6a51a3", damage="#6a51a3",
    hannum="#238b45", horvath="#238b45", intrinclock="#238b45",
    retroelementV1="#238b45", retroelementV2="#238b45", skinandblood="#238b45",
    pc_hannum="#238b45", pc_horvath="#238b45", pc_skinandblood="#238b45",
    icage="#d4a800", phenoage="#d4a800", pc_dnamtl="#d4a800", pc_grimage="#d4a800",
    pc_phenoage="#d4a800"
  )
  
  CLOCK_FAM_LEGEND <- list(
    labels = c("Ląstelių dalijimosi laikrodžiai",
               "Priežastiniai laikrodžiai",
               "Chronologinio amžiaus laikrodžiai",
               "Biologiniai laikrodžiai"),
    cols   = c("#cb181d","#6a51a3","#238b45","#d4a800")
  )
  
  draw_dendro <- function(d, cex_lbl = 0.85) {
    hc  <- d$hc; n <- length(hc$labels)
    bot <- max(nchar(hc$labels)) * cex_lbl * 0.55 + 1.5
    dend <- color_dend_leaves(as.dendrogram(hc), CLOCK_FAM_COL)
    par(mar = c(bot, 4.5, 3.5, 16), bg = "white")
    plot(dend, axes = TRUE,
         ylab = "Pearson koreliacijos atstumas (1 - r)",
         main = "Laikrodžių dendrograma", cex = cex_lbl)
    abline(h = 0, col = "grey85", lty = 2)
    legend("topright", inset = c(-0.30, 0), xpd = TRUE,
           legend = CLOCK_FAM_LEGEND$labels,
           col    = CLOCK_FAM_LEGEND$cols,
           lwd = 2.5, bty = "n", cex = 0.75, title = "Grupė", title.font = 2)
  }
  
  output$dendro_plot <- renderPlot({
    d <- dendro_data(); if (is.null(d)) return(NULL)
    draw_dendro(d)
  }, height = function() { 580 },
  width  = function() {
    d <- dendro_data(); if (is.null(d)) return(600)
    max(600, length(d$hc$labels) * 55 + 180)
  }, res=120)
  
  output$dl_dendro <- downloadHandler(
    filename = "dendrograma.pdf",
    content  = function(file) {
      d <- dendro_data()
      if (is.null(d)) { cairo_pdf(file); dev.off(); return() }
      cairo_pdf(file, width = max(7, length(d$hc$labels)*0.5+2), height = 7)
      draw_dendro(d)
      dev.off()
    }
  )
  
  # EWAS DENDROGRAM
  ewas_dendro_data <- reactive({
    req(results())
    df  <- results()
    agg <- aggregate(score ~ trait + pmid + clock, data=df, FUN=sum)
    agg$trait_pmid <- paste0(agg$trait, " [", agg$pmid, "]")
    mat <- reshape(agg[, c("trait_pmid","clock","score")],
                   idvar="trait_pmid", timevar="clock", direction="wide")
    rownames(mat) <- mat$trait_pmid; mat$trait_pmid <- NULL
    colnames(mat) <- sub("score\\.", "", colnames(mat))
    mat <- as.matrix(mat); mat[is.na(mat)] <- 0
    if (nrow(mat) < 2) return(NULL)
    mat_log <- sign(mat) * log(abs(mat) + 1)
    mat_log[!is.finite(mat_log)] <- 0
    cm <- tryCatch(cor(t(mat_log), use="pairwise.complete.obs"), error=function(e) NULL)
    if (is.null(cm)) return(NULL)
    cm[!is.finite(cm)] <- 0
    hc <- hclust(as.dist(1 - cm), method="complete")
    list(hc=hc)
  })
  
  TRAIT_GRP_COLS <- c("#cb181d","#f16913","#41ab5d","#2171b5","#6a51a3",
                      "#d94801","#238b45","#fb6a4a","#4292c6","#a1d99b","#969696", "black")
  
  draw_ewas_dendro <- function(d, cex_lbl = 0.55) {
    hc  <- d$hc; n <- length(hc$labels)
    grp_names  <- names(TRAIT_GROUPS)
    row_traits <- sub(" \\[.*\\]$", "", hc$labels)
    
    lcol <- setNames(rep("#999999", n), hc$labels)
    for (i in seq_along(grp_names))
      lcol[hc$labels[row_traits %in% TRAIT_GROUPS[[grp_names[i]]]]] <-
      TRAIT_GRP_COLS[((i-1) %% length(TRAIT_GRP_COLS)) + 1]
    
    phy <- as.phylo(hc)
    
    tip_cols <- lcol[phy$tip.label]
    
    par(mar = c(1, 1, 2, 1), bg = "white")
    plot(phy, type = "fan", show.tip.label = TRUE,
         tip.color = tip_cols,
         cex = cex_lbl-0.1,
         main = "EWAS studijų dendrograma",
         label.offset = 0.02)
    
    shown <- grp_names[sapply(grp_names, function(g) any(row_traits %in% TRAIT_GROUPS[[g]]))]
    legend("topleft", xpd = TRUE, inset = c(0, -0.03), 
           legend = shown,
           col = TRAIT_GRP_COLS[(match(shown, grp_names)-1) %% length(TRAIT_GRP_COLS) + 1],
           lwd = 2.5, bty = "o", bg = "white", box.col = "white", cex = 0.4, title = "Kategorija", title.font = 2)
  }
  
  output$ewas_dendro_plot <- renderPlot({
    d <- ewas_dendro_data(); if (is.null(d)) return(NULL)
    draw_ewas_dendro(d)
  }, height = function() { 1100 },
  width  = function() { 1100 }, res=150)
  
  output$dl_ewas_dendro <- downloadHandler(
    filename = "ewas_dendrograma.pdf",
    content  = function(file) {
      d <- ewas_dendro_data()
      if (is.null(d)) { cairo_pdf(file); dev.off(); return() }
      cairo_pdf(file, width = 14, height = 14)
      draw_ewas_dendro(d)
      dev.off()
    }
  )
  
  # DOT PLOT
  CAT_BAND_COLORS <- c(
    "#FFD6D6","#FFE8C2","#D6F0D6","#C2DCFF","#E8D6FF",
    "#FFD6C2","#C2FFE8","#FFB3B3","#C2D4FF","#D6FFD6","#E0E0E0"
  )
  
  # GRUPUOTAS DOT PLOT
  output$grouped_plot <- renderPlot({
    req(results())
    df  <- results()
    agg <- aggregate(score ~ trait + clock, data=df, FUN=sum)
    score_lim <- input$score_filter %||% 15
    agg <- agg[agg$score >= -score_lim & agg$score <= score_lim, ]
    if (nrow(agg) == 0) return(NULL)
    ordered_traits <- c(); spacing <- 2; current_y <- 0; trait_y <- c()
    cc <- custom_clocks()
    for (grp in names(TRAIT_GROUPS)) {
      grp_traits <- intersect(TRAIT_GROUPS[[grp]], unique(agg$trait))
      if (length(grp_traits) == 0) next
      for (t in rev(sort(grp_traits))) { current_y <- current_y + spacing; trait_y[t] <- current_y }
      ordered_traits <- c(ordered_traits, rev(sort(grp_traits)))
      current_y <- current_y + spacing
    }
    total_y      <- current_y
    traits_label <- ifelse(nchar(ordered_traits) > 50, paste0(substr(ordered_traits,1,47),"..."), ordered_traits)
    names(traits_label) <- ordered_traits
    all_colors <- if (length(cc) > 0) c(CLOCK_COLORS, setNames(rep("#888888",length(cc)),names(cc))) else CLOCK_COLORS
    agg$y         <- trait_y[agg$trait]
    agg$point_col <- all_colors[agg$clock]
    x_range     <- range(agg$score, na.rm=TRUE)
    x_lim       <- c(x_range[1]-diff(x_range)*0.05, x_range[2]+diff(x_range)*0.05)
    right_margin <- max(10, ceiling(max(nchar(traits_label))*0.45))
    par(mar=c(5, 3, 4, right_margin + 14), bg="white")
    plot(NA, xlim=x_lim, ylim=c(0, total_y+spacing), xlab="", ylab="", axes=FALSE)
    rect(par("usr")[1], par("usr")[3], par("usr")[2], par("usr")[4], col="white", border=NA)
    grp_counter <- 0; current_y <- 0
    for (grp in names(TRAIT_GROUPS)) {
      grp_traits <- intersect(TRAIT_GROUPS[[grp]], unique(agg$trait))
      if (length(grp_traits) == 0) next
      grp_counter <- grp_counter + 1
      grp_start   <- current_y
      grp_end     <- current_y + length(grp_traits)*spacing + spacing
      rect(par("usr")[1], grp_start, par("usr")[2], grp_end,
           col=if (grp_counter%%2==0) "#E8EEF4" else "#FFFFFF", border=NA)
      mtext(grp, side=4, at=(grp_start+grp_end)/2, las=2, cex=0.65, font=2,
            col="#444444", line=right_margin-1, xpd=TRUE)
      current_y <- grp_end
    }
    abline(h=trait_y, col="#DDDDDD", lwd=0.8)
    abline(v=0, col="black", lwd=0.8)
    points(agg$score, agg$y, col=agg$point_col, pch=16, cex=1.2)
    axis(1, at=pretty(x_lim,n=10), cex.axis=1.0, padj=0.3)
    axis(4, at=trait_y[ordered_traits], labels=traits_label[ordered_traits],
         las=2, cex.axis=0.85, tick=FALSE, hadj=0)
    box(col="gray60")
    mtext("Amžiaus skirtumas metais", side=1, line=3, cex=1.1)
    mtext("Veiksnių įtaka epigenetiniams laikrodžiams", side=3, line=1, font=2, cex=1.1)
    all_labels <- if (length(cc) > 0) c(CLOCK_LABELS, setNames(gsub("_"," ",tools::toTitleCase(names(cc))),names(cc))) else CLOCK_LABELS
    selected_clocks <- intersect(unique(agg$clock), names(all_colors))
    legend("topright", inset=c(-14/par("pin")[1], 0), xpd=TRUE,
           legend=all_labels[selected_clocks],
           col=all_colors[selected_clocks], pch=16, pt.cex=1.2, cex=0.7, bty="n",
           y.intersp=1.1, title="Laikrodis", title.font=2)
  }, height=function() {
    df <- results(); if (is.null(df)) return(700)
    max(600, length(unique(df$trait))*20+200)
  }, width=function() { 1300 }, res=120)
  
  # DOWNLOAD: CSV
  output$dl_btn <- downloadHandler(
    filename = "rezultatai.csv",
    content  = function(f) write.csv(results(), f, row.names=FALSE)
  )
  
  # DOWNLOAD: DOT PLOT
  output$dl_dot <- downloadHandler(
    filename = "dot_plot.pdf",
    content  = function(file) {
      df  <- results()
      agg <- aggregate(score ~ trait + clock, data=df, FUN=sum)
      score_lim <- input$score_filter %||% 15
      agg <- agg[agg$score >= -score_lim & agg$score <= score_lim, ]
      if (nrow(agg) == 0) { cairo_pdf(file); dev.off(); return() }
      traits       <- rev(sort(unique(agg$trait)))
      traits_label <- ifelse(nchar(traits) > 50, paste0(substr(traits,1,47),"..."), traits)
      n_traits     <- length(traits)
      spacing      <- 2
      trait_idx    <- match(agg$trait, traits) * spacing
      cc           <- custom_clocks()
      all_colors   <- if (length(cc) > 0) c(CLOCK_COLORS, setNames(rep("#888888",length(cc)),names(cc))) else CLOCK_COLORS
      point_cols   <- all_colors[agg$clock]
      x_range      <- range(agg$score, na.rm=TRUE)
      x_lim        <- c(x_range[1]-diff(x_range)*0.05, x_range[2]+diff(x_range)*0.05)
      right_margin <- max(10, ceiling(max(nchar(traits_label))*0.45))
      cairo_pdf(file, width=max(10, right_margin*0.3+10), height=max(8, n_traits*0.25+3))
      par(mar=c(5, 3, 4, right_margin + 14), bg="white")
      plot(NA, xlim=x_lim, ylim=c(0.5*spacing,(n_traits+0.5)*spacing), xlab="", ylab="", axes=FALSE)
      rect(par("usr")[1], par("usr")[3], par("usr")[2], par("usr")[4], col="white", border=NA)
      abline(h=seq_len(n_traits)*spacing, col="#CCCCCC", lwd=1)
      abline(v=0, col="black", lwd=0.8)
      points(agg$score, trait_idx, col=point_cols, pch=16, cex=1.2)
      axis(1, at=pretty(x_lim,n=10), cex.axis=1.0, padj=0.3)
      axis(2, at=seq_len(n_traits)*spacing, labels=traits_label, las=2, cex.axis=0.85, tick=FALSE, hadj=1)
      box(col="gray60")
      mtext("Amžiaus skirtumas metais", side=1, line=3, cex=1.1)
      mtext("Veiksnių įtaka epigenetiniams laikrodžiams", side=3, line=1, font=2, cex=1.2)
      all_labels <- if (length(cc) > 0) c(CLOCK_LABELS, setNames(gsub("_"," ",tools::toTitleCase(names(cc))),names(cc))) else CLOCK_LABELS
      selected_clocks <- intersect(unique(agg$clock), names(all_colors))
      legend("topright", inset=c(-14/par("pin")[1], 0), xpd=TRUE,
             legend=all_labels[selected_clocks],
             col=all_colors[selected_clocks], pch=16, pt.cex=1.2, cex=0.7, bty="n",
             y.intersp=1.1, title="Laikrodis", title.font=2)
      dev.off()
    }
  )
  
  # DOWNLOAD: HEATMAP
  output$dl_heatmap_active <- downloadHandler(
    filename = function() {
      cat <- input$heatmap_category
      if (is.null(cat) || cat == "Visi") "heatmap_visi.pdf"
      else paste0("heatmap_", gsub(" ", "_", cat), ".pdf")
    },
    content = function(file) {
      cat <- input$heatmap_category
      df  <- results()
      if (!is.null(cat) && cat != "Visi") {
        df <- df[df$trait %in% TRAIT_GROUPS[[cat]], ]
      }
      if (nrow(df) == 0) { cairo_pdf(file); dev.off(); return() }
      title <- if (is.null(cat)) "Visi" else cat
      h <- make_heatmap(df, title, "#F7F7F7")
      if (is.null(h)) { cairo_pdf(file); dev.off(); return() }
      heatmap_save(h, title, file)
    }
  )
}

shinyApp(ui = ui, server = server)