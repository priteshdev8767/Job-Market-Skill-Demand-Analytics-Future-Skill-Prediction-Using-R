# ============================================================
# R/analysis.R — Core Analytics Functions
# ============================================================
# Implements:
#   Analysis 1 – Top Skills
#   Analysis 2 – Skills by Job Role
#   Analysis 3 – Skill Trend Analysis
#   Analysis 4 – Skill Combination Analysis
#   Analysis 5 – Skill Classification
# ============================================================

library(tidyverse)
library(lubridate)

# ------------------------------------------------------------------
# Analysis 1: Top N most demanded skills
# ------------------------------------------------------------------
get_top_skills <- function(skills_long, total_jobs, top_n = 20) {
  skills_long %>%
    group_by(skill, category) %>%
    summarise(n_jobs = n_distinct(job_id), .groups = "drop") %>%
    mutate(demand_pct = round(n_jobs / total_jobs * 100, 2)) %>%
    arrange(desc(n_jobs)) %>%
    head(top_n) %>%
    mutate(rank = row_number())
}

# ------------------------------------------------------------------
# Analysis 2: Skills by job role
# ------------------------------------------------------------------
get_role_skills <- function(skills_long, role, top_n = 15) {
  role_data <- skills_long %>%
    filter(job_title == role)
  
  total_role_jobs <- n_distinct(role_data$job_id)
  
  role_data %>%
    group_by(skill, category) %>%
    summarise(n_jobs = n_distinct(job_id), .groups = "drop") %>%
    mutate(
      demand_pct = round(n_jobs / total_role_jobs * 100, 2),
      role       = role,
      total_role_jobs = total_role_jobs
    ) %>%
    arrange(desc(n_jobs)) %>%
    head(top_n)
}

# Get summary for all roles
get_all_roles_summary <- function(skills_long) {
  skills_long %>%
    group_by(job_title) %>%
    summarise(
      n_jobs   = n_distinct(job_id),
      n_skills = n_distinct(skill),
      .groups  = "drop"
    ) %>%
    arrange(desc(n_jobs))
}

# ------------------------------------------------------------------
# Analysis 3: Skill Trend Analysis — quarterly demand over time
# ------------------------------------------------------------------
get_skill_trends <- function(skills_long, jobs_df) {
  # Total jobs per quarter
  jobs_per_quarter <- jobs_df %>%
    group_by(year_quarter, year, quarter) %>%
    summarise(total_quarter_jobs = n(), .groups = "drop")
  
  # Skill counts per quarter
  skill_quarter <- skills_long %>%
    group_by(skill, year_quarter, year, quarter) %>%
    summarise(n_jobs = n_distinct(job_id), .groups = "drop")
  
  # Merge and compute demand percentage
  trend <- skill_quarter %>%
    left_join(jobs_per_quarter, by = c("year_quarter", "year", "quarter")) %>%
    mutate(demand_pct = round(n_jobs / total_quarter_jobs * 100, 2)) %>%
    arrange(skill, year, quarter)
  
  return(trend)
}

# Calculate growth rate for each skill
get_skill_growth <- function(trend_data) {
  # Compare first half and last half
  trend_data %>%
    group_by(skill) %>%
    arrange(year, quarter) %>%
    mutate(period = ifelse(row_number() <= n() / 2, "early", "late")) %>%
    group_by(skill, period) %>%
    summarise(avg_demand = mean(demand_pct, na.rm = TRUE), .groups = "drop") %>%
    pivot_wider(names_from = period, values_from = avg_demand) %>%
    filter(!is.na(early), !is.na(late)) %>%
    mutate(
      growth_rate = round((late - early) / early * 100, 2),
      trend_direction = case_when(
        growth_rate > 10  ~ "Rising",
        growth_rate < -10 ~ "Declining",
        TRUE              ~ "Stable"
      )
    ) %>%
    arrange(desc(growth_rate))
}

# ------------------------------------------------------------------
# Analysis 4: Skill Combination Analysis
# ------------------------------------------------------------------
get_skill_combinations <- function(jobs_df, top_n = 20) {
  # Parse skills per job into a list
  job_skills <- jobs_df %>%
    select(job_id, skills_clean) %>%
    mutate(skill_list = str_split(skills_clean, ",\\s*"))
  
  # Generate all pairs for each job
  all_pairs <- lapply(seq_len(nrow(job_skills)), function(i) {
    sk <- sort(unique(job_skills$skill_list[[i]]))
    if (length(sk) < 2) return(NULL)
    pairs <- combn(sk, 2, simplify = FALSE)
    tibble(
      skill_1 = sapply(pairs, `[`, 1),
      skill_2 = sapply(pairs, `[`, 2)
    )
  })
  
  pairs_df <- bind_rows(all_pairs)
  
  # Count occurrences
  combo_counts <- pairs_df %>%
    group_by(skill_1, skill_2) %>%
    summarise(co_occurrence = n(), .groups = "drop") %>%
    mutate(combination = paste(skill_1, "+", skill_2)) %>%
    arrange(desc(co_occurrence)) %>%
    head(top_n)
  
  return(combo_counts)
}

# ------------------------------------------------------------------
# Analysis 5: Skill Classification based on growth/trend
# ------------------------------------------------------------------
classify_skills <- function(growth_data) {
  growth_data %>%
    mutate(
      classification = case_when(
        growth_rate > 15  ~ "Rising Demand",
        growth_rate > 0   ~ "Moderately Rising",
        growth_rate > -10 ~ "Stable Demand",
        TRUE              ~ "Declining Demand"
      ),
      classification = factor(classification,
                               levels = c("Rising Demand", "Moderately Rising",
                                          "Stable Demand", "Declining Demand"))
    )
}

# ------------------------------------------------------------------
# Dashboard KPIs
# ------------------------------------------------------------------
get_dashboard_kpis <- function(jobs_df, skills_long, growth_data) {
  total_jobs    <- nrow(jobs_df)
  total_skills  <- n_distinct(skills_long$skill)
  total_roles   <- n_distinct(skills_long$job_title)
  
  # Most demanded skill
  top_skill <- skills_long %>%
    count(skill, sort = TRUE) %>%
    slice(1) %>%
    pull(skill)
  
  # Fastest growing skill (among those with reasonable sample size)
  fastest_growing <- growth_data %>%
    filter(!is.na(growth_rate)) %>%
    arrange(desc(growth_rate)) %>%
    slice(1) %>%
    pull(skill)
  
  list(
    total_jobs      = total_jobs,
    total_skills    = total_skills,
    total_roles     = total_roles,
    top_skill       = top_skill,
    fastest_growing = fastest_growing
  )
}
