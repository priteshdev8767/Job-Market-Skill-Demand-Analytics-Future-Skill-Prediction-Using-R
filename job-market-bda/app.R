# ============================================================
# app.R — R Shiny Analytics Dashboard
# Job Market Skill Demand Analytics & Future Skill Prediction
# B.E. Computer Engineering — Big Data Analytics Mini Project
# ============================================================
# Run with:  shiny::runApp()
# ============================================================

# ---- Load Required Libraries ----
suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
  library(DT)
  library(tidyverse)
  library(lubridate)
  library(plotly)
  library(scales)
  library(forecast)
  library(RColorBrewer)
})

# ---- Source Modules ----
source("R/data_cleaning.R",     local = TRUE)
source("R/skill_extraction.R",  local = TRUE)
source("R/analysis.R",          local = TRUE)
source("R/forecasting.R",       local = TRUE)

# ============================================================
# DATA PIPELINE INITIALIZATION
# ============================================================

raw_file       <- file.path("data", "raw", "job_postings.csv")
processed_file <- file.path("data", "processed", "jobs_cleaned.csv")

# Ensure dataset exists
if (!file.exists(raw_file)) {
  message("Generating job postings dataset...")
  source("data/raw/generate_dataset.R", local = TRUE)
}

# Ensure cleaned data exists
if (!file.exists(processed_file)) {
  message("Preprocessing job postings...")
  jobs_cleaned <- clean_job_data(raw_file)
  save_processed_data(jobs_cleaned)
} else {
  jobs_cleaned <- read_csv(processed_file, show_col_types = FALSE) %>%
    mutate(posted_date = as.Date(posted_date))
}

# Core Data Objects
skills_long   <- build_skills_long(jobs_cleaned)
total_jobs    <- nrow(jobs_cleaned)
top_skills_df <- get_top_skills(skills_long, total_jobs, top_n = 20)
roles_summary <- get_all_roles_summary(skills_long)
trend_data    <- get_skill_trends(skills_long, jobs_cleaned)
growth_data   <- get_skill_growth(trend_data)
classified    <- classify_skills(growth_data)
combo_data    <- get_skill_combinations(jobs_cleaned, top_n = 20)

# Forecast top 15 skills
forecast_skills  <- top_skills_df$skill[1:min(15, nrow(top_skills_df))]
forecast_results <- forecast_all_skills(trend_data, forecast_skills, h = 3)
forecast_summary <- get_forecast_summary(forecast_results, growth_data)
kpis             <- get_dashboard_kpis(jobs_cleaned, skills_long, growth_data)

# ============================================================
# CLEAN ACADEMIC PLOTLY THEME
# ============================================================
plotly_layout_clean <- function(p, title = "") {
  p %>%
    layout(
      title = list(
        text = title,
        font = list(color = "#1E293B", size = 15, family = "Inter, sans-serif")
      ),
      paper_bgcolor = "#FFFFFF",
      plot_bgcolor  = "#FFFFFF",
      font  = list(color = "#475569", family = "Inter, sans-serif", size = 12),
      xaxis = list(
        gridcolor     = "#F1F5F9",
        zerolinecolor = "#E2E8F0",
        tickfont      = list(color = "#475569", size = 11)
      ),
      yaxis = list(
        gridcolor     = "#F1F5F9",
        zerolinecolor = "#E2E8F0",
        tickfont      = list(color = "#475569", size = 11)
      ),
      legend = list(
        font = list(color = "#334155", size = 11)
      ),
      margin = list(t = 45, b = 40, l = 50, r = 20)
    )
}

# ============================================================
# USER INTERFACE
# ============================================================

ui <- page_navbar(
  title = tags$div(
    style = "display: flex; align-items: center; gap: 10px;",
    tags$i(class = "bi bi-graph-up-arrow", style = "font-size: 1.3rem; color: #38BDF8;"),
    tags$span("Job Market Skill Demand Analytics", style = "font-weight: 700; color: #FFFFFF; font-size: 1.15rem;"),
    tags$span("BDA PROJECT", class = "badge bg-primary",
              style = "font-size: 0.68rem; font-weight: 600; letter-spacing: 0.5px; padding: 4px 8px; margin-left: 6px;")
  ),
  id = "main_nav",
  inverse = TRUE,
  theme = bs_theme(
    version      = 5,
    bootswatch   = "flatly",
    primary      = "#2563EB",
    secondary    = "#475569",
    success      = "#059669",
    info         = "#0284C7",
    warning      = "#D97706",
    danger       = "#DC2626",
    bg           = "#F8FAFC",
    fg           = "#0F172A",
    base_font    = font_google("Inter"),
    heading_font = font_google("Inter"),
    "navbar-bg"  = "#1E293B"
  ),
  header = tags$head(
    tags$link(rel = "stylesheet",
              href = "https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css"),
    tags$style(HTML("
      /* ---- Clean Human/Academic Styling ---- */
      body {
        font-family: 'Inter', sans-serif;
        background-color: #F8FAFC;
        color: #0F172A;
      }

      /* Navbar */
      .navbar {
        background-color: #1E293B !important;
        border-bottom: 2px solid #0EA5E9 !important;
        padding: 10px 24px !important;
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
      }
      .navbar-nav .nav-link {
        color: #E2E8F0 !important;
        font-size: 0.92rem !important;
        font-weight: 500 !important;
        padding: 8px 16px !important;
        margin: 0 2px !important;
        border-radius: 6px !important;
        transition: all 0.2s ease-in-out !important;
      }
      .navbar-nav .nav-link:hover {
        color: #FFFFFF !important;
        background-color: rgba(255, 255, 255, 0.1) !important;
      }
      .navbar-nav .nav-link.active {
        color: #FFFFFF !important;
        background-color: #2563EB !important;
        font-weight: 600 !important;
        box-shadow: 0 2px 6px rgba(37, 99, 235, 0.35) !important;
      }
      .navbar-nav .nav-link i {
        margin-right: 6px;
      }

      /* Sub-header Banner */
      .academic-banner {
        background-color: #FFFFFF;
        border-bottom: 1px solid #E2E8F0;
        padding: 10px 24px;
        font-size: 0.85rem;
        color: #475569;
        display: flex;
        justify-content: space-between;
        align-items: center;
        box-shadow: 0 1px 2px rgba(0,0,0,0.02);
      }
      .academic-banner strong {
        color: #1E293B;
      }

      /* Human-Engineered KPI Stat Cards */
      .stat-card {
        background: #FFFFFF;
        border: 1px solid #E2E8F0;
        border-radius: 8px;
        padding: 18px 20px;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
        position: relative;
        overflow: hidden;
        margin-bottom: 16px;
        transition: transform 0.2s ease, box-shadow 0.2s ease;
      }
      .stat-card:hover {
        transform: translateY(-2px);
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
      }
      .stat-card::before {
        content: '';
        position: absolute;
        top: 0;
        left: 0;
        bottom: 0;
        width: 4px;
      }
      .stat-blue::before   { background-color: #2563EB; }
      .stat-teal::before   { background-color: #0D9488; }
      .stat-indigo::before { background-color: #4F46E5; }
      .stat-amber::before  { background-color: #D97706; }
      .stat-slate::before  { background-color: #475569; }

      .stat-top {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 8px;
      }
      .stat-label {
        font-size: 0.78rem;
        font-weight: 600;
        text-transform: uppercase;
        letter-spacing: 0.5px;
        color: #64748B;
      }
      .stat-icon {
        font-size: 1.2rem;
        color: #94A3B8;
      }
      .stat-value {
        font-size: 1.85rem;
        font-weight: 700;
        color: #0F172A;
        line-height: 1.1;
      }
      .stat-subtext {
        font-size: 0.8rem;
        color: #64748B;
        margin-top: 6px;
      }

      /* Clean Content Cards */
      .card {
        background-color: #FFFFFF !important;
        border: 1px solid #E2E8F0 !important;
        border-radius: 8px !important;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04) !important;
        margin-bottom: 20px;
      }
      .card-header {
        background-color: #F8FAFC !important;
        border-bottom: 1px solid #E2E8F0 !important;
        color: #1E293B !important;
        font-weight: 600 !important;
        font-size: 0.95rem !important;
        padding: 12px 18px !important;
      }
      .card-body {
        padding: 20px !important;
      }

      /* Academic Alert & Info Boxes */
      .alert-academic {
        background-color: #EFF6FF;
        border-left: 4px solid #2563EB;
        padding: 12px 16px;
        border-radius: 6px;
        color: #1E40AF;
        font-size: 0.88rem;
        margin-bottom: 16px;
      }
      .alert-forecast {
        background-color: #FFFBEB;
        border-left: 4px solid #D97706;
        padding: 12px 16px;
        border-radius: 6px;
        color: #92400E;
        font-size: 0.88rem;
        margin-bottom: 16px;
      }

      /* Clean DataTables */
      .dataTables_wrapper {
        font-size: 0.9rem;
      }
      table.dataTable {
        border-collapse: collapse !important;
        width: 100% !important;
      }
      table.dataTable thead th {
        background-color: #F1F5F9 !important;
        color: #1E293B !important;
        font-weight: 600 !important;
        border-bottom: 2px solid #CBD5E1 !important;
        padding: 10px !important;
      }
      table.dataTable tbody td {
        padding: 10px !important;
        color: #334155 !important;
        border-bottom: 1px solid #F1F5F9 !important;
      }
      table.dataTable tbody tr:hover {
        background-color: #F8FAFC !important;
      }

      /* Badges */
      .badge-growth-rising    { background-color: #DCFCE7; color: #166534; font-weight: 600; padding: 4px 8px; border-radius: 4px; }
      .badge-growth-stable    { background-color: #FEF3C7; color: #92400E; font-weight: 600; padding: 4px 8px; border-radius: 4px; }
      .badge-growth-declining { background-color: #FEE2E2; color: #991B1B; font-weight: 600; padding: 4px 8px; border-radius: 4px; }

      /* About Section */
      .about-card h4 {
        color: #1E293B;
        font-weight: 600;
        font-size: 1.1rem;
        margin-top: 18px;
        margin-bottom: 8px;
        border-bottom: 1px solid #E2E8F0;
        padding-bottom: 6px;
      }
      .about-card p, .about-card li {
        color: #334155;
        line-height: 1.6;
        font-size: 0.92rem;
      }
    "))
  ),

  # Sub-header bar
  tags$div(
    class = "academic-banner",
    tags$div(
      tags$strong("Big Data Analytics (BDA) Laboratory Project"),
      tags$span(" • ", style = "color:#CBD5E1;"),
      tags$span("Tech Job Market Skill Extraction & Forecasting"),
      tags$span(" • ", style = "color:#CBD5E1;"),
      tags$span("Records: 5,003 Postings (2021–2025)")
    ),
    tags$div(
      tags$i(class = "bi bi-check2-circle text-success me-1"),
      tags$span("Pipeline: R / tidyverse / forecast / Shiny")
    )
  ),

  # ============================================================
  # TAB 1: DASHBOARD
  # ============================================================
  nav_panel(
    title = tags$span(tags$i(class = "bi bi-grid-1x2-fill"), " Dashboard Overview"),
    value = "dashboard",
    div(
      class = "container-fluid p-4",

      # Stat Cards Row
      fluidRow(
        column(2,
          div(class = "stat-card stat-blue",
            div(class = "stat-top",
              span(class = "stat-label", "Total Jobs"),
              tags$i(class = "bi bi-briefcase-fill stat-icon")
            ),
            div(class = "stat-value", format(kpis$total_jobs, big.mark = ",")),
            div(class = "stat-subtext", "Deduplicated sample")
          )
        ),
        column(2,
          div(class = "stat-card stat-teal",
            div(class = "stat-top",
              span(class = "stat-label", "Skills Tracked"),
              tags$i(class = "bi bi-cpu-fill stat-icon")
            ),
            div(class = "stat-value", kpis$total_skills),
            div(class = "stat-subtext", "7 tech categories")
          )
        ),
        column(3,
          div(class = "stat-card stat-indigo",
            div(class = "stat-top",
              span(class = "stat-label", "Most Demanded"),
              tags$i(class = "bi bi-award-fill stat-icon")
            ),
            div(class = "stat-value", kpis$top_skill),
            div(class = "stat-subtext", "Highest frequency in listings")
          )
        ),
        column(3,
          div(class = "stat-card stat-amber",
            div(class = "stat-top",
              span(class = "stat-label", "Fastest Growing"),
              tags$i(class = "bi bi-graph-up-arrow stat-icon")
            ),
            div(class = "stat-value", kpis$fastest_growing),
            div(class = "stat-subtext", "Quarterly growth rate leader")
          )
        ),
        column(2,
          div(class = "stat-card stat-slate",
            div(class = "stat-top",
              span(class = "stat-label", "Job Roles"),
              tags$i(class = "bi bi-people-fill stat-icon")
            ),
            div(class = "stat-value", kpis$total_roles),
            div(class = "stat-subtext", "Analyzed categories")
          )
        )
      ),

      tags$div(style = "height: 8px;"),

      # Charts Row 1
      fluidRow(
        column(6,
          card(
            card_header(
              tags$span(tags$i(class = "bi bi-bar-chart-fill text-primary me-2"), "Top 15 Most Demanded Technical Skills")
            ),
            card_body(plotlyOutput("dash_top_skills", height = "380px"))
          )
        ),
        column(6,
          card(
            card_header(
              tags$span(tags$i(class = "bi bi-pie-chart-fill text-primary me-2"), "Skill Demand Distribution by Category")
            ),
            card_body(plotlyOutput("dash_category_pie", height = "380px"))
          )
        )
      ),

      # Charts Row 2
      fluidRow(
        column(6,
          card(
            card_header(
              tags$span(tags$i(class = "bi bi-link-45deg text-primary me-2"), "Top 10 Co-Occurring Skill Combinations")
            ),
            card_body(plotlyOutput("dash_combos", height = "360px"))
          )
        ),
        column(6,
          card(
            card_header(
              tags$span(tags$i(class = "bi bi-funnel-fill text-primary me-2"), "Skill Distribution by Growth Classification")
            ),
            card_body(plotlyOutput("dash_classification", height = "360px"))
          )
        )
      )
    )
  ),

  # ============================================================
  # TAB 2: SKILL ANALYSIS
  # ============================================================
  nav_panel(
    title = tags$span(tags$i(class = "bi bi-search"), " Skill Deep-Dive"),
    value = "skill_analysis",
    div(
      class = "container-fluid p-4",
      fluidRow(
        column(3,
          card(
            card_header("Select Technical Skill"),
            card_body(
              selectInput("skill_select", "Choose Skill to Inspect:",
                          choices = sort(unique(skills_long$skill)),
                          selected = "Python"),
              div(class = "alert-academic",
                tags$strong("Diagnostic Note:"),
                tags$p("This section evaluates individual skill demand metrics, category taxonomy, historical quarterly trajectory, and role-wise distribution.",
                       style = "margin: 4px 0 0 0; font-size: 0.82rem;")
              )
            )
          )
        ),
        column(9,
          fluidRow(
            column(3, uiOutput("skill_demand_card")),
            column(3, uiOutput("skill_rank_card")),
            column(3, uiOutput("skill_category_card")),
            column(3, uiOutput("skill_trend_card"))
          ),
          fluidRow(
            column(6,
              card(
                card_header("Quarterly Demand Trend (% of Job Postings)"),
                card_body(plotlyOutput("skill_trend_plot", height = "340px"))
              )
            ),
            column(6,
              card(
                card_header("Requirement Distribution Across Job Roles"),
                card_body(plotlyOutput("skill_roles_plot", height = "340px"))
              )
            )
          )
        )
      )
    )
  ),

  # ============================================================
  # TAB 3: JOB ROLES
  # ============================================================
  nav_panel(
    title = tags$span(tags$i(class = "bi bi-person-workspace"), " Job Role Analytics"),
    value = "roles",
    div(
      class = "container-fluid p-4",
      fluidRow(
        column(3,
          card(
            card_header("Select Industry Role"),
            card_body(
              selectInput("role_select", "Target Role:",
                          choices = sort(unique(skills_long$job_title)),
                          selected = "Software Developer"),
              uiOutput("role_info_panel")
            )
          )
        ),
        column(9,
          card(
            card_header("Top Required Skills for Selected Role"),
            card_body(plotlyOutput("role_skills_plot", height = "360px"))
          ),
          card(
            card_header("Skill Breakdown & Frequency Table"),
            card_body(DTOutput("role_skills_table"))
          )
        )
      )
    )
  ),

  # ============================================================
  # TAB 4: SKILL TRENDS
  # ============================================================
  nav_panel(
    title = tags$span(tags$i(class = "bi bi-graph-up"), " Trend Comparison"),
    value = "trends",
    div(
      class = "container-fluid p-4",
      fluidRow(
        column(3,
          card(
            card_header("Compare Technologies"),
            card_body(
              selectInput("trend_skills", "Select Skills (Max 5):",
                          choices = sort(unique(trend_data$skill)),
                          selected = c("Python", "JavaScript", "Docker", "AWS", "Machine Learning"),
                          multiple = TRUE),
              div(class = "alert-academic",
                tags$strong("Comparison View:"),
                tags$p("Compare quarterly trajectories (2021 to 2025) to evaluate rising vs. mature technologies.",
                       style = "margin: 4px 0 0 0; font-size: 0.82rem;")
              )
            )
          )
        ),
        column(9,
          card(
            card_header("Multi-Skill Historical Demand Trajectory (Quarterly %)"),
            card_body(plotlyOutput("trend_line_plot", height = "400px"))
          ),
          card(
            card_header("Calculated Growth Rate Summary Table"),
            card_body(DTOutput("growth_table"))
          )
        )
      )
    )
  ),

  # ============================================================
  # TAB 5: FUTURE SKILLS (FORECASTING)
  # ============================================================
  nav_panel(
    title = tags$span(tags$i(class = "bi bi-lightning-charge"), " Future Skill Prediction"),
    value = "future",
    div(
      class = "container-fluid p-4",

      div(class = "alert-forecast",
        tags$i(class = "bi bi-info-circle-fill me-2"),
        tags$strong("Predictive Analytics Methodology:"),
        " Forecasts are generated using Exponential Smoothing (ETS). Confidence intervals (95%) reflect empirical statistical variance over time."
      ),

      fluidRow(
        column(3,
          card(
            card_header("Forecast Parameters"),
            card_body(
              selectInput("forecast_skill", "Skill to Forecast:",
                          choices = names(forecast_results),
                          selected = names(forecast_results)[1]),
              tags$br(),
              uiOutput("forecast_model_info")
            )
          )
        ),
        column(9,
          card(
            card_header("Time-Series Demand Forecast (Next 3 Quarters)"),
            card_body(plotlyOutput("forecast_plot", height = "380px"))
          ),
          card(
            card_header("Summary of Forecasted Skill Trajectories"),
            card_body(DTOutput("forecast_summary_table"))
          )
        )
      )
    )
  ),

  # ============================================================
  # TAB 6: ABOUT & PROJECT METADATA
  # ============================================================
  nav_panel(
    title = tags$span(tags$i(class = "bi bi-info-circle"), " Project Documentation"),
    value = "about",
    div(
      class = "container-fluid p-4",
      card(
        card_body(class = "about-card",
          tags$div(
            style = "text-align: center; margin-bottom: 24px;",
            tags$h3("Job Market Skill Demand Analytics & Future Skill Prediction", style = "font-weight: 700; color: #1E293B;"),
            tags$p("Bachelor of Engineering (B.E.) — Computer Engineering | Big Data Analytics Mini Project",
                   style = "color: #64748B; font-weight: 500;")
          ),

          tags$h4("1. Project Overview"),
          tags$p("This academic mini-project implements a complete Big Data Analytics pipeline using R Programming. It analyses a dataset of over 5,000 job postings across 10 technical domains to identify top demanded skills, examine co-occurrence patterns, track quarterly demand trajectories (2021–2025), and forecast future demand using Exponential Smoothing (ETS)."),

          tags$h4("2. Analytics Architecture"),
          tags$ul(
            tags$li(tags$strong("Descriptive Analytics:"), " Frequency distribution of skills, category share, and role-wise top requirements."),
            tags$li(tags$strong("Diagnostic Analytics:"), " Pairwise co-occurrence matrix identifying common multi-skill stacks (e.g., Python + SQL)."),
            tags$li(tags$strong("Predictive Analytics:"), " Time-series forecasting utilizing the ETS (Error, Trend, Seasonal) algorithm from the R forecast package.")
          ),

          tags$h4("3. Technology Stack"),
          tags$ul(
            tags$li(tags$strong("Core Language:"), " R (v4.6+)"),
            tags$li(tags$strong("Data Manipulation:"), " tidyverse (dplyr, tidyr, readr, stringr, lubridate)"),
            tags$li(tags$strong("Visualization:"), " ggplot2, plotly (interactive rendering)"),
            tags$li(tags$strong("Time Series & Forecasting:"), " forecast (ETS / ARIMA)"),
            tags$li(tags$strong("Dashboard Framework:"), " Shiny, bslib, DT")
          ),

          tags$h4("4. Preprocessing & Skill Extraction"),
          tags$p("A curated technical skill taxonomy (60+ technical skills categorized into 7 domains) is mapped against posting descriptions using an 80+ synonym dictionary to handle variations (e.g., 'ReactJS' → 'React', 'K8s' → 'Kubernetes', 'JS' → 'JavaScript'). Duplicate postings are removed and dates are parsed to quarterly intervals."),

          tags$h4("5. Academic Limitations & Scope"),
          tags$ul(
            tags$li("The dataset is a realistic synthetic benchmark designed for reproducible academic demonstration."),
            tags$li("Skill extraction uses deterministic dictionary matching rather than probabilistic NLP NER models."),
            tags$li("Future extension includes connecting live streaming feeds via Apache Kafka and adding salary prediction regression models.")
          ),

          tags$hr(style = "margin-top: 30px;"),
          tags$p(style = "text-align: center; color: #64748B; font-size: 0.85rem;",
                 "B.E. Computer Engineering Mini Project | Big Data Analytics (BDA) | Developed with R & Shiny")
        )
      )
    )
  )
)

# ============================================================
# SERVER LOGIC
# ============================================================

server <- function(input, output, session) {

  # ----- DASHBOARD OVERVIEW -----

  # Top 15 Skills Horizontal Bar Chart
  output$dash_top_skills <- renderPlotly({
    df <- top_skills_df %>% head(15)

    p <- ggplot(df, aes(x = reorder(skill, n_jobs), y = n_jobs,
                         text = paste0("<b>", skill, "</b>\nPostings: ", format(n_jobs, big.mark = ","),
                                       "\nDemand: ", demand_pct, "%"))) +
      geom_col(fill = "#2563EB", width = 0.68) +
      geom_text(aes(label = paste0(demand_pct, "%")),
                hjust = -0.15, color = "#475569", size = 3.2) +
      coord_flip(clip = "off") +
      scale_y_continuous(labels = comma, expand = expansion(mult = c(0, 0.15))) +
      labs(x = NULL, y = "Number of Job Postings") +
      theme_minimal(base_size = 11) +
      theme(
        panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(colour = "#F1F5F9"),
        axis.text          = element_text(colour = "#334155"),
        axis.title         = element_text(colour = "#475569", size = 10)
      )

    ggplotly(p, tooltip = "text") %>%
      plotly_layout_clean()
  })

  # Skill Demand by Category Donut Chart
  output$dash_category_pie <- renderPlotly({
    cat_data <- skills_long %>%
      filter(!is.na(category)) %>%
      count(category, sort = TRUE)

    clean_colors <- c("#2563EB", "#0D9488", "#7C3AED", "#D97706",
                      "#E11D48", "#0284C7", "#475569")

    plot_ly(cat_data, labels = ~category, values = ~n,
            type = "pie", hole = 0.52,
            marker = list(colors = clean_colors,
                          line = list(color = "#FFFFFF", width = 2)),
            textinfo = "label+percent",
            textposition = "inside",
            insidetextfont = list(color = "#FFFFFF", size = 11),
            hovertemplate = "<b>%{label}</b><br>Occurrences: %{value}<br>Share: %{percent}<extra></extra>") %>%
      plotly_layout_clean() %>%
      layout(
        showlegend = TRUE,
        legend = list(orientation = "h", y = -0.15, font = list(size = 10))
      )
  })

  # Top Skill Combinations
  output$dash_combos <- renderPlotly({
    df <- combo_data %>% head(10)

    p <- ggplot(df, aes(x = reorder(combination, co_occurrence), y = co_occurrence,
                         text = paste0("<b>", combination, "</b>\nCo-occurrences: ", co_occurrence))) +
      geom_col(fill = "#4F46E5", width = 0.68) +
      coord_flip() +
      scale_y_continuous(labels = comma) +
      labs(x = NULL, y = "Co-occurrence Count") +
      theme_minimal(base_size = 11) +
      theme(
        panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(colour = "#F1F5F9"),
        axis.text          = element_text(colour = "#334155"),
        axis.title         = element_text(colour = "#475569", size = 10)
      )

    ggplotly(p, tooltip = "text") %>%
      plotly_layout_clean()
  })

  # Skill Growth Classification
  output$dash_classification <- renderPlotly({
    df <- classified %>%
      count(classification) %>%
      mutate(color = case_when(
        classification == "Rising Demand"     ~ "#059669",
        classification == "Moderately Rising" ~ "#0284C7",
        classification == "Stable Demand"     ~ "#D97706",
        classification == "Declining Demand"  ~ "#DC2626",
        TRUE ~ "#64748B"
      ))

    plot_ly(df, x = ~classification, y = ~n, type = "bar",
            marker = list(color = ~color),
            text = ~n, textposition = "outside",
            hovertemplate = "<b>%{x}</b><br>Skills: %{y}<extra></extra>") %>%
      plotly_layout_clean("Skills by Growth Velocity") %>%
      layout(
        xaxis = list(title = ""),
        yaxis = list(title = "Number of Skills")
      )
  })

  # ----- SKILL DEEP-DIVE -----

  selected_skill_data <- reactive({
    sk <- input$skill_select
    list(
      counts = skills_long %>%
        filter(skill == sk) %>%
        summarise(n_jobs = n_distinct(job_id)),
      rank = top_skills_df %>%
        bind_rows(get_top_skills(skills_long, total_jobs, top_n = 100)) %>%
        distinct(skill, .keep_all = TRUE) %>%
        arrange(desc(n_jobs)) %>%
        mutate(rank = row_number()) %>%
        filter(skill == sk),
      category = skill_to_category %>% filter(skill == sk),
      growth   = growth_data %>% filter(skill == sk)
    )
  })

  output$skill_demand_card <- renderUI({
    d <- selected_skill_data()
    demand_pct <- round(d$counts$n_jobs / total_jobs * 100, 1)
    div(class = "stat-card stat-blue",
      div(class = "stat-top",
        span(class = "stat-label", "Market Share"),
        tags$i(class = "bi bi-pie-chart-fill stat-icon")
      ),
      div(class = "stat-value", paste0(demand_pct, "%")),
      div(class = "stat-subtext", paste0(d$counts$n_jobs, " total job postings"))
    )
  })

  output$skill_rank_card <- renderUI({
    d <- selected_skill_data()
    rank_val <- if (nrow(d$rank) > 0) d$rank$rank[1] else "N/A"
    div(class = "stat-card stat-teal",
      div(class = "stat-top",
        span(class = "stat-label", "Demand Rank"),
        tags$i(class = "bi bi-hash stat-icon")
      ),
      div(class = "stat-value", paste0("#", rank_val)),
      div(class = "stat-subtext", "Across all 54 skills")
    )
  })

  output$skill_category_card <- renderUI({
    d <- selected_skill_data()
    cat_val <- if (nrow(d$category) > 0) d$category$category[1] else "General"
    div(class = "stat-card stat-indigo",
      div(class = "stat-top",
        span(class = "stat-label", "Skill Domain"),
        tags$i(class = "bi bi-folder-fill stat-icon")
      ),
      div(class = "stat-value", style = "font-size: 1.3rem;", cat_val),
      div(class = "stat-subtext", "Taxonomy grouping")
    )
  })

  output$skill_trend_card <- renderUI({
    d <- selected_skill_data()
    if (nrow(d$growth) > 0) {
      gr <- d$growth$growth_rate[1]
      trend_dir <- d$growth$trend_direction[1]
      colour_class <- if (gr > 0) "stat-teal" else if (gr < 0) "stat-amber" else "stat-slate"
      dir_color    <- if (gr > 0) "#059669" else if (gr < 0) "#DC2626" else "#D97706"
    } else {
      gr <- 0; trend_dir <- "N/A"; colour_class <- "stat-slate"; dir_color <- "#64748B"
    }
    div(class = paste("stat-card", colour_class),
      div(class = "stat-top",
        span(class = "stat-label", "Growth Velocity"),
        tags$i(class = "bi bi-activity stat-icon")
      ),
      div(class = "stat-value", style = paste0("color: ", dir_color),
          paste0(ifelse(gr > 0, "+", ""), round(gr, 1), "%")),
      div(class = "stat-subtext", paste("Trend:", trend_dir))
    )
  })

  output$skill_trend_plot <- renderPlotly({
    sk <- input$skill_select
    df <- trend_data %>% filter(skill == sk) %>% arrange(year, quarter)
    if (nrow(df) == 0) return(NULL)

    p <- ggplot(df, aes(x = year_quarter, y = demand_pct, group = 1,
                         text = paste0("<b>", year_quarter, "</b>\nDemand: ", demand_pct, "%"))) +
      geom_line(color = "#2563EB", linewidth = 1.3) +
      geom_point(color = "#1E40AF", size = 2.5) +
      labs(x = NULL, y = "Demand (% of Postings)") +
      theme_minimal(base_size = 11) +
      theme(
        panel.grid.major = element_line(colour = "#F1F5F9"),
        axis.text.x      = element_text(angle = 45, hjust = 1, colour = "#334155"),
        axis.text.y      = element_text(colour = "#334155")
      )

    ggplotly(p, tooltip = "text") %>%
      plotly_layout_clean()
  })

  output$skill_roles_plot <- renderPlotly({
    sk <- input$skill_select
    df <- skills_long %>%
      filter(skill == sk) %>%
      group_by(job_title) %>%
      summarise(n = n_distinct(job_id), .groups = "drop") %>%
      arrange(desc(n))

    p <- ggplot(df, aes(x = reorder(job_title, n), y = n,
                         text = paste0("<b>", job_title, "</b>\nPostings: ", n))) +
      geom_col(fill = "#0D9488", width = 0.68) +
      coord_flip() +
      labs(x = NULL, y = "Number of Jobs") +
      theme_minimal(base_size = 11) +
      theme(
        panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(colour = "#F1F5F9"),
        axis.text          = element_text(colour = "#334155")
      )

    ggplotly(p, tooltip = "text") %>%
      plotly_layout_clean()
  })

  # ----- JOB ROLES -----

  output$role_info_panel <- renderUI({
    role <- input$role_select
    role_jobs <- skills_long %>% filter(job_title == role) %>% summarise(n = n_distinct(job_id))
    role_sk   <- skills_long %>% filter(job_title == role) %>% summarise(n = n_distinct(skill))

    tagList(
      div(class = "stat-card stat-blue", style = "margin-bottom: 12px;",
        div(class = "stat-label", "Role Postings"),
        div(class = "stat-value", format(role_jobs$n, big.mark = ",")),
        div(class = "stat-subtext", "Total role occurrences")
      ),
      div(class = "stat-card stat-teal",
        div(class = "stat-label", "Distinct Skills"),
        div(class = "stat-value", role_sk$n),
        div(class = "stat-subtext", "Associated technical skills")
      )
    )
  })

  output$role_skills_plot <- renderPlotly({
    df <- get_role_skills(skills_long, input$role_select, top_n = 15)

    p <- ggplot(df, aes(x = reorder(skill, demand_pct), y = demand_pct,
                         text = paste0("<b>", skill, "</b>\nPostings: ", n_jobs, "\nRole Demand: ", demand_pct, "%"))) +
      geom_col(fill = "#0284C7", width = 0.68) +
      geom_text(aes(label = paste0(demand_pct, "%")),
                hjust = -0.15, color = "#475569", size = 3) +
      coord_flip(clip = "off") +
      scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
      labs(x = NULL, y = "Demand (% of Role's Postings)") +
      theme_minimal(base_size = 11) +
      theme(
        panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(colour = "#F1F5F9"),
        axis.text          = element_text(colour = "#334155")
      )

    ggplotly(p, tooltip = "text") %>%
      plotly_layout_clean()
  })

  output$role_skills_table <- renderDT({
    df <- get_role_skills(skills_long, input$role_select, top_n = 20) %>%
      select(Skill = skill, Category = category, Jobs = n_jobs, `Demand %` = demand_pct)

    datatable(df, options = list(pageLength = 10, dom = "ftp"),
              rownames = FALSE, class = "table table-hover table-striped")
  })

  # ----- TREND COMPARISON -----

  output$trend_line_plot <- renderPlotly({
    selected <- input$trend_skills
    if (is.null(selected) || length(selected) == 0) return(NULL)
    selected <- head(selected, 5)

    df <- trend_data %>%
      filter(skill %in% selected) %>%
      arrange(year, quarter)

    clean_colors <- c("#2563EB", "#059669", "#D97706", "#DC2626", "#7C3AED")

    p <- ggplot(df, aes(x = year_quarter, y = demand_pct,
                         color = skill, group = skill,
                         text = paste0("<b>", skill, "</b>\nQuarter: ", year_quarter, "\nDemand: ", demand_pct, "%"))) +
      geom_line(linewidth = 1.2) +
      geom_point(size = 2.5) +
      scale_color_manual(values = clean_colors[seq_along(selected)]) +
      labs(x = NULL, y = "Demand (% of Postings)", color = "Skill") +
      theme_minimal(base_size = 11) +
      theme(
        panel.grid.major = element_line(colour = "#F1F5F9"),
        axis.text.x      = element_text(angle = 45, hjust = 1, colour = "#334155"),
        axis.text.y      = element_text(colour = "#334155"),
        legend.position  = "bottom"
      )

    ggplotly(p, tooltip = "text") %>%
      plotly_layout_clean()
  })

  output$growth_table <- renderDT({
    df <- classified %>%
      select(Skill = skill, `Early Baseline %` = early, `Recent Average %` = late,
             `Growth Rate %` = growth_rate, Trend = trend_direction,
             Classification = classification) %>%
      arrange(desc(`Growth Rate %`))

    datatable(df, options = list(pageLength = 10, dom = "ftp"),
              rownames = FALSE, class = "table table-hover table-striped") %>%
      formatStyle("Growth Rate %",
                  color = styleInterval(c(-10, 10), c("#DC2626", "#D97706", "#059669")),
                  fontWeight = "600")
  })

  # ----- FUTURE PREDICTIONS (ETS FORECASTING) -----

  output$forecast_plot <- renderPlotly({
    sk <- input$forecast_skill
    if (is.null(sk) || !(sk %in% names(forecast_results))) return(NULL)

    df      <- forecast_results[[sk]]$data
    hist_df <- df %>% filter(type == "Historical")
    fc_df   <- df %>% filter(type == "Forecast")

    p <- plot_ly() %>%
      # Historical Demand (Navy line)
      add_trace(data = hist_df, x = ~year_quarter, y = ~demand_pct,
                type = "scatter", mode = "lines+markers",
                name = "Historical Demand",
                line = list(color = "#1E40AF", width = 2.5),
                marker = list(color = "#1E40AF", size = 6),
                hovertemplate = "<b>Historical</b><br>Quarter: %{x}<br>Demand: %{y:.2f}%<extra></extra>")

    if (nrow(fc_df) > 0) {
      # Forecast Demand (Amber dashed line)
      p <- p %>%
        add_trace(data = fc_df, x = ~year_quarter, y = ~demand_pct,
                  type = "scatter", mode = "lines+markers",
                  name = "ETS Forecast",
                  line = list(color = "#D97706", width = 2.5, dash = "dash"),
                  marker = list(color = "#D97706", size = 7, symbol = "diamond"),
                  hovertemplate = "<b>Forecast</b><br>Quarter: %{x}<br>Predicted: %{y:.2f}%<extra></extra>")

      # 95% Confidence Interval Ribbon
      if (any(!is.na(fc_df$lower_95))) {
        p <- p %>%
          add_trace(data = fc_df, x = ~year_quarter, y = ~upper_95,
                    type = "scatter", mode = "lines",
                    line = list(width = 0), showlegend = FALSE, hoverinfo = "skip") %>%
          add_trace(data = fc_df, x = ~year_quarter, y = ~lower_95,
                    type = "scatter", mode = "lines",
                    fill = "tonexty",
                    fillcolor = "rgba(217, 119, 6, 0.15)",
                    line = list(width = 0),
                    name = "95% Prediction Interval",
                    hoverinfo = "skip")
      }

      # Bridge line connecting last historical point to first forecast point
      bridge <- bind_rows(
        hist_df %>% arrange(year, quarter) %>% slice_tail(n = 1) %>% select(year_quarter, demand_pct),
        fc_df %>% arrange(year, quarter) %>% slice_head(n = 1) %>% select(year_quarter, demand_pct)
      )
      p <- p %>%
        add_trace(data = bridge, x = ~year_quarter, y = ~demand_pct,
                  type = "scatter", mode = "lines",
                  line = list(color = "#D97706", width = 1.5, dash = "dot"),
                  showlegend = FALSE, hoverinfo = "skip")
    }

    p %>%
      plotly_layout_clean(paste("ETS Forecast Model —", sk)) %>%
      layout(
        xaxis = list(title = "Quarter"),
        yaxis = list(title = "Demand Percentage (%)")
      )
  })

  output$forecast_model_info <- renderUI({
    sk <- input$forecast_skill
    if (is.null(sk) || !(sk %in% names(forecast_results))) return(NULL)

    model     <- forecast_results[[sk]]$model
    cls       <- forecast_summary %>% filter(skill == sk)
    cls_label <- if (nrow(cls) > 0) cls$classification[1] else "N/A"
    cls_class <- case_when(
      cls_label == "Rising Demand"   ~ "stat-teal",
      cls_label == "Stable Demand"   ~ "stat-amber",
      cls_label == "Declining Demand"~ "stat-slate",
      TRUE ~ "stat-blue"
    )

    tagList(
      div(class = "alert-academic",
        tags$strong("Fitted Model: "), model$model_type, tags$br(),
        tags$strong("AIC Criterion: "), round(model$aic, 2)
      ),
      div(class = paste("stat-card", cls_class),
        div(class = "stat-label", "Predicted Outlook"),
        div(class = "stat-value", style = "font-size: 1.3rem;", cls_label),
        div(class = "stat-subtext", "Based on model trajectory")
      )
    )
  })

  output$forecast_summary_table <- renderDT({
    df <- forecast_summary %>%
      select(Skill = skill,
             `Current Demand %` = current_demand_pct,
             `Forecasted Demand %` = forecasted_demand_pct,
             `Net Change %` = predicted_change_pct,
             Model = model_type,
             Classification = classification) %>%
      arrange(desc(`Forecasted Demand %`))

    datatable(df, options = list(pageLength = 10, dom = "ftp"),
              rownames = FALSE, class = "table table-hover table-striped") %>%
      formatStyle("Net Change %",
                  color = styleInterval(c(-1, 1), c("#DC2626", "#475569", "#059669")),
                  fontWeight = "600")
  })
}

# ============================================================
# LAUNCH APPLICATION
# ============================================================
shinyApp(ui = ui, server = server)
