# ============================================================
# R/skill_extraction.R — Skill Extraction Module
# ============================================================
# Functions for:
#   • Defining the master technical-skill dictionary
#   • Extracting skills from job descriptions
#   • Building a long-format skills table
# ============================================================

library(tidyverse)

# ------------------------------------------------------------------
# Master Skill Dictionary — categorised by domain
# ------------------------------------------------------------------
skill_dictionary <- list(
  "Programming Languages" = c(
    "C", "C++", "Java", "Python", "JavaScript", "TypeScript",
    "Go", "R", "C#", "Rust", "Kotlin", "Swift", "PHP", "Ruby"
  ),
  "Web Development" = c(
    "HTML", "CSS", "React", "Angular", "Vue.js", "Node.js",
    "Sass", "Webpack", "Redux", "REST API", "Figma"
  ),
  "Databases" = c(
    "SQL", "MySQL", "PostgreSQL", "MongoDB", "Redis",
    "SQL Server", "SQLite", "Oracle"
  ),
  "Cloud & DevOps" = c(
    "AWS", "Azure", "Docker", "Kubernetes", "Git",
    "Terraform", "CI/CD", "Jenkins", "Ansible",
    "Linux", "Bash", "Monitoring", "Networking"
  ),
  "Data & AI" = c(
    "Machine Learning", "Artificial Intelligence", "Deep Learning",
    "TensorFlow", "PyTorch", "Scikit-Learn", "NLP",
    "Computer Vision", "Spark", "Hadoop", "Pandas", "NumPy",
    "Statistics", "Data Visualization", "ETL", "MLOps"
  ),
  "BI & Analytics" = c(
    "Power BI", "Tableau", "Excel"
  ),
  "Methodologies" = c(
    "Agile", "Spring"
  )
)

# Flat list of all known skills
all_skills <- unlist(skill_dictionary, use.names = FALSE) %>% unique()

# Reverse lookup: skill → category
skill_to_category <- tibble(
  skill = character(),
  category = character()
)
for (cat in names(skill_dictionary)) {
  skill_to_category <- bind_rows(
    skill_to_category,
    tibble(skill = skill_dictionary[[cat]], category = cat)
  )
}

# ------------------------------------------------------------------
# extract_skills_from_text: find known skills in a text string
# ------------------------------------------------------------------
extract_skills_from_text <- function(text, skill_list = all_skills) {
  if (is.na(text) || text == "") return(character(0))
  
  text_lower <- tolower(text)
  
  found <- sapply(skill_list, function(sk) {
    pattern <- paste0("\\b", tolower(sk), "\\b")
    # Handle special regex characters in skill names
    pattern <- str_replace_all(pattern, "\\+", "\\\\+")
    pattern <- str_replace_all(pattern, "\\.", "\\\\.")
    pattern <- str_replace_all(pattern, "\\#", "\\\\#")
    grepl(pattern, text_lower, perl = TRUE)
  }, USE.NAMES = TRUE)
  
  names(found)[found]
}

# ------------------------------------------------------------------
# build_skills_long: expand cleaned data to long format
#   Each row = one (job, skill) pair
# ------------------------------------------------------------------
build_skills_long <- function(df) {
  # Use the cleaned skills column (comma-separated)
  skills_long <- df %>%
    select(job_id, job_title, company, location, posted_date,
           year, quarter, year_quarter, salary_lpa,
           experience_years, skills_clean) %>%
    separate_rows(skills_clean, sep = ",\\s*") %>%
    rename(skill = skills_clean) %>%
    filter(skill != "", !is.na(skill)) %>%
    # Add category
    left_join(skill_to_category, by = "skill")
  
  message("Skills long table: ", nrow(skills_long), " rows, ",
          n_distinct(skills_long$skill), " unique skills")
  
  return(skills_long)
}

# ------------------------------------------------------------------
# get_skill_counts: basic frequency table
# ------------------------------------------------------------------
get_skill_counts <- function(skills_long, total_jobs) {
  skills_long %>%
    group_by(skill, category) %>%
    summarise(
      n_jobs   = n_distinct(job_id),
      .groups  = "drop"
    ) %>%
    mutate(
      demand_pct = round(n_jobs / total_jobs * 100, 2)
    ) %>%
    arrange(desc(n_jobs))
}
