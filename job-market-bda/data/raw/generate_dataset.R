# ============================================================
# generate_dataset.R — Create a realistic synthetic dataset
# ============================================================
# This script generates a synthetic job-posting dataset for
# demonstration purposes. In a real project you would replace
# this with an actual dataset (e.g., from Kaggle).
#
# The generated data mimics realistic patterns:
#   • Skill frequencies follow real-world proportions
#   • Job titles map to plausible skill sets
#   • Posting dates span 2021-01 to 2025-06
#   • Salaries vary by role and experience
# ============================================================

library(tidyverse)
library(lubridate)

set.seed(42)  # Reproducibility

# ------ Configuration ------
N_JOBS <- 5000   # Number of job postings to generate

# ------ Job Role Definitions ------
# Each role has a base set of "core" skills and optional skills
role_definitions <- list(
  "Software Developer" = list(
    core = c("Java", "Python", "JavaScript", "Git", "SQL"),
    optional = c("C++", "TypeScript", "Docker", "AWS", "React",
                 "Node.js", "PostgreSQL", "MongoDB", "Kubernetes",
                 "Spring", "Linux", "REST API", "Agile")
  ),
  "Data Analyst" = list(
    core = c("Python", "SQL", "Excel", "Power BI", "Tableau"),
    optional = c("R", "Statistics", "Machine Learning", "Pandas",
                 "Data Visualization", "Git", "PostgreSQL", "MySQL",
                 "ETL", "Agile")
  ),
  "Data Scientist" = list(
    core = c("Python", "Machine Learning", "SQL", "Statistics", "TensorFlow"),
    optional = c("R", "PyTorch", "Deep Learning", "NLP", "Pandas",
                 "Scikit-Learn", "AWS", "Docker", "Spark",
                 "Data Visualization", "Git", "Tableau", "Power BI")
  ),
  "Web Developer" = list(
    core = c("HTML", "CSS", "JavaScript", "React", "Git"),
    optional = c("TypeScript", "Node.js", "Angular", "Vue.js",
                 "MongoDB", "SQL", "Docker", "AWS", "REST API",
                 "Agile", "Figma", "Sass")
  ),
  "Frontend Developer" = list(
    core = c("HTML", "CSS", "JavaScript", "React", "TypeScript"),
    optional = c("Angular", "Vue.js", "Sass", "Figma", "Git",
                 "REST API", "Node.js", "Agile", "Webpack",
                 "Redux")
  ),
  "Backend Developer" = list(
    core = c("Java", "Python", "SQL", "Node.js", "Git"),
    optional = c("PostgreSQL", "MongoDB", "Docker", "AWS",
                 "Kubernetes", "Spring", "REST API", "Redis",
                 "Linux", "Agile", "C++", "Go")
  ),
  "DevOps Engineer" = list(
    core = c("Docker", "Kubernetes", "AWS", "Linux", "Git"),
    optional = c("Azure", "Terraform", "CI/CD", "Python",
                 "Jenkins", "Ansible", "Bash", "Monitoring",
                 "Networking", "Agile")
  ),
  "Full Stack Developer" = list(
    core = c("JavaScript", "React", "Node.js", "SQL", "Git"),
    optional = c("TypeScript", "Python", "MongoDB", "PostgreSQL",
                 "Docker", "AWS", "HTML", "CSS", "REST API",
                 "Angular", "Agile")
  ),
  "Machine Learning Engineer" = list(
    core = c("Python", "Machine Learning", "TensorFlow", "SQL", "Docker"),
    optional = c("PyTorch", "Deep Learning", "AWS", "Kubernetes",
                 "Scikit-Learn", "Spark", "NLP", "Computer Vision",
                 "Git", "Statistics", "MLOps")
  ),
  "Cloud Engineer" = list(
    core = c("AWS", "Azure", "Docker", "Linux", "Kubernetes"),
    optional = c("Terraform", "Python", "CI/CD", "Networking",
                 "Git", "Bash", "Ansible", "Jenkins",
                 "Monitoring", "SQL", "Agile")
  )
)

# Role probability weights (some roles are more common)
role_weights <- c(
  "Software Developer" = 0.18,
  "Data Analyst"       = 0.12,
  "Data Scientist"     = 0.10,
  "Web Developer"      = 0.12,
  "Frontend Developer" = 0.08,
  "Backend Developer"  = 0.10,
  "DevOps Engineer"    = 0.08,
  "Full Stack Developer" = 0.10,
  "Machine Learning Engineer" = 0.06,
  "Cloud Engineer"     = 0.06
)

# ------ Company Names ------
companies <- c(
  "TechCorp Solutions", "DataWave Analytics", "CloudNine Systems",
  "InnovateTech", "ByteForge Labs", "QuantumSoft", "DigitalEdge",
  "CodeCraft Technologies", "Nexus IT Services", "Pinnacle Systems",
  "FutureTech India", "SmartLogic Solutions", "AppVenture Inc",
  "DataPrime Analytics", "SkyNet Solutions", "CyberTech Global",
  "AlphaCode Labs", "TechVista Solutions", "NetSphere Technologies",
  "PrimeStack Solutions", "DevMatrix Corp", "InfoBridge Systems",
  "TechPulse Innovations", "CoreLogic Technologies", "ZenithTech",
  "Accenture", "TCS", "Infosys", "Wipro", "HCL Technologies",
  "Cognizant", "Tech Mahindra", "Capgemini", "IBM India",
  "Microsoft India", "Google India", "Amazon India", "Flipkart",
  "Paytm", "Zomato", "PhonePe", "Swiggy", "Razorpay",
  "Freshworks", "Zoho"
)

# ------ Locations ------
locations <- c(
  "Bangalore", "Mumbai", "Hyderabad", "Pune", "Chennai",
  "Delhi NCR", "Noida", "Gurgaon", "Kolkata", "Ahmedabad",
  "Jaipur", "Kochi", "Remote", "Hybrid - Bangalore",
  "Hybrid - Mumbai", "Hybrid - Pune"
)
location_weights <- c(
  0.22, 0.15, 0.14, 0.12, 0.08,
  0.06, 0.04, 0.04, 0.03, 0.02,
  0.01, 0.01, 0.04, 0.02,
  0.01, 0.01
)

# ------ Salary Ranges by Role (LPA = Lakhs Per Annum) ------
salary_ranges <- list(
  "Software Developer"         = c(4, 25),
  "Data Analyst"               = c(3, 18),
  "Data Scientist"             = c(6, 30),
  "Web Developer"              = c(3, 18),
  "Frontend Developer"         = c(4, 20),
  "Backend Developer"          = c(5, 25),
  "DevOps Engineer"            = c(6, 28),
  "Full Stack Developer"       = c(5, 24),
  "Machine Learning Engineer"  = c(8, 35),
  "Cloud Engineer"             = c(6, 30)
)

# ------ Experience Ranges by Role ------
exp_ranges <- list(
  "Software Developer"         = c(0, 12),
  "Data Analyst"               = c(0, 8),
  "Data Scientist"             = c(1, 10),
  "Web Developer"              = c(0, 8),
  "Frontend Developer"         = c(0, 8),
  "Backend Developer"          = c(1, 10),
  "DevOps Engineer"            = c(2, 12),
  "Full Stack Developer"       = c(1, 10),
  "Machine Learning Engineer"  = c(1, 12),
  "Cloud Engineer"             = c(2, 12)
)

# ------ Temporal trend: skill popularity shifts over time ------
# Skills whose demand grows over time (multiplier increases with date)
growing_skills  <- c("Python", "AWS", "Docker", "Kubernetes", "Machine Learning",
                     "TypeScript", "React", "TensorFlow", "Azure", "Deep Learning",
                     "PyTorch", "Go", "Terraform", "MLOps", "CI/CD", "Power BI")
declining_skills <- c("C++", "Java", "Angular", "Jenkins", "Bash", "Excel")

# ------ Generate Posting Dates ------
start_date <- ymd("2021-01-01")
end_date   <- ymd("2025-06-30")
date_range <- as.numeric(end_date - start_date)

# ------ Helper: generate a job description snippet ------
make_description <- function(role, skills) {
  intro_templates <- c(
    paste0("We are looking for a skilled ", role, " to join our team."),
    paste0("Hiring an experienced ", role, " for exciting projects."),
    paste0("Join us as a ", role, " and work on cutting-edge technology."),
    paste0("Seeking a passionate ", role, " to build innovative solutions."),
    paste0("Opportunity for a talented ", role, " in a fast-paced environment.")
  )
  
  skill_str <- paste(skills, collapse = ", ")
  
  mid_templates <- c(
    paste0("Required skills: ", skill_str, "."),
    paste0("Must have experience with ", skill_str, "."),
    paste0("Proficiency in ", skill_str, " is required."),
    paste0("The ideal candidate knows ", skill_str, ".")
  )
  
  end_templates <- c(
    "Strong problem-solving and communication skills preferred.",
    "Ability to work in agile teams and deliver quality code.",
    "Good understanding of software development lifecycle.",
    "Experience with version control and collaborative tools.",
    "Strong analytical mindset and attention to detail."
  )
  
  paste(
    sample(intro_templates, 1),
    sample(mid_templates, 1),
    sample(end_templates, 1)
  )
}

# ------ Generate Dataset ------
message("Generating ", N_JOBS, " synthetic job postings...")

jobs <- tibble(
  job_id     = seq_len(N_JOBS),
  job_title  = character(N_JOBS),
  company    = character(N_JOBS),
  location   = character(N_JOBS),
  salary_lpa = numeric(N_JOBS),
  experience_years = numeric(N_JOBS),
  posted_date = as.Date(character(N_JOBS)),
  skills     = character(N_JOBS),
  description = character(N_JOBS)
)

roles_vec <- names(role_definitions)

for (i in seq_len(N_JOBS)) {
  # Pick role
  role <- sample(roles_vec, 1, prob = role_weights)
  
  # Pick date
  post_date <- start_date + sample(0:date_range, 1)
  
  # Core skills (pick 3-5 from core)
  core <- role_definitions[[role]]$core
  n_core <- min(length(core), sample(3:5, 1))
  picked_core <- sample(core, n_core)
  
  # Optional skills (pick 2-5 from optional)
  opt <- role_definitions[[role]]$optional
  n_opt <- sample(2:5, 1)
  picked_opt <- sample(opt, min(n_opt, length(opt)))
  
  all_skills <- unique(c(picked_core, picked_opt))
  
  # Temporal adjustment: favour growing skills for later dates
  time_factor <- as.numeric(post_date - start_date) / date_range  # 0 → 1
  
  # Increase probability of keeping growing skills later
  keep <- sapply(all_skills, function(s) {
    if (s %in% growing_skills) {
      runif(1) < (0.5 + 0.5 * time_factor)
    } else if (s %in% declining_skills) {
      runif(1) < (0.9 - 0.4 * time_factor)
    } else {
      runif(1) < 0.8
    }
  })
  
  final_skills <- all_skills[keep]
  if (length(final_skills) < 2) final_skills <- all_skills[1:min(3, length(all_skills))]
  
  # Salary
  sal_range <- salary_ranges[[role]]
  exp_range <- exp_ranges[[role]]
  exp_yrs   <- round(runif(1, exp_range[1], exp_range[2]), 1)
  base_sal  <- runif(1, sal_range[1], sal_range[2])
  salary    <- round(base_sal + exp_yrs * 0.5, 1)  # Higher exp → higher salary
  
  # Occasionally make salary NA (10% missing)
  if (runif(1) < 0.10) salary <- NA
  
  # Fill row
  jobs$job_title[i]        <- role
  jobs$company[i]          <- sample(companies, 1)
  jobs$location[i]         <- sample(locations, 1, prob = location_weights)
  jobs$salary_lpa[i]       <- salary
  jobs$experience_years[i] <- exp_yrs
  jobs$posted_date[i]      <- post_date
  jobs$skills[i]           <- paste(final_skills, collapse = ", ")
  jobs$description[i]      <- make_description(role, final_skills)
}

# ------ Add some noise: duplicate rows, messy skill names ------
# Add ~3% duplicates
n_dup <- round(N_JOBS * 0.03)
dup_idx <- sample(seq_len(N_JOBS), n_dup, replace = TRUE)
jobs <- bind_rows(jobs, jobs[dup_idx, ])

# Introduce some messy skill names in ~8% of rows
messy_map <- c(
  "JavaScript" = "Java Script",
  "JavaScript" = "JS",
  "Machine Learning" = "ML",
  "Artificial Intelligence" = "AI",
  "React" = "React.js",
  "React" = "ReactJS",
  "Node.js" = "NodeJS",
  "TypeScript" = "Typescript",
  "PostgreSQL" = "Postgres",
  "MongoDB" = "Mongo DB",
  "Kubernetes" = "K8s",
  "Power BI" = "PowerBI",
  "TensorFlow" = "Tensorflow"
)

n_messy <- round(nrow(jobs) * 0.08)
messy_idx <- sample(seq_len(nrow(jobs)), n_messy)
for (idx in messy_idx) {
  pair <- sample(seq_along(messy_map), 1)
  clean_name <- names(messy_map)[pair]
  dirty_name <- messy_map[pair]
  jobs$skills[idx] <- str_replace(jobs$skills[idx], fixed(clean_name), dirty_name)
  jobs$description[idx] <- str_replace(jobs$description[idx], fixed(clean_name), dirty_name)
}

# Shuffle rows
jobs <- jobs %>% sample_frac(1) %>% mutate(job_id = row_number())

# ------ Save ------
output_dir <- file.path("data", "raw")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

write_csv(jobs, file.path(output_dir, "job_postings.csv"))

message("Dataset saved to data/raw/job_postings.csv")
message("Total rows: ", nrow(jobs))
message("Columns: ", paste(names(jobs), collapse = ", "))
