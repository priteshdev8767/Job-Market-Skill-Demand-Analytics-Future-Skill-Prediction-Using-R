# ============================================================
# R/data_cleaning.R — Data Preprocessing and Cleaning
# ============================================================
# Functions for:
#   • Removing duplicates
#   • Handling missing values
#   • Cleaning dates, titles, locations
#   • Normalising skill names
# ============================================================

library(tidyverse)
library(lubridate)

# ------------------------------------------------------------------
# Skill synonym dictionary
# Maps messy/abbreviated skill names → canonical names
# Easy to extend: just add new entries
# ------------------------------------------------------------------
skill_synonyms <- c(
  # JavaScript variants
  "java script"   = "JavaScript",
  "js"            = "JavaScript",
  "javascript"    = "JavaScript",
  
  # React variants
  "react.js"      = "React",
  "reactjs"       = "React",
  "react js"      = "React",
  
  # Node variants
  "nodejs"        = "Node.js",
  "node"          = "Node.js",
  "node js"       = "Node.js",
  
  # TypeScript
  "typescript"    = "TypeScript",
  "ts"            = "TypeScript",
  
  # ML / AI
  "ml"            = "Machine Learning",
  "machine learning" = "Machine Learning",
  "ai"            = "Artificial Intelligence",
  "artificial intelligence" = "Artificial Intelligence",
  
  # Databases
  "postgres"      = "PostgreSQL",
  "postgresql"    = "PostgreSQL",
  "mongo db"      = "MongoDB",
  "mongo"         = "MongoDB",
  "mongodb"       = "MongoDB",
  "mysql"         = "MySQL",
  "sql server"    = "SQL Server",
  
  # DevOps / Cloud
  "k8s"           = "Kubernetes",
  "kubernetes"    = "Kubernetes",
  "amazon web services" = "AWS",
  "aws"           = "AWS",
  "azure"         = "Azure",
  "docker"        = "Docker",
  "git"           = "Git",
  "github"        = "Git",
  
  # BI tools
  "powerbi"       = "Power BI",
  "power bi"      = "Power BI",
  "tableau"       = "Tableau",
  
  # Deep Learning frameworks
  "tensorflow"    = "TensorFlow",
  "tensor flow"   = "TensorFlow",
  "pytorch"       = "PyTorch",
  "py torch"      = "PyTorch",
  
  # Languages
  "python"        = "Python",
  "java"          = "Java",
  "c++"           = "C++",
  "cpp"           = "C++",
  "c#"            = "C#",
  "golang"        = "Go",
  "go"            = "Go",
  "r"             = "R",
  
  # Web
  "html"          = "HTML",
  "html5"         = "HTML",
  "css"           = "CSS",
  "css3"          = "CSS",
  "angular"       = "Angular",
  "angularjs"     = "Angular",
  "vue"           = "Vue.js",
  "vue.js"        = "Vue.js",
  "vuejs"         = "Vue.js",
  "sass"          = "Sass",
  "scss"          = "Sass",
  
  # Other
  "ci/cd"         = "CI/CD",
  "cicd"          = "CI/CD",
  "rest api"      = "REST API",
  "restful"       = "REST API",
  "agile"         = "Agile",
  "scrum"         = "Agile",
  "deep learning" = "Deep Learning",
  "dl"            = "Deep Learning",
  "nlp"           = "NLP",
  "natural language processing" = "NLP",
  "computer vision" = "Computer Vision",
  "cv"            = "Computer Vision",
  "excel"         = "Excel",
  "figma"         = "Figma",
  "linux"         = "Linux",
  "bash"          = "Bash",
  "jenkins"       = "Jenkins",
  "ansible"       = "Ansible",
  "terraform"     = "Terraform",
  "redis"         = "Redis",
  "spark"         = "Spark",
  "hadoop"        = "Hadoop",
  "scikit-learn"  = "Scikit-Learn",
  "sklearn"       = "Scikit-Learn",
  "pandas"        = "Pandas",
  "numpy"         = "NumPy",
  "spring"        = "Spring",
  "spring boot"   = "Spring",
  "statistics"    = "Statistics",
  "data visualization" = "Data Visualization",
  "etl"           = "ETL",
  "monitoring"    = "Monitoring",
  "networking"    = "Networking",
  "webpack"       = "Webpack",
  "redux"         = "Redux",
  "mlops"         = "MLOps",
  "sql"           = "SQL"
)

# ------------------------------------------------------------------
# normalise_skill: look up a skill in the synonym dictionary
# ------------------------------------------------------------------
normalise_skill <- function(skill) {
  s <- str_trim(tolower(skill))
  if (s %in% names(skill_synonyms)) {
    return(skill_synonyms[[s]])
  }
  # Return original with first-letter capitalisation as fallback
  return(str_to_title(skill))
}

# ------------------------------------------------------------------
# clean_job_data: main cleaning pipeline
# ------------------------------------------------------------------
clean_job_data <- function(raw_path) {
  message("Loading raw data from: ", raw_path)
  
  df <- read_csv(raw_path, show_col_types = FALSE)
  message("Raw rows: ", nrow(df))
  
  # 1. Remove exact duplicates (keep first)
  df <- df %>% distinct(job_title, company, location, skills, description,
                         .keep_all = TRUE)
  message("After dedup: ", nrow(df))
  
  # 2. Handle dates
  df <- df %>%
    mutate(
      posted_date = as.Date(posted_date),
      year        = year(posted_date),
      month       = month(posted_date),
      quarter     = quarter(posted_date),
      year_quarter = paste0(year, "-Q", quarter)
    )
  
  # 3. Clean job titles — trim whitespace, standardise case
  df <- df %>%
    mutate(job_title = str_trim(job_title),
           job_title = str_to_title(job_title))
  
  # 4. Clean locations
  df <- df %>%
    mutate(location = str_trim(location),
           location = str_to_title(location))
  
  # 5. Handle salary: keep numeric, cap outliers
  if ("salary_lpa" %in% names(df)) {
    df <- df %>%
      mutate(salary_lpa = as.numeric(salary_lpa))
  }
  
  # 6. Clean experience
  if ("experience_years" %in% names(df)) {
    df <- df %>%
      mutate(experience_years = as.numeric(experience_years))
  }
  
  # 7. Normalise skills column
  df <- df %>%
    mutate(
      skills_clean = sapply(skills, function(s) {
        if (is.na(s) || s == "") return(NA_character_)
        individual <- str_split(s, ",")[[1]]
        normalised <- sapply(individual, normalise_skill, USE.NAMES = FALSE)
        normalised <- unique(str_trim(normalised))
        paste(normalised, collapse = ", ")
      }, USE.NAMES = FALSE)
    )
  
  # 8. Remove rows with no skills or no description
  df <- df %>%
    filter(!is.na(skills_clean), skills_clean != "",
           !is.na(description), description != "")
  
  message("After cleaning: ", nrow(df), " rows")
  
  return(df)
}

# ------------------------------------------------------------------
# save_processed_data: write cleaned data to CSV
# ------------------------------------------------------------------
save_processed_data <- function(df, output_dir = file.path("data", "processed")) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  
  output_path <- file.path(output_dir, "jobs_cleaned.csv")
  write_csv(df, output_path)
  message("Cleaned data saved to: ", output_path)
  
  return(output_path)
}

# ------------------------------------------------------------------
# Run if executed directly
# ------------------------------------------------------------------
if (sys.nframe() == 0) {
  raw_file <- file.path("data", "raw", "job_postings.csv")
  if (file.exists(raw_file)) {
    cleaned <- clean_job_data(raw_file)
    save_processed_data(cleaned)
  } else {
    message("Raw data not found. Run data/raw/generate_dataset.R first.")
  }
}
