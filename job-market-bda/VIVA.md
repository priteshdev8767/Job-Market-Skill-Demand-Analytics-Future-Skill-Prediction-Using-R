# Viva Questions & Answers

## Job Market Skill Demand Analytics & Future Skill Prediction Using R

---

### Q1. Why did you choose R for this project?

**Answer:** R is a programming language specifically designed for statistical computing and data analysis. It has excellent packages for data manipulation (tidyverse), visualization (ggplot2, plotly), time-series forecasting (forecast), and building interactive dashboards (Shiny). Since our project is focused on Big Data Analytics — data cleaning, exploratory analysis, and prediction — R is the most natural and efficient choice. Additionally, R Shiny allows us to build a complete web dashboard without needing any other web technology.

---

### Q2. Why is this project relevant to Big Data Analytics?

**Answer:** Big Data Analytics involves processing large datasets to extract meaningful insights and patterns. This project demonstrates all three pillars of analytics:
1. **Descriptive Analytics** — What skills are most demanded? (top skills, counts)
2. **Diagnostic Analytics** — Why do certain skills appear together? (combinations, trends)
3. **Predictive Analytics** — What will future demand look like? (ETS forecasting)

The dataset contains 5,000+ records with multiple attributes, and we perform skill extraction, trend analysis, and time-series forecasting — all core BDA concepts.

---

### Q3. What problem does this project solve?

**Answer:** The technology job market changes rapidly, and students/professionals often don't know which skills to learn. This project analyses job posting data to objectively answer: Which skills are most demanded? Which are growing? Which are declining? What skills commonly appear together? And what is the predicted future demand? This helps in data-driven career planning.

---

### Q4. What dataset did you use?

**Answer:** We used a synthetic dataset of approximately 5,000 job postings spanning from January 2021 to June 2025. Each record includes job title, company, location, salary, experience, skills, posting date, and description. The dataset was generated using R with realistic patterns — skills follow real-world demand distributions, and temporal trends simulate growing and declining technologies. In a production system, this would be replaced with real data from platforms like Kaggle, LinkedIn, or Naukri.

---

### Q5. How did you clean the data?

**Answer:** Data cleaning involved five main steps:
1. **Duplicate removal** — Removed exact duplicate records using `distinct()`.
2. **Missing value handling** — Removed rows with missing skills or descriptions; retained missing salaries.
3. **Date parsing** — Converted dates to R Date objects and extracted year, quarter.
4. **Skill name normalization** — Used a dictionary of 80+ synonym mappings to standardize names (e.g., "JS" → "JavaScript", "React.js" → "React", "ML" → "Machine Learning").
5. **Text cleaning** — Trimmed whitespace and standardized casing for titles and locations.

---

### Q6. How were skills extracted from job descriptions?

**Answer:** We used a dictionary-based approach. We defined a master skill dictionary of 60+ technical skills organized into 7 categories (Programming, Web, Databases, Cloud/DevOps, Data/AI, BI, Methodologies). For each job posting, the cleaned skills column was split by commas, and each skill was matched against the dictionary using the synonym mapping. The result is a long-format table where each row represents one (job, skill) pair.

---

### Q7. What is descriptive analytics? How is it demonstrated?

**Answer:** Descriptive analytics answers "What happened?" using historical data summarization. In our project:
- **Top Skills bar chart** shows which skills appear in the most job postings
- **Category pie chart** shows the distribution across skill categories
- **Job Role analysis** shows which skills are needed for each role
- **KPI cards** summarize total jobs, skills, and roles

These are all summaries of existing data — the definition of descriptive analytics.

---

### Q8. What is predictive analytics? How is it demonstrated?

**Answer:** Predictive analytics uses statistical models to forecast future outcomes based on historical patterns. In our project, we use Exponential Smoothing (ETS) to forecast skill demand for the next 3 quarters. For example, if Python's demand has been increasing from 15% to 28% over 4 years, the model predicts it will continue to a certain level. We also provide confidence intervals showing the range of uncertainty.

---

### Q9. How does skill trend analysis work?

**Answer:** We compute the demand percentage of each skill per quarter:

`Demand % = (Jobs requiring skill in quarter / Total jobs in quarter) × 100`

By plotting this across quarters, we get a trend line. We then calculate the growth rate by comparing the average demand in the first half vs. the second half of the time period:

`Growth Rate = ((Late Average - Early Average) / Early Average) × 100`

Skills with growth rate > 10% are classified as "Rising", between -10% and 10% as "Stable", and below -10% as "Declining".

---

### Q10. Which forecasting algorithm was used and why?

**Answer:** We used **Exponential Smoothing (ETS)** from the R `forecast` package. ETS was chosen because:
1. It works well with short time-series data (we have ~18 quarterly points per skill)
2. It automatically selects the best combination of Error, Trend, and Seasonality components
3. It provides confidence intervals for uncertainty quantification
4. It is simple, interpretable, and computationally efficient
5. It is a standard method taught in time-series analysis courses

If ETS fails (insufficient data), we fall back to simple linear regression as a backup.

---

### Q11. What is ARIMA?

**Answer:** ARIMA stands for **Auto-Regressive Integrated Moving Average**. It is a time-series forecasting method that combines:
- **AR (Auto-Regressive)**: Uses past values to predict future values
- **I (Integrated)**: Differencing to make the series stationary
- **MA (Moving Average)**: Uses past forecast errors

ARIMA is characterized by three parameters (p, d, q). In our project, we primarily use ETS, but the `forecast` package also supports ARIMA as an alternative. Both are standard time-series methods suitable for this type of data.

---

### Q12. What is Exponential Smoothing?

**Answer:** Exponential Smoothing is a family of forecasting methods that assign exponentially decreasing weights to past observations. Recent data points get more weight than older ones. The ETS framework has three components:
- **E (Error)**: Additive or Multiplicative
- **T (Trend)**: None, Additive, or Damped
- **S (Seasonality)**: None, Additive, or Multiplicative

The R `ets()` function automatically selects the best combination using AIC (Akaike Information Criterion).

---

### Q13. What is R Shiny?

**Answer:** R Shiny is an R package for building interactive web applications directly from R code. It has two main components:
1. **UI (User Interface)**: Defines the layout — inputs (dropdowns, sliders) and outputs (charts, tables)
2. **Server**: Contains the logic — reactive computations, plot generation, data filtering

Shiny applications run in a web browser but are written entirely in R. They are commonly used for data dashboards, interactive reports, and analytics tools. We used `bslib` for Bootstrap 5 theming and `plotly` for interactive charts.

---

### Q14. What are the main tabs in your dashboard?

**Answer:** The dashboard has 6 tabs:
1. **Dashboard**: Overview with KPI cards and summary charts
2. **Skill Analysis**: Deep-dive into a selected skill — demand, rank, trend, related roles
3. **Job Roles**: Analyse skills required for a specific job role
4. **Skill Trends**: Compare demand trends of multiple skills over time
5. **Future Skills**: Forecast viewer with confidence intervals and classification
6. **About**: Project description, methodology, and limitations

---

### Q15. How does the skill combination analysis work?

**Answer:** For each job posting, we extract its list of skills and generate all possible pairs using `combn()`. For example, if a job requires {Python, SQL, Docker}, the pairs are: Python+SQL, Python+Docker, SQL+Docker. We then count how many times each pair appears across all jobs. The top 20 most frequent pairs are displayed. This helps identify which skills employers commonly expect together (e.g., Python+SQL, React+JavaScript).

---

### Q16. What is the difference between ETS and ARIMA?

**Answer:**
| Feature        | ETS                              | ARIMA                           |
|----------------|----------------------------------|---------------------------------|
| Approach       | Weighted exponential smoothing   | Auto-regression + Moving average|
| Stationarity   | Does not require                 | Requires (uses differencing)    |
| Components     | Error, Trend, Seasonality        | AR, I, MA orders (p, d, q)     |
| Selection      | Minimizes AIC across 30 models   | Uses auto.arima() for selection |
| Interpretability| Intuitive (recent data matters more)| More mathematical             |

Both are valid for this project. ETS is often preferred for short series with clear trend.

---

### Q17. What are the limitations of your project?

**Answer:**
1. The dataset is synthetic — real-world results may differ significantly.
2. Skill extraction is dictionary-based, so new/niche skills not in the dictionary are missed.
3. Forecasting assumes past trends continue; sudden market changes (e.g., new technology breakthrough) are not captured.
4. The project does not deeply analyse geographic or industry-specific variations.
5. Salary analysis is basic due to missing values in the dataset.

---

### Q18. What is the future scope of this project?

**Answer:**
1. **Real data integration** — Connect to LinkedIn, Indeed, or Naukri APIs for live data.
2. **NLP-based extraction** — Use Named Entity Recognition to automatically discover skills from unstructured descriptions.
3. **Salary prediction** — Build regression models to predict salary based on skills and experience.
4. **Career recommendation** — Suggest learning paths based on current skill gaps.
5. **Cloud deployment** — Host on ShinyApps.io or AWS for public access.
6. **Real-time analytics** — Stream new job postings for live dashboard updates.

---

### Q19. How is the skill classification done?

**Answer:** Skills are classified based on their computed growth rate, which compares demand in the first half of the data to the second half:

| Growth Rate      | Classification    |
|------------------|-------------------|
| > 15%            | Rising Demand     |
| 0% to 15%        | Moderately Rising |
| -10% to 0%       | Stable Demand     |
| < -10%           | Declining Demand  |

This classification is **computed from the data**, not manually assigned. The forecast model's prediction also classifies skills: if the forecasted demand is higher than current, it's "Rising"; if similar, "Stable"; if lower, "Declining".

---

### Q20. What packages did you use and why?

**Answer:**
| Package    | Purpose                                         |
|------------|--------------------------------------------------|
| tidyverse  | Data manipulation (dplyr, tidyr, readr, stringr, ggplot2) |
| lubridate  | Easy date and time parsing                       |
| plotly     | Convert ggplot2 charts to interactive (hover, zoom) |
| forecast   | Time-series models (ETS, ARIMA) and predictions  |
| shiny      | Build the interactive web dashboard              |
| bslib      | Modern Bootstrap 5 theming for Shiny             |
| DT         | Render interactive, sortable, searchable tables  |
| scales     | Format chart axes (percentages, commas)          |
| RColorBrewer | Professional colour palettes for charts        |
| caret      | Machine learning framework (available for extensions) |

---

### Bonus Q: How would you improve accuracy with a real dataset?

**Answer:** With a real dataset:
1. Use more data points (years of historical data) for better forecasting.
2. Apply NLP techniques for robust skill extraction.
3. Use ARIMA with seasonal decomposition for monthly data.
4. Cross-validate forecasts using rolling-window evaluation.
5. Incorporate external features (e.g., economic indicators, technology trends) as covariates.
6. Use ensemble methods combining ETS, ARIMA, and Prophet for more robust predictions.
