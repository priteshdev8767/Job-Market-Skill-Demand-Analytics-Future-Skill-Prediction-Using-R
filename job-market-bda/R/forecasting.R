# ============================================================
# R/forecasting.R — Future Skill Demand Prediction
# ============================================================
# Uses Exponential Smoothing (ETS) / ARIMA to forecast
# skill demand for the next 2–3 quarters.
#
# Why ETS/ARIMA?
#   • Simple, interpretable, standard in time-series
#   • Works well with quarterly data
#   • Provides confidence intervals
#   • Easy to explain in a viva
# ============================================================

library(tidyverse)
library(forecast)

# ------------------------------------------------------------------
# prepare_skill_ts: build a time-series object for one skill
# ------------------------------------------------------------------
prepare_skill_ts <- function(trend_data, skill_name) {
  # Filter for the specific skill and sort
  sk <- trend_data %>%
    filter(skill == skill_name) %>%
    arrange(year, quarter)
  
  if (nrow(sk) < 4) {
    message("Not enough data points for: ", skill_name)
    return(NULL)
  }
  
  # Create ts object — quarterly frequency
  start_year <- min(sk$year)
  start_qtr  <- min(sk$quarter[sk$year == start_year])
  
  ts_obj <- ts(sk$demand_pct,
               start     = c(start_year, start_qtr),
               frequency = 4)
  
  return(ts_obj)
}

# ------------------------------------------------------------------
# forecast_skill: run ETS forecast for a skill
# ------------------------------------------------------------------
forecast_skill <- function(trend_data, skill_name, h = 3) {
  ts_obj <- prepare_skill_ts(trend_data, skill_name)
  
  if (is.null(ts_obj)) {
    return(NULL)
  }
  
  tryCatch({
    # Try ETS first (Exponential Smoothing)
    fit <- ets(ts_obj)
    fc  <- forecast(fit, h = h)
    
    # Build a tidy result
    hist_data <- trend_data %>%
      filter(skill == skill_name) %>%
      arrange(year, quarter) %>%
      mutate(type = "Historical")
    
    # Forecast dates
    fc_times <- time(fc$mean)
    fc_years <- floor(fc_times)
    fc_qtrs  <- round((fc_times - fc_years) * 4) + 1
    
    forecast_data <- tibble(
      skill       = skill_name,
      year        = as.integer(fc_years),
      quarter     = as.integer(fc_qtrs),
      year_quarter = paste0(fc_years, "-Q", fc_qtrs),
      demand_pct  = as.numeric(fc$mean),
      lower_80    = as.numeric(fc$lower[, 1]),
      upper_80    = as.numeric(fc$upper[, 1]),
      lower_95    = as.numeric(fc$lower[, 2]),
      upper_95    = as.numeric(fc$upper[, 2]),
      type        = "Forecast"
    )
    
    # Combine historical + forecast
    hist_subset <- hist_data %>%
      select(skill, year, quarter, year_quarter, demand_pct) %>%
      mutate(
        lower_80 = NA_real_, upper_80 = NA_real_,
        lower_95 = NA_real_, upper_95 = NA_real_,
        type     = "Historical"
      )
    
    combined <- bind_rows(hist_subset, forecast_data)
    
    # Model info
    model_info <- list(
      skill      = skill_name,
      model_type = fit$method,
      aic        = fit$aic,
      forecast   = fc,
      fit        = fit
    )
    
    return(list(data = combined, model = model_info))
    
  }, error = function(e) {
    message("Forecast error for ", skill_name, ": ", e$message)
    
    # Fallback: simple linear trend
    tryCatch({
      hist_data <- trend_data %>%
        filter(skill == skill_name) %>%
        arrange(year, quarter) %>%
        mutate(t = row_number())
      
      lm_fit <- lm(demand_pct ~ t, data = hist_data)
      
      future_t <- (nrow(hist_data) + 1):(nrow(hist_data) + h)
      future_pred <- predict(lm_fit, newdata = data.frame(t = future_t),
                              interval = "prediction", level = 0.95)
      
      last_year <- max(hist_data$year)
      last_qtr  <- max(hist_data$quarter[hist_data$year == last_year])
      
      fc_qtrs <- ((last_qtr):(last_qtr + h - 1) %% 4) + 1
      fc_years <- last_year + cumsum(c(0, diff(fc_qtrs) < 0))
      
      # Simple quarter increment
      fc_periods <- tibble(year = integer(), quarter = integer())
      cy <- last_year; cq <- last_qtr
      for (j in seq_len(h)) {
        cq <- cq + 1
        if (cq > 4) { cq <- 1; cy <- cy + 1 }
        fc_periods <- bind_rows(fc_periods, tibble(year = cy, quarter = cq))
      }
      
      forecast_data <- tibble(
        skill        = skill_name,
        year         = fc_periods$year,
        quarter      = fc_periods$quarter,
        year_quarter = paste0(fc_periods$year, "-Q", fc_periods$quarter),
        demand_pct   = future_pred[, "fit"],
        lower_80     = future_pred[, "lwr"],
        upper_80     = future_pred[, "upr"],
        lower_95     = future_pred[, "lwr"],
        upper_95     = future_pred[, "upr"],
        type         = "Forecast"
      )
      
      hist_subset <- hist_data %>%
        select(skill, year, quarter, year_quarter, demand_pct) %>%
        mutate(
          lower_80 = NA_real_, upper_80 = NA_real_,
          lower_95 = NA_real_, upper_95 = NA_real_,
          type     = "Historical"
        )
      
      combined <- bind_rows(hist_subset, forecast_data)
      
      model_info <- list(
        skill      = skill_name,
        model_type = "Linear Trend (fallback)",
        aic        = AIC(lm_fit),
        forecast   = NULL,
        fit        = lm_fit
      )
      
      return(list(data = combined, model = model_info))
      
    }, error = function(e2) {
      message("Linear fallback also failed for ", skill_name, ": ", e2$message)
      return(NULL)
    })
  })
}

# ------------------------------------------------------------------
# forecast_all_skills: batch forecast for top skills
# ------------------------------------------------------------------
forecast_all_skills <- function(trend_data, skill_list, h = 3) {
  results <- list()
  
  for (sk in skill_list) {
    res <- forecast_skill(trend_data, sk, h = h)
    if (!is.null(res)) {
      results[[sk]] <- res
    }
  }
  
  return(results)
}

# ------------------------------------------------------------------
# get_forecast_summary: summary table of all forecasts
# ------------------------------------------------------------------
get_forecast_summary <- function(forecast_results, growth_data) {
  summaries <- lapply(names(forecast_results), function(sk) {
    res <- forecast_results[[sk]]
    fc_data <- res$data %>% filter(type == "Forecast")
    
    if (nrow(fc_data) == 0) return(NULL)
    
    last_hist <- res$data %>%
      filter(type == "Historical") %>%
      arrange(desc(year), desc(quarter)) %>%
      slice(1) %>%
      pull(demand_pct)
    
    last_fc <- fc_data %>%
      arrange(desc(year), desc(quarter)) %>%
      slice(1) %>%
      pull(demand_pct)
    
    growth <- growth_data %>% filter(skill == sk)
    
    tibble(
      skill               = sk,
      current_demand_pct  = round(last_hist, 2),
      forecasted_demand_pct = round(last_fc, 2),
      predicted_change_pct  = round(last_fc - last_hist, 2),
      model_type          = res$model$model_type,
      growth_rate         = ifelse(nrow(growth) > 0, growth$growth_rate[1], NA),
      classification      = case_when(
        (last_fc - last_hist) > 1   ~ "Rising Demand",
        (last_fc - last_hist) > -1  ~ "Stable Demand",
        TRUE                        ~ "Declining Demand"
      )
    )
  })
  
  bind_rows(summaries)
}
