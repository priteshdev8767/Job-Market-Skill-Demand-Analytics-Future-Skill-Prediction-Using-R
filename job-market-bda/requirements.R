# ============================================================
# requirements.R — Install and load all required R packages
# Job Market Skill Demand Analytics & Future Skill Prediction
# ============================================================

# List of required packages
required_packages <- c(
  # Data processing
  "tidyverse",    # Includes dplyr, tidyr, readr, stringr, ggplot2, purrr, tibble
  "lubridate",    # Date handling
  
  # Visualization
  "plotly",       # Interactive plots
  
  # Text processing
  "tidytext",     # Text mining helpers
  
  # Machine Learning / Forecasting
  "caret",        # ML framework
  "forecast",     # Time-series forecasting (ARIMA, ETS)
  
  # Dashboard
  "shiny",        # Web app framework
  "bslib",        # Bootstrap themes for Shiny
  "DT",           # Interactive data tables
  
  # Utilities
  "scales",       # Formatting axes/labels
  "RColorBrewer"  # Colour palettes
)

# Install missing packages
install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message(paste("Installing package:", pkg))
    install.packages(pkg, repos = "https://cloud.r-project.org")
  } else {
    message(paste("Package already installed:", pkg))
  }
}

invisible(lapply(required_packages, install_if_missing))

message("\nAll required packages are installed.")
message("You can now run the Shiny app with: shiny::runApp()")
