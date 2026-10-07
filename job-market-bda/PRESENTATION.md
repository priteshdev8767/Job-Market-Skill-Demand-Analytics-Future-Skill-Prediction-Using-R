# Presentation Content

## Job Market Skill Demand Analytics & Future Skill Prediction Using R

> Use this content for your PowerPoint / Google Slides presentation.  
> Approximately 10 slides.

---

## Slide 1 — Title Slide

**Job Market Skill Demand Analytics & Future Skill Prediction Using R**

B.E. Computer Engineering  
Big Data Analytics — Mini Project  

Team Members: [Your Names]  
Guide: [Guide Name]  
Academic Year: 2025–2026  

---

## Slide 2 — Problem Statement

### The Challenge

- The technology job market evolves rapidly — new skills emerge while others decline.
- Students and professionals lack **data-driven insights** on which skills to prioritise.
- Job postings contain valuable signals about industry demand, but raw data is messy and unstructured.

### Our Goal

Build an analytics system that:
- Identifies top demanded skills from job postings
- Tracks trends over time
- Forecasts future skill demand
- Presents findings through an interactive dashboard

---

## Slide 3 — Objectives

1. Identify the **Top 20** most demanded technical skills
2. Analyse **skill demand by job role** (Data Scientist, Web Developer, DevOps, etc.)
3. Track **quarterly skill trends** — which skills are rising or declining?
4. Discover **common skill combinations** (e.g., Python + SQL, React + Node.js)
5. **Forecast** future demand using time-series models (ETS)
6. **Classify** skills as Rising, Stable, or Declining
7. Build an **interactive R Shiny dashboard** for exploration

---

## Slide 4 — Existing System vs. Proposed System

### Existing System
| Aspect              | Limitation                              |
|---------------------|-----------------------------------------|
| Job portals         | Show listings, not analytics            |
| Manual research     | Time-consuming, subjective              |
| Static reports      | Quickly outdated                        |
| No predictions      | Only show current state                 |

### Proposed System
| Aspect              | Improvement                             |
|---------------------|-----------------------------------------|
| Data-driven         | Analyse 5,000+ job postings             |
| Automated cleaning  | Normalize messy skill names             |
| Trend analysis      | Track quarterly demand over 4+ years    |
| Forecasting         | Predict next 3 quarters using ETS       |
| Interactive         | Shiny dashboard with filters & charts   |

---

## Slide 5 — Dataset

| Property       | Details                              |
|----------------|--------------------------------------|
| Type           | Synthetic (for demonstration)        |
| Records        | ~5,000 job postings                  |
| Time Span      | Jan 2021 – Jun 2025                  |
| Columns        | job_id, job_title, company, location, salary, experience, skills, posted_date, description |

**Realistic features:**
- 10 different job roles
- 40+ companies
- 60+ technical skills
- Temporal demand shifts (Python↑, C++↓)
- Messy data (typos, abbreviations, duplicates)

*In production: replace with Kaggle / LinkedIn / Naukri data*

---

## Slide 6 — Methodology / Pipeline

```
 ┌─────────────────┐
 │   Raw Dataset    │
 └────────┬────────┘
          │
 ┌────────▼────────┐
 │  Data Cleaning   │  Remove duplicates, normalize skills,
 │                   │  handle missing values, parse dates
 └────────┬────────┘
          │
 ┌────────▼────────┐
 │ Skill Extraction │  Dictionary-based matching (60+ skills)
 └────────┬────────┘
          │
 ┌────────▼────────┐
 │     Analytics    │  Top skills, Role analysis,
 │                   │  Trends, Combinations, Classification
 └────────┬────────┘
          │
 ┌────────▼────────┐
 │   Forecasting    │  ETS (Exponential Smoothing)
 │                   │  3-quarter ahead prediction
 └────────┬────────┘
          │
 ┌────────▼────────┐
 │  Shiny Dashboard │  6 interactive tabs
 └─────────────────┘
```

---

## Slide 7 — System Architecture

```
┌─────────────────────────────────────────┐
│           R Shiny Dashboard             │
│  ┌─────┬──────┬─────┬──────┬──────┐    │
│  │Dash │Skill │Role │Trend │Future│    │
│  │board│ Anal │ Anal│  s   │Skills│    │
│  └──┬──┴──┬───┴──┬──┴──┬───┴──┬───┘    │
│     │     │      │     │      │         │
│  ┌──▼─────▼──────▼─────▼──────▼──┐      │
│  │      Server + R Modules       │      │
│  │  data_cleaning.R              │      │
│  │  skill_extraction.R           │      │
│  │  analysis.R                   │      │
│  │  forecasting.R                │      │
│  └───────────────┬───────────────┘      │
│                  │                       │
│  ┌───────────────▼───────────────┐      │
│  │     CSV Data (raw/processed)  │      │
│  └───────────────────────────────┘      │
└─────────────────────────────────────────┘
```

**Technology Stack:** R, tidyverse, ggplot2, plotly, forecast, Shiny, bslib, DT

---

## Slide 8 — Dashboard Screenshots

*[Insert screenshots of your running dashboard here]*

### Tab Highlights:
- **Dashboard**: KPI cards + 4 summary charts
- **Skill Analysis**: Select any skill → demand, rank, trend, roles
- **Job Roles**: Select a role → top required skills
- **Skill Trends**: Compare up to 5 skills over time
- **Future Skills**: ETS forecast with confidence intervals

---

## Slide 9 — Key Results

### Top 5 Most Demanded Skills
| Rank | Skill        | Demand % |
|------|-------------|----------|
| 1    | Python      | ~55%     |
| 2    | JavaScript  | ~48%     |
| 3    | SQL         | ~45%     |
| 4    | Git         | ~42%     |
| 5    | React       | ~35%     |

### Key Findings
- ☑ **Cloud skills (AWS, Docker, Kubernetes)** show the strongest growth
- ☑ **Python + SQL** is the most common skill combination
- ☑ **Machine Learning** demand nearly doubled over 4 years
- ☑ **ETS forecasts** predict continued growth in cloud and ML skills
- ☑ **C++ and Angular** show relatively declining demand

*Note: Results from synthetic data — for demonstration only*

---

## Slide 10 — Conclusion & Future Scope

### Conclusion
- Successfully built a complete BDA pipeline: Data → Cleaning → Analysis → Prediction → Dashboard
- Demonstrated descriptive, diagnostic, and predictive analytics using R
- The interactive Shiny dashboard makes findings accessible and explorable
- ETS forecasting provides data-driven career guidance

### Future Scope
1. Integrate real-time job posting APIs (LinkedIn, Indeed)
2. Use NLP for automated skill extraction
3. Add salary prediction models
4. Build a career recommendation engine
5. Deploy on cloud (ShinyApps.io / AWS)

### Thank You!
*Questions?*
