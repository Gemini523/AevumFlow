library(shiny)
library(DT)

# Serve www/ relative to this script file
local({
  script_dir <- tryCatch(
    dirname(rstudioapi::getSourceEditorContext()$path),
    error = function(e) getwd()
  )
  www_path <- file.path(script_dir, "www")
  if (dir.exists(www_path)) addResourcePath("www_aev", www_path)
})


ewas_preview <- readRDS("data/ewas_all.rds")
all_traits   <- sort(unique(ewas_preview$trait))

all_clocks <- c(
  "AdaptAge"="adaptage", "CauseAge"="causage", "DamAge"="damage",
  "Hannum"="hannum", "Horvath"="horvath", "Intrinclock"="intrinclock",
  "ICage"="icage", "PhenoAge"="phenoage",
  "RetroelementV1"="retroelementV1", "RetroelementV2"="retroelementV2",
  "SkinAndBlood"="skinandblood", "EpiToc"="epitoc",
  "EpiToc2"="epitoc2", "MiAge"="miage"
)
all_clocks_pc <- c(
  "PCDnamTL"="pc_dnamtl", "PCHannum"="pc_hannum", "PCHorvath"="pc_horvath",
  "PCPhenoAge"="pc_phenoage", "PCGrimAge"="pc_grimage", "PCSkinAndBlood"="pc_skinandblood"
)

aev_section <- function(id, title, ..., open = FALSE) {
  body_style <- if (!open) "display:none;" else ""
  tagList(
    tags$div(
      class        = if (open) "aev-sec-hdr aev-open" else "aev-sec-hdr",
      `data-id`    = id,
      tags$span(class = "aev-sec-title", title),
      tags$span(class = "aev-chevron", if (open) "\u25b4" else "\u25be")
    ),
    tags$div(id = id, class = "aev-sec-body", style = body_style, ...)
  )
}

plot_panel <- function(plot_id, dl_id = NULL, warning_id = NULL,
                       overflow = "visible", width = "auto") {
  tags$div(
    class = "aev-plot-wrap",
    if (!is.null(dl_id) || !is.null(warning_id))
      tags$div(class = "aev-plot-bar",
               if (!is.null(dl_id))
                 downloadButton(dl_id, "\u2193 PDF", class = "aev-dl-btn"),
               if (!is.null(warning_id)) uiOutput(warning_id)
      ),
    tags$div(style = paste0("overflow:", overflow, ";"),
             plotOutput(plot_id, height = "auto", width = width))
  )
}

js_code <- paste0(
  
  "$(document).on('click', '.aev-sec-hdr', function(){",
  "  var id = $(this).data('id');",
  "  $('#'+id).slideToggle(200);",
  "  $(this).toggleClass('aev-open');",
  "  $(this).find('.aev-chevron').text(",
  "    $(this).hasClass('aev-open') ? '\\u25b4' : '\\u25be');",
  "});",
  
  "Shiny.addCustomMessageHandler('setTabDisabled',function(msg){",
  "  var $a=$('a[data-value=\"'+msg.tab+'\"]');",
  "  if(msg.disabled){$a.parent().addClass('aev-tab-dim');$a.css({'color':'#bbb','pointer-events':'none'});}",
  "  else{$a.parent().removeClass('aev-tab-dim');$a.css({'color':'','pointer-events':''});}",
  "});"
)

ui <- fluidPage(
  tags$head(
    tags$style(HTML("@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');

:root {
  --blue:    #3b82f6;
  --blue-dk: #1d4ed8;
  --blue-lt: #eff6ff;
  --text:    #1e293b;
  --muted:   #64748b;
  --border:  #e2e8f0;
  --bg:      #f8fafc;
  --white:   #ffffff;
  --r:       7px;
}

* { box-sizing: border-box; }
body {
  font-family: 'Inter', system-ui, sans-serif;
  font-size: 14px;
  background: var(--bg);
  color: var(--text);
  margin: 0;
}

/* ── App header ── */
.aev-header {
  background: var(--white);
  border-bottom: 1px solid var(--border);
  padding: 11px 22px;
  display: flex;
  align-items: baseline;
  gap: 10px;
}
.aev-logo    { font-size: 1.1rem; font-weight: 700; color: var(--text); }
.aev-tagline { font-size: 0.8rem; color: var(--muted); }
.shiny-title-panel, h2.shiny-title-panel { display: none !important; }

/* ── Sidebar ── */
.aev-sidebar.well {
  background: var(--bg) !important;
  border: none !important;
  box-shadow: none !important;
  padding: 10px 6px !important;
}

/* ── Collapsible section header ── */
.aev-sec-hdr {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: var(--white);
  border: 1px solid var(--border);
  border-radius: var(--r);
  padding: 9px 13px;
  margin-bottom: 2px;
  cursor: pointer;
  user-select: none;
  transition: background 0.13s, border-color 0.13s;
}
.aev-sec-hdr:hover        { background: #f1f5f9; }
.aev-sec-hdr.aev-open     { background: var(--blue-lt); border-color: #bfdbfe;
                             border-bottom-left-radius: 0; border-bottom-right-radius: 0; }
.aev-sec-title {
  font-size: 0.9rem;
  font-weight: 700;
  letter-spacing: 0.03em;
  text-transform: uppercase;
  color: var(--muted);
}
.aev-sec-hdr.aev-open .aev-sec-title { color: var(--blue-dk); }
.aev-chevron { font-size: 0.7rem; color: #94a3b8; line-height: 1; }
.aev-sec-hdr.aev-open .aev-chevron   { color: var(--blue); }

/* ── Collapsible section body ── */
.aev-sec-body {
  background: var(--white);
  border: 1px solid #bfdbfe;
  border-top: none;
  border-radius: 0 0 var(--r) var(--r);
  padding: 10px 12px 12px;
  margin-bottom: 6px;
}

/* ── Column labels inside clocks ── */
.aev-col-label {
  font-size: 0.72rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--muted);
  margin-top: 24px;
  margin-bottom: 4px;
}

/* ── Checkboxes tighter ── */
.shiny-input-container .checkbox { margin: 0 !important; padding: 0 !important; }
.shiny-input-container .checkbox label {
  font-size: 0.83rem;
  line-height: 1.6;
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 1px 0;
}
.shiny-input-container .checkbox input[type=checkbox] {
  margin: 0 !important;
  position: relative !important;
  top: 0 !important;
  flex-shrink: 0;
}
.shiny-input-container > label { font-size: 0.78rem; font-weight: 700; color: var(--muted); margin-bottom: 12px; margin-top: 8px; display: block; text-transform: uppercase; letter-spacing: 0.04em; }

/* ── Small buttons ── */
.aev-btn-sm {
  background: var(--white) !important;
  border: 1px solid var(--border) !important;
  border-radius: 5px !important;
  padding: 4px 11px !important;
  font-size: 0.76rem !important;
  font-weight: 500 !important;
  color: var(--muted) !important;
  cursor: pointer;
  transition: all 0.12s;
  box-shadow: none !important;
}
.aev-btn-sm:hover { background: #f1f5f9 !important; border-color: #94a3b8 !important; color: var(--text) !important; }

.aev-btn-row { display: flex; gap: 5px; flex-wrap: wrap; margin-top: 6px; }

/* ── Run row ── */
.aev-run-row { display: flex; gap: 8px; align-items: stretch; }
.aev-run-btn {
  flex: 1;
  background: var(--blue) !important;
  color: #fff !important;
  border: none !important;
  border-radius: var(--r) !important;
  padding: 9px 0 !important;
  font-size: 0.88rem !important;
  font-weight: 600 !important;
  cursor: pointer;
  letter-spacing: 0.02em;
  transition: background 0.14s, box-shadow 0.14s, transform 0.1s;
  box-shadow: none !important;
}
.aev-run-btn:hover { background: var(--blue-dk) !important; box-shadow: 0 4px 14px rgba(59,130,246,.35) !important; transform: translateY(-1px); }
.aev-run-btn:active { transform: none; }

.aev-csv-btn {
  background: var(--white) !important;
  color: var(--blue) !important;
  border: 1.5px solid var(--blue) !important;
  border-radius: var(--r) !important;
  padding: 8px 12px !important;
  font-size: 0.82rem !important;
  font-weight: 600 !important;
  white-space: nowrap;
  cursor: pointer;
  text-decoration: none !important;
  transition: background 0.12s;
}
.aev-csv-btn:hover { background: var(--blue-lt) !important; }

/* ── Main tab bar ── */
.nav.nav-tabs {
  display: flex !important;
  flex-wrap: nowrap !important;
  overflow-x: auto !important;
  overflow-y: hidden !important;
  scrollbar-width: none !important;
  border-bottom: 1px solid var(--border) !important;
  background: var(--white);
  padding: 0 4px;
  gap: 0;
}
.nav.nav-tabs::-webkit-scrollbar { display: none; }
.nav.nav-tabs > li { flex-shrink: 0 !important; }
.nav.nav-tabs > li > a {
  border: none !important;
  border-bottom: 2px solid transparent !important;
  border-radius: 0 !important;
  padding: 10px 15px 8px !important;
  font-size: 0.85rem !important;
  font-weight: 500 !important;
  color: var(--muted) !important;
  background: transparent !important;
  white-space: nowrap;
  transition: color 0.13s;
  margin-bottom: -1px;
}
.nav.nav-tabs > li > a:hover { color: var(--text) !important; background: #f8fafc !important; }
.nav.nav-tabs > li.active > a {
  color: var(--blue) !important;
  font-weight: 700 !important;
  border-bottom: 2px solid var(--blue) !important;
  background: transparent !important;
}

/* ── Inner tabs (heatmap categories, dendrograms) ── */
.aev-inner-tabs .nav.nav-tabs { background: #fafbfc; }
.aev-inner-tabs .nav.nav-tabs > li > a {
  font-size: 0.78rem !important;
  padding: 6px 11px 5px !important;
  color: #94a3b8 !important;
}
.aev-inner-tabs .nav.nav-tabs > li.active > a {
  color: var(--blue) !important;
  border-bottom: 2px solid var(--blue) !important;
}

/* ── Plot panel ── */
.aev-plot-wrap { position: relative; }
.aev-plot-bar {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 6px 4px;
}
.aev-dl-btn {
  display: inline-flex !important;
  align-items: center;
  gap: 4px;
  background: var(--white) !important;
  border: 1px solid var(--border) !important;
  border-radius: 5px !important;
  padding: 4px 12px !important;
  font-size: 0.77rem !important;
  font-weight: 500 !important;
  color: var(--muted) !important;
  text-decoration: none !important;
  transition: all 0.12s;
}
.aev-dl-btn:hover { background: #f1f5f9 !important; border-color: #94a3b8 !important; color: var(--text) !important; }

/* ── Disabled heatmap category tabs ── */
.aev-tab-dim > a { color: #cbd5e0 !important; pointer-events: none !important; cursor: default !important; }


/* ── Radio: kill Bootstrap indent ── */
.shiny-input-container .radio,
.shiny-input-container .radio-inline {
  margin: 0 !important;
  padding: 0 !important;
}
.shiny-input-container .radio label,
.shiny-input-container .radio-inline label {
  padding-left: 0 !important;
  margin-left: 0 !important;
  display: flex !important;
  align-items: center !important;
  gap: 6px !important;
  font-size: 0.83rem;
  line-height: 1.6;
  min-height: 0 !important;
}
.shiny-input-container .radio input[type=radio],
.shiny-input-container .radio-inline input[type=radio] {
  float: none !important;
  margin: 0 !important;
  margin-left: 0 !important;
  position: static !important;
  top: auto !important;
  flex-shrink: 0;
}

/* ── Slider ── */
.irs--shiny .irs-bar { background: var(--blue); border-color: var(--blue); }
.irs--shiny .irs-handle { border-color: var(--blue); }

/* ── Selectize (Veiksniai dropdown) ── */
.selectize-input { font-size: 0.83rem !important; min-height: 30px !important; }
.selectize-dropdown { font-size: 0.83rem !important; }
.selectize-input .item { font-size: 0.81rem !important; }

/* ── DT table ── */
.dataTables_wrapper { font-size: 0.88rem; }

.aev-sec-body .shiny-input-container + .shiny-input-container { margin-top: 10px; }
")),
    tags$link(rel = "stylesheet", href = "style.css"),
    tags$link(rel = "stylesheet", href = "style.css"),
    tags$script(HTML(js_code))
  ),
  
  tags$div(class = "aev-header",
           tags$span(class = "aev-logo", "AevumFlow"),
           tags$span(class = "aev-tagline", "Clock \u00d7 EWAS")
  ),
  
  sidebarLayout(
    sidebarPanel(width = 3, class = "aev-sidebar",
                 
                 # ── Clocks (open by default) ────────────────────────────────────────
                 aev_section("sec_clocks", "Laikrod\u017eiai", open = TRUE,
                             checkboxGroupInput("clock_choice", "Standartiniai:",
                                                choices = all_clocks, selected = all_clocks),
                             checkboxGroupInput("clock_choice_pc", "PC laikrod\u017eiai:",
                                                choices = all_clocks_pc, selected = all_clocks_pc),
                             checkboxGroupInput("clock_choice_custom", "Papildomi:", choices = NULL),
                             actionButton("toggle_all_clocks", "At\u017eim\u0117ti visus", class = "aev-btn-sm")
                 ),
                 
                 # ── EWAS source ─────────────────────────────────────────────────────
                 aev_section("sec_ewas_src", "EWAS \u0161altinis", open = FALSE,
                             radioButtons("ewas_source", NULL,
                                          choices  = c("Atlas"="atlas","Catalog"="catalog","Custom"="custom","Visi"="all"),
                                          selected = "all", inline = FALSE)
                 ),
                 
                 # ── Traits ──────────────────────────────────────────────────────────
                 aev_section("sec_traits", "Veiksniai", open = FALSE,
                             selectizeInput("selected_traits", NULL, choices = all_traits,
                                            multiple = TRUE, options = list(placeholder = "Visi veiksniai \u2014 be filtro")),
                             actionButton("toggle_traits", "Pasirinkti visus", class = "aev-btn-sm")
                 ),
                 
                 # ── Dot plot filter ─────────────────────────────────────────────────
                 aev_section("sec_filter", "Dot plot filtras", open = FALSE,
                             sliderInput("score_filter", "Score riba (\u00b1):", min=1, max=100, value=15, step=1)
                 ),
                 
                 # ── Upload clock ────────────────────────────────────────────────────
                 aev_section("sec_upload_clock", "\u012ekelti laikrod\u012f", open = FALSE,
                             textInput("custom_clock_name", "Pavadinimas:"),
                             fileInput("custom_clock_file", "Failas (cpg, coef):", accept = c(".csv",".xlsx")),
                             actionButton("add_clock_btn", "Prid\u0117ti laikrod\u012f", class = "aev-btn-sm")
                 ),
                 
                 # ── Upload EWAS ─────────────────────────────────────────────────────
                 aev_section("sec_upload_ewas", "\u012ekelti EWAS", open = FALSE,
                             fileInput("custom_ewas_file", "Failas (cpg, trait, pmid, beta, sample_size):",
                                       accept = c(".csv",".xlsx")),
                             tags$div(class = "aev-btn-row",
                                      actionButton("add_ewas_btn",   "Tik \u0161ie",  class = "aev-btn-sm"),
                                      actionButton("merge_ewas_btn", "Sujungti",      class = "aev-btn-sm"),
                                      actionButton("reset_ewas_btn", "Atstatyti",     class = "aev-btn-sm")
                             )
                 ),
                 
                 tags$hr(style = "margin: 12px 0; border-color: #e2e8f0;"),
                 
                 # ── Run & download ──────────────────────────────────────────────────
                 tags$div(class = "aev-run-row",
                          actionButton("run_btn", "\u25b6 Skai\u010diuoti", class = "aev-run-btn"),
                          downloadButton("dl_btn", "\u2193 CSV", class = "aev-csv-btn")
                 )
    ),
    
    mainPanel(width = 9,
              tabsetPanel(id = "main_tabs",
                          
                          tabPanel("Rezultatai",
                                   tags$div(style = "padding:12px 4px;", DTOutput("results_tbl"))
                          ),
                          
                          tabPanel("Heatmap",
                                   tags$div(class = "aev-plot-bar",
                                            downloadButton("dl_heatmap_active", "\u2193 PDF", class = "aev-dl-btn")
                                   ),
                                   tags$div(class = "aev-inner-tabs",
                                            tabsetPanel(id = "heatmap_category", selected = "Visi",
                                                        tabPanel("Visi",                                    plot_panel("heatmap_plot")),
                                                        tabPanel("Sen\u0117jimas",                          plot_panel("heatmap_plot_aging")),
                                                        tabPanel("Su motina susij\u0119 veiksniai",          plot_panel("heatmap_plot_maternal")),
                                                        tabPanel("Svoris / nutukimas",                      plot_panel("heatmap_plot_weight")),
                                                        tabPanel("Med\u017eiag\u0173 apykaita",             plot_panel("heatmap_plot_metabolism")),
                                                        tabPanel("\u0160irdis / kraujagysl\u0117s",         plot_panel("heatmap_plot_cardio")),
                                                        tabPanel("Imuniniai / u\u017edegiminiai",           plot_panel("heatmap_plot_immune")),
                                                        tabPanel("Neurologiniai / psichiatriniai",          plot_panel("heatmap_plot_neuro")),
                                                        tabPanel("Infekcijos",                              plot_panel("heatmap_plot_infect")),
                                                        tabPanel("R\u016bkymo poveikiai",                   plot_panel("heatmap_plot_smoking")),
                                                        tabPanel("Genetiniai / sindromai",                  plot_panel("heatmap_plot_genetic")),
                                                        tabPanel("Socialiniai veiksniai",                   plot_panel("heatmap_plot_social")),
                                                        tabPanel("Kita",                                    plot_panel("heatmap_plot_other"))
                                            )
                                   )
                          ),
                          
                          tabPanel("Grupuotas",
                                   tags$div(style="overflow-x:auto;",
                                            plotOutput("grouped_plot", height="auto", width="1300px"))
                          ),
                          
                          tabPanel("Jaccard",
                                   plot_panel("jaccard_plot", dl_id="dl_jaccard", overflow="auto")
                          ),
                          
                          tabPanel("Dendrograma",
                                   tags$div(class = "aev-inner-tabs",
                                            tabsetPanel(
                                              tabPanel("Laikrod\u017eiai", plot_panel("dendro_plot",      dl_id="dl_dendro")),
                                              tabPanel("EWAS",            plot_panel("ewas_dendro_plot",  dl_id="dl_ewas_dendro"))
                                            )
                                   )
                          )
              )
    )
  )
)