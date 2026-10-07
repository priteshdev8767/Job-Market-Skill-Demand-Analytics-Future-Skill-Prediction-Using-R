# Job Market Skill Demand Analytics & Future Skill Prediction Using R

> **B.E. Computer Engineering — Big Data Analytics Mini Project**

---

## 1. Problem Statement

The technology job market is evolving rapidly. New skills emerge, existing skills grow or decline in demand, and employers increasingly require multi-skill candidates. Students and professionals lack a data-driven way to understand which technical skills to prioritise for career growth.

This project analyses a dataset of job postings to identify the most demanded skills, track their trends over time, discover common skill combinations, and forecast future demand using time-series methods — all presented through an interactive R Shiny dashboard.

---

## 2. Objectives

1. **Identify** the top 20 most demanded technical skills across job postings.
2. **Analyse** skill demand differences across job roles (e.g., Data Scientist vs. Web Developer).
3. **Track** quarterly trends in skill demand to detect rising and declining skills.
4. **Discover** commonly co-occurring skill pairs in job descriptions.
5. **Forecast** future skill demand using Exponential Smoothing (ETS).
6. **Classify** skills as Rising, Stable, or Declining based on computed metrics.
7. **Visualise** all findings through an interactive Shiny dashboard.

---

## 3. Dataset

| Property       | Details                                      |
|----------------|----------------------------------------------|
| **Type**       | Synthetic (generated for demonstration)      |
| **Size**       | ~5,000 job postings                          |
| **Time Span**  | January 2021 – June 2025                     |
| **Columns**    | job_id, job_title, company, location, salary_lpa, experience_years, posted_date, skills, description |

The dataset simulates realistic patterns including:
- Temporal skill-demand shifts (e.g., Python growing, C++ declining)
- Messy/inconsistent skill names (e.g., "JS", "Java Script", "React.js")
- Missing salary values (~10%)
- Duplicate records (~3%)

> **Note:** In a production setting, replace this with a real dataset from Kaggle, LinkedIn Jobs, Glassdoor, or Naukri.

---

## 4. Technology Stack

| Category          | Technologies                          |
|-------------------|---------------------------------------|
| Language          | R                                     |
| Data Processing   | tidyverse, dplyr, tidyr, readr, stringr, lubridate |
| Visualization     | ggplot2, plotly                       |
| Text Processing   | tidytext, stringr                     |
| Forecasting       | forecast (ETS / ARIMA)                |
| Machine Learning  | caret                                 |
| Dashboard         | Shiny, bslib, DT                      |
| Utilities         | scales, RColorBrewer                  |

---

## 5. Methodology

```
Job Posting Dataset (CSV)
        │
        ▼
   Data Cleaning
   • Remove duplicates
   • Handle missing values
   • Normalize skill names
   • Parse dates
        │
        ▼
   Skill Extraction
   • Dictionary-based matching
   • Categorize skills
   • Build long-format table
        │
        ▼
   Exploratory Data Analysis
   • Top skills ranking
   • Category distribution
   • Role-wise analysis
        │
        ▼
   Skill Trend Analysis
   • Quarterly demand %
   • Growth rate calculation
   • Rising/Stable/Declining
        │
        ▼
   Skill Combination Analysis
   • Co-occurrence pairs
   • Top combinations
        │
        ▼
   Future Skill Prediction
   • ETS forecasting
   • Confidence intervals
   • 3-quarter forecast
        │
        ▼
   R Shiny Dashboard
   • 6 interactive tabs
   • KPI cards
   • Plotly charts
   • Data tables
```

---

## 6. System Architecture

```
┌──────────────────────────────────────────────────┐
│                 R Shiny Dashboard                 │
│  ┌──────┬───────┬──────┬───────┬───────┬───────┐ │
│  │Dash- │Skill  │Job   │Skill  │Future │About  │ │
│  │board │Analy. │Roles │Trends │Skills │       │ │
│  └──┬───┴───┬───┴──┬───┴───┬───┴───┬───┴───────┘ │
│     │       │      │       │       │              │
│  ┌──▼───────▼──────▼───────▼───────▼──┐           │
│  │         Server Logic               │           │
│  │  • Reactive computations           │           │
│  │  • Plot generation (ggplot2+Plotly)│           │
│  │  • Table rendering (DT)            │           │
│  └──────────────┬─────────────────────┘           │
│                 │                                  │
│  ┌──────────────▼─────────────────────┐           │
│  │          R Modules                  │           │
│  │  ┌──────────┐  ┌────────────────┐  │           │
│  │  │  data_   │  │   skill_       │  │           │
│  │  │ cleaning │  │  extraction    │  │           │
│  │  └──────────┘  └────────────────┘  │           │
│  │  ┌──────────┐  ┌────────────────┐  │           │
│  │  │ analysis │  │  forecasting   │  │           │
│  │  └──────────┘  └────────────────┘  │           │
│  └──────────────┬─────────────────────┘           │
│                 │                                  │
│  ┌──────────────▼─────────────────────┐           │
│  │           Data Layer                │           │
│  │   data/raw/  →  data/processed/     │           │
│  └─────────────────────────────────────┘           │
└──────────────────────────────────────────────────┘
```

---

## 7. Data Preprocessing

### 7.1 Duplicate Removal
Exact duplicates based on job_title, company, location, skills, and description are removed using `dplyr::distinct()`.

### 7.2 Missing Value Handling
- Rows with missing skills or descriptions are removed.
- Salary values with `NA` are retained for analysis where salary is not required.

### 7.3 Date Parsing
Dates are converted to R `Date` objects. Year, month, quarter, and year-quarter columns are derived using `lubridate`.

### 7.4 Skill Name Normalization
A dictionary of 80+ synonym mappings converts messy skill names to canonical forms:
- `"JS"`, `"Java Script"` → `"JavaScript"`
- `"React.js"`, `"ReactJS"` → `"React"`
- `"ML"` → `"Machine Learning"`
- `"K8s"` → `"Kubernetes"`
- `"Postgres"` → `"PostgreSQL"`

---

## 8. Skill Extraction

Skills are extracted using a curated dictionary of 60+ technical skills organized into 7 categories:

| Category             | Example Skills                                  |
|----------------------|-------------------------------------------------|
| Programming Languages| Python, Java, JavaScript, C++, TypeScript, Go   |
| Web Development      | HTML, CSS, React, Angular, Node.js, Vue.js       |
| Databases            | SQL, MySQL, PostgreSQL, MongoDB, Redis           |
| Cloud & DevOps       | AWS, Azure, Docker, Kubernetes, Git, Terraform   |
| Data & AI            | Machine Learning, TensorFlow, PyTorch, NLP, Spark|
| BI & Analytics       | Power BI, Tableau, Excel                         |
| Methodologies        | Agile, Spring                                    |

---

## 9. Analytics

### Analysis 1 — Top Skills
Ranks skills by the number of job postings and demand percentage.

### Analysis 2 — Skills by Job Role
Shows the top 15 most demanded skills for each job role (e.g., Software Developer, Data Scientist).

### Analysis 3 — Skill Trends
Computes quarterly demand percentages and growth rates to identify rising, stable, and declining skills.

### Analysis 4 — Skill Combinations
Uses pairwise co-occurrence analysis to find the top 20 skill pairs that appear together most frequently.

### Analysis 5 — Skill Classification
Classifies skills based on computed growth rates:
- **Rising Demand**: Growth rate > 15%
- **Moderately Rising**: 0% < Growth rate ≤ 15%
- **Stable Demand**: -10% < Growth rate ≤ 0%
- **Declining Demand**: Growth rate ≤ -10%

---

## 10. Forecasting

### Algorithm: Exponential Smoothing (ETS)

ETS was chosen because:
- Works well with short quarterly time-series data
- Automatically selects the best error, trend, and seasonality components
- Provides confidence intervals
- Simple and interpretable (important for a BDA mini project)

### Process
1. Build a quarterly time-series object (`ts()`) for each skill
2. Fit an ETS model using `forecast::ets()`
3. Forecast 3 quarters ahead with 80% and 95% confidence intervals
4. If ETS fails (insufficient data), fall back to linear trend regression

### Output
- Historical demand line
- Forecast line with dashed styling
- Shaded confidence interval region
- Classification: Rising / Stable / Declining

---

## 11. Dashboard

The Shiny dashboard has 6 tabs:

| Tab           | Content                                                  |
|---------------|----------------------------------------------------------|
| **Dashboard** | KPI cards (Total Jobs, Skills, Top Skill, Fastest Growing, Roles), Top Skills bar chart, Category pie chart, Combinations chart, Classification chart |
| **Skill Analysis** | Select a skill → Demand %, Rank, Category, Trend direction, Trend chart, Roles chart |
| **Job Roles** | Select a role → Top skills bar chart, Demand table, Job count |
| **Skill Trends** | Select up to 5 skills → Multi-line trend comparison, Growth rate table with color coding |
| **Future Skills** | Select a skill → Forecast chart with confidence intervals, Model info, Classification, Summary table |
| **About** | Project description, methodology, limitations, future scope |

---

## 12. Results

Key findings from the synthetic dataset:

- **Most demanded skills**: Python, JavaScript, SQL, Git, React (typical of real-world data)
- **Fastest growing**: Skills like Docker, Kubernetes, and Machine Learning show strong upward trends
- **Declining**: C++ and Angular show relatively lower growth
- **Top combinations**: Python + SQL, React + JavaScript, Docker + AWS
- **Forecasts**: ETS models predict continued growth for cloud and ML skills

> **Note:** These are results from synthetic data. Real datasets will produce different findings.

---

## 13. Limitations

1. The dataset is synthetic and for demonstration only.
2. Skill extraction is dictionary-based — it may miss niche or emerging skills not in the dictionary.
3. Time-series forecasting assumes past patterns continue, which may not hold due to external events.
4. The project does not deeply analyze salary correlations or geographic factors.
5. NLP-based extraction would be more robust but is beyond mini-project scope.

---

## 14. Future Scope

1. Integrate with real job-posting APIs (LinkedIn, Indeed, Glassdoor, Naukri).
2. Use NLP (Named Entity Recognition) for automatic skill extraction.
3. Add salary prediction models.
4. Build a career recommendation engine.
5. Deploy as a cloud-hosted web application (ShinyApps.io or AWS).
6. Add real-time data ingestion for live trend tracking.

---

## 15. Installation

### Prerequisites
- **R** (version 4.1 or later)
- **RStudio** (recommended IDE)

### Steps

```r
# 1. Clone or download the project
# 2. Open the project folder in RStudio
# 3. Set working directory to the project root

# 4. Install required packages
source("requirements.R")

# 5. Generate the sample dataset (if not present)
source("data/raw/generate_dataset.R")

# 6. Run the Shiny app
shiny::runApp()
```

---

## 16. How to Run

```bash
# Option 1: From RStudio
# Open app.R → Click "Run App" button

# Option 2: From R console
setwd("path/to/job-market-bda")
shiny::runApp()

# Option 3: From command line
Rscript -e "shiny::runApp('path/to/job-market-bda')"
```

The app will:
1. Check if the raw dataset exists; if not, generate it automatically.
2. Check if cleaned data exists; if not, run the cleaning pipeline.
3. Perform all analytics and forecasting.
4. Launch the interactive dashboard in your browser.

---

## 17. Project Structure

```
job-market-bda/
│
├── app.R                        # Main Shiny application
│
├── data/
│   ├── raw/
│   │   ├── generate_dataset.R   # Dataset generation script
│   │   └── job_postings.csv     # Raw dataset (generated)
│   └── processed/
│       └── jobs_cleaned.csv     # Cleaned dataset (generated)
│
├── R/
│   ├── data_cleaning.R          # Data preprocessing functions
│   ├── skill_extraction.R       # Skill dictionary & extraction
│   ├── analysis.R               # Core analytics (5 analyses)
│   └── forecasting.R            # ETS forecasting functions
│
├── outputs/                     # (For exported charts/reports)
│
├── requirements.R               # Package installation script
├── README.md                    # Project documentation
├── VIVA.md                      # Viva questions & answers
└── PRESENTATION.md              # Presentation slide content
```

---

**Developed as a B.E. Computer Engineering Mini Project for Big Data Analytics**
