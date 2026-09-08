# R functions


#########################
########### Descriptives
#########################


# Create a custom function where you enter the vector of interest followed by how many bins
var_group <- function(x, c) {
  
  # Create the cut offs
  cut_offs <- quantile(x, probs = seq(0, 1, by = 1/c), na.rm = TRUE)
  
  # Fix the labels
  labels <- paste0(round(cut_offs[-length(cut_offs)]), "-", round(cut_offs[-1]))
  labels[length(labels)] <- paste0(round(cut_offs[length(cut_offs)-1]), "-", max(x, na.rm = TRUE))
  
  # Return the group label
  cut(x, breaks = cut_offs, include.lowest = TRUE, labels = labels)
}


# Create a custom function to get descriptives
get_descriptives <- function(data) {
  
  # Add an age aggregate dataset
  data_agg <- data %>%
    group_by(ID) %>%
    slice_head(n = 1) %>%
    ungroup()
  
  # Introduce age category information
  data_agg_age <- data_agg %>%
    count(Age_group_c,Spell_group) %>%
    pivot_wider(
      names_from = Age_group_c, 
      values_from = n, 
      names_prefix = "Age_"
    ) %>%
    as.data.frame()
  
  # Create a dataframe with descriptives between high and low spellers
  data_descriptives <- data.frame(
    Spell_group = c("high", "low"),
    sample_n = c(sum(data_agg$Spell_group == "high"), sum(data_agg$Spell_group == "low")),
    sex_m = c(sum(data_agg$Sex == "M" & data_agg$Spell_group == "high"),
              sum(data_agg$Sex == "M" & data_agg$Spell_group == "low")),
    sex_f = c(sum(data_agg$Sex == "F" & data_agg$Spell_group == "high"),
              sum(data_agg$Sex == "F" & data_agg$Spell_group == "low")),
    age_c_mean = c(round(mean(data_agg$Age_min_c[data_agg$Spell_group == "high"]),3),
                   round(mean(data_agg$Age_min_c[data_agg$Spell_group == "low"]),3))) 
  
  # Introduce the age count information
  data_descriptives_age <- left_join(data_descriptives, data_agg_age, by = "Spell_group")
  
  # Return full descriptive information
  return(data_descriptives_age)
  
}


##############################
########### Data Visualization
##############################

# Create a custom function to plot a design matrix
plot_design <- function(design_matrix){

# Convert the design matrix into long (for plotting)
design_matrix_long <- design_matrix %>%
  mutate(Row = row_number()) %>%
  tidyr::pivot_longer(-Row, names_to = "Column", values_to = "Value") %>%
  mutate(Column = factor(Column, levels = names(design_matrix)))

# Plot the design matrix
ggplot(design_matrix_long, aes(x = Column, y = Row, fill = factor(Value))) +
  geom_raster() + # Faster rendering than geom_tile for pure patterns
  scale_fill_manual(values = c("0" = "#ffffff", "-1" = "red", "1" = "#1f77b4")) +
  scale_y_reverse(expand = c(0, 0)) +
  scale_x_discrete(position = "top", expand = c(0, 0)) +
  theme_void() +
  theme(
    plot.title = element_text(hjust = 0.5, vjust = 4),
    axis.text.x = element_text(angle = 20, hjust = 0, face = "bold", size = 8),
    panel.border = element_rect(color = "black", fill = NA, size = 1),
    plot.margin = margin(10, 10, 10, 10)
  ) +
  labs(title = "Delta QTPME Design Matrix")

}


# Create a custom function to produce power as a function of sample size plots
plot_power <- function(data, group, alpha = 0.05) {
  
  # data summary
  data_sum <- data %>%
    filter(effect == "fixed") %>%
    mutate(
      term = fct_inorder(term),
      group = factor({{ group }}) # <-- Added {{ }} here!
    ) %>%
    group_by(term, group) %>%
    summarise(
      effect = first(effect),
      sim_power = mean(p.value < alpha),
      sim_n = n(),
      .groups = "drop"
    ) 
  
  # Generate a plot
  p1 <- data_sum %>%
    ggplot(aes(x = group, y = sim_power, group = term)) +
    geom_point() +
    geom_line() +
    facet_wrap(~term) +
    theme_minimal()
  
  # Return the plot and the sample size per group
  list(p1, unique(select(data_sum, group, sim_n)))
}



######################################
########### Data Simulation PARAMETRIC
######################################


# set up the custom data simulation function
my_sim_data <- function(
  # Sample size and grouping structure
  n = 303,
  prop_high   = .80,
  prop_high_f = .54,
  prop_low_f  = .06,
  
  # Age and structure inputs
  age_sampling = "empirical",
  data         = delta_dat_agg,
  original_dat = delta_dat,
  
  # Explicit Parameter Inputs (extract from vectors)
  beta_a  = fixe_effs[1:12],
  beta_b  = fixe_effs[13:14],
  beta_xs = fixe_effs[15:16],
  tau_0   = rand_effs[1],
  sigma   = rand_effs[2]
) {
  
  # 1. Simulate subjects helper function
  subjects <- between_subjects(
    n, prop_high, prop_high_f, prop_low_f
  )
  
  # 2. Add age information (sample or population)
  subjects <- add_age(subjects, age_sampling, data)
  
  # 3. Add subject specific effects
  subjects$a_ran <- rnorm(nrow(subjects), 0, tau_0)
  
  # 4. Cross subjects with the within subject factors
  crossed_top <- expand.grid(region = unique(original_dat$region), 
                             hemisphere = unique(original_dat$hemisphere))
  
  subjects_crossed <- crossing(subjects, crossed_top)
  
  # 5. Creating our design matrix
  subjects_crossed_design <- create_design_variables(subjects_crossed)
  
  # 6. Contrast the factors in the same way as the original model
  subjects_crossed_design_contrasts <- set_model_contrasts(subjects_crossed_design)
  
  # 7. Simulate the 'observed' log EEG power
  add_simulated_outcome(
    df      = subjects_crossed_design_contrasts, 
    beta_a  = beta_a, 
    beta_b  = beta_b, 
    beta_xs = beta_xs, 
    sigma   = sigma
  )
  
}



##
##### Step 1 Function
##

# Create a custom function to simulate the between subject-factors (sex and age)
between_subjects <- function(
    n           = 303,    # sample size
    prop_high   = 0.8,    # Proportion of good spellers
    prop_high_f = 0.54,   # Proportion of females in the good spelling group
    prop_low_f  = 0.06) { # Proportion of females in the poor spelling group
  
  # Get the sample size for each spelling group
  n_high <- round(n * prop_high)
  n_low  <- n - n_high
  
  # Get the number of females conditional on spelling group
  n_high_f <- round(n * prop_high_f)
  n_low_f  <- round(n * prop_low_f)
  
  # Create a dataframe wih the 
  data <- data.frame(
    ID = seq_len(n),
    Spell_group = rep(c("high", "low"), c(n_high, n_low)),
    Sex = c(
      rep(c("F", "M"), c(n_high_f, n_high - n_high_f)),
      rep(c("F", "M"), c(n_low_f,  n_low - n_low_f)))
    )
  
  # Return the data frame
  return(data)
}

###
####### Step 2 Function
###

# Create a function to get the ages from the sample
add_age <- function(
    subjects     = NULL,   # Provide the between-subjects data frame
    age_sampling = c("empirical", 
                     "uniform_current", 
                     "uniform_extended"),
    data         = NULL,   # Provide the data frame with spelling information
    c            = 5) { 
  
  if (age_sampling == "empirical") {
    
    # Count how many high and low subjects are in the current simulation rows
    n_high <- sum(subjects$Spell_group == "high")
    n_low  <- sum(subjects$Spell_group == "low")
    
    # Get the age for the high spellers matching the current n_high count
    sim_ages_high <- data %>%
      filter(Spell_group == "high") %>%
      select(Age_min_c, Age_group, Age_group_c) %>%
      slice_sample(n = n_high, replace = TRUE)
    
    # Get the age for the low spellers matching the current n_low count
    sim_ages_low <- data %>%
      filter(Spell_group == "low") %>%
      select(Age_min_c, Age_group, Age_group_c) %>%
      slice_sample(n = n_low, replace = TRUE)
    
    # Combine the high and low group spelling ages together
    sim_ages <- bind_rows(sim_ages_high, sim_ages_low)
    
  } else if (age_sampling == "uniform_current") {
    
    # Get the age for the same age range as our sample uniformly
    sim_ages <- data.frame(
      Age_min_c = sample(0:17, size = nrow(subjects), replace = TRUE)
    ) %>%
      mutate(Age_group_c = var_group(Age_min_c, c))
    
  } else if (age_sampling == "uniform_extended") {
    
    # Get the age for the extended age range uniformly
    sim_ages <- data.frame(
      Age_min_c = sample(0:25, size = nrow(subjects), replace = TRUE)
    ) %>%
      mutate(
        Age_group_c = var_group(Age_min_c, c)
      )
  }
  
  # Return the between-subject dataframe with age information
  return(cbind(subjects, sim_ages))
}


###
####### Step 5 Function
###


# Create a custom function to introduce the contrast coded predictors
create_design_variables <- function(subjects_crossed) {
  
  # Create the contrast coded predictors
  subjects_crossed %>%
    mutate(
      
      # Create the effect for sex (dummy coded)
      SexM = ifelse(Sex == "M", 1, 0),
      
      # Create the effect for spelling (dummy coded)
      Spell_low = ifelse(Spell_group == "low", 1, 0),
      
      # Create the effect for hemisphere (effect coded)
      hem_left = ifelse(hemisphere == "left", 1, -1),
      
      # Create effect coded contrasts where temporal is the 'reference'
      reg_central = case_when(
        region == "central" ~ 1,
        region == "temporal" ~ -1,
        TRUE ~ 0
      ),
      
      reg_frontal = case_when(
        region == "frontal" ~ 1,
        region == "temporal" ~ -1,
        TRUE ~ 0
      ),
      
      reg_occip = case_when(
        region == "occipital" ~ 1,
        region == "temporal" ~ -1,
        TRUE ~ 0
      ),
      
      reg_parietal = case_when(
        region == "parietal" ~ 1,
        region == "temporal" ~ -1,
        TRUE ~ 0
      ),
      
      # Create the interaction variables as well
      hem_central  = hem_left * reg_central,
      hem_frontal  = hem_left * reg_frontal,
      hem_occip    = hem_left * reg_occip,
      hem_parietal = hem_left * reg_parietal
    )
}


###
####### Step 6 Function
###


# Create a custom function to produce the same contrasts of the simulated data as the original model
set_model_contrasts <- function(dat) {
  
  dat$Spell_group <- factor(
    dat$Spell_group,
    levels = levels(delta_dat$Spell_group)
  )
  
  dat$Sex <- factor(
    dat$Sex,
    levels = levels(delta_dat$Sex)
  )
  
  dat$region <- factor(
    dat$region,
    levels = levels(delta_dat$region)
  )
  
  dat$hemisphere <- factor(
    dat$hemisphere,
    levels = levels(delta_dat$hemisphere)
  )
  
  dat$ID <- factor(dat$ID)
  
  contrasts(dat$Spell_group) <- contrasts(delta_dat$Spell_group)
  contrasts(dat$Sex) <- contrasts(delta_dat$Sex)
  contrasts(dat$region) <- contrasts(delta_dat$region)
  contrasts(dat$hemisphere) <- contrasts(delta_dat$hemisphere)
  
  dat
}

###
####### Step 7 Function
###

add_simulated_outcome <- function(
    df, 
    beta_a,
    beta_b,
    beta_xs,
    sigma
) {
  # Extract the a parameters
  a1 = beta_a[1]; a2 = beta_a[2]; a3 = beta_a[3]; a4 = beta_a[4]; a5 = beta_a[5]; a6 = beta_a[6] 
  a7 = beta_a[7]; a8 = beta_a[8]; a9 = beta_a[9]; a10 = beta_a[10]; a11 = beta_a[11]; a12 = beta_a[12] 
  
  # Extract the b parameters
  b1 = beta_b[1]; b2 = beta_b[2]
  
  # Extract the xs parameters
  xs1 = beta_xs[1]; xs2 = beta_xs[2]
  
  # Generate outcome variable
  df %>%
    mutate(
      a_param = a1 + a2*SexM + a3*hem_left + a4*reg_central + a5*reg_frontal + 
        a6*reg_occip + a7*reg_parietal + a8*Spell_low + a9*hem_central + 
        a10*hem_frontal + a11*hem_occip + a12*hem_parietal + a_ran,
      
      b_param  = b1 + b2 * Spell_low,
      xs_param = xs1 + xs2 * Spell_low,
      
      mu = ifelse(
        Age_min_c <= xs_param,
        a_param + b_param * Age_min_c - (b_param / (2 * xs_param)) * Age_min_c^2,
        a_param + (b_param * xs_param) / 2
      ),
      
      log_absolute_power = mu + rnorm(n(), 0, sigma)
    )
}


######################################
########### Data Simulation RESAMPLED
######################################


# A new function to simulate data
my_sim_data2 <- function(data, mod, dup_n) {
  
  # Get the residual standard deviation from the model
  noise_sd <- as.numeric(VarCorr(mod)["Residual", "StdDev"])
  
  # Generate original + duplicated datasets
  data_list <- lapply(seq_len(dup_n), function(x) {
    
    if (x > 1) {
      
      # Give duplicates new IDs
      data$ID <- paste0(data$ID, "_", x)
      
      # Generate new outcome
      data$log_absolute_power <- fitted(mod) + rnorm(nrow(data), mean = 0, sd = noise_sd)
    }
    
    # Return data for this iteration
    data
  })
  
  # Merge everything into one data frame
  sim_data <- do.call(rbind, data_list)
  
  return(sim_data)
}



##########################
########### Fitting Models
##########################


###
######## Main Function
###


# Set up the power function
single_run <- function(
    filename  = NULL, # Use to create a .csv
    iteration = NA,   # Number of data simulation + model fitting + estimate extraction
    seed      = NULL, # Specify seed before data creation to replicate
    sim_type  = "parametric", #("parametric" or "resampled")
    ...
) {
  
  # Set the seed if one was provided
  if (!is.null(seed)) {
    set.seed(seed)
  }
  
  # 1. Conditionally simulate data based on sim_type
  if (sim_type == "parametric") {
    dat_sim <- my_sim_data(...)
  } else if (sim_type == "resample") {
    dat_sim <- my_sim_data2(...)
  } else {
    stop("Invalid 'sim_type'. Must be either 'parametric' or 'resample'.")
  }
  
  # 2. Fit the model
  fit <- fit_sim_model(dat_sim)
  
  # 3. Check for failure
  failure_row <- handle_model_failure(fit, iteration, seed, ...)
  if (!is.null(failure_row)) return(failure_row)
  
  # 4. Extract the model results
  sim_results <- extract_sim_results(fit$model) %>%
    mutate(
      iteration = iteration,
      seed = seed,
      warnings = fit$warnings,
      errors = fit$errors
    )
  
  # 5. Add parameter info into sim_results (However ignore if arguments == those below)
  run_params <- list(...)
  for (name in names(run_params)) {
    if (!name %in% c("data", "mod", "filename") && length(run_params[[name]]) == 1) {
      sim_results[name] <- run_params[[name]]
    }
  }
  
  # 6. Save current sim_results into a .csv and append it
  if (!is.null(filename)) {
    append <- file.exists(filename)
    write_csv(sim_results, filename, append = append)
  }
  
  # Return the simulation results (for single usage)
  sim_results
}



# Create a function to fit the model to the data (raw or sim) and capture warnings/errors
fit_sim_model <- function(dat_sim) {
  
  ww <- ""
  ee <- ""
  
  mod_sim <- tryCatch(
    withCallingHandlers(
      
      nlme(
        log_absolute_power ~ SSquadp3xs(Age_min_c, a, b, xs),
        data = dat_sim,
        fixed = list(
          a ~ Sex + hemisphere * region + Spell_group,
          b ~ Spell_group,
          xs ~ Spell_group
        ),
        random = a ~ 1 | ID,
        start = c(
          a = 2, rep(0, 1 + 1 + 4 + 1 + 1 - 1 + 4),
          b = -1, 0,
          xs = 13, 0
        ),
        control = nlmeControl(msMaxIter = 2000)
      ),
      
      warning = function(w) {
        ww <<- w$message
        invokeRestart("muffleWarning")
      }
    ),
    
    error = function(e) {
      ee <<- e$message
      NULL
    }
  )
  
  list(
    model = mod_sim,
    warnings = ww,
    errors = ee
  )
}

# Create a helper function that returns NA's if the model fails to produce
handle_model_failure <- function(fit, iteration = NA, seed = NULL, ...) {
  if (is.null(fit$model)) {
    
    # 1. Create the base failure row
    res <- tibble(
      effect    = NA_character_,
      term      = NA_character_,
      estimate  = NA_real_,
      std.error = NA_real_,
      df        = NA_real_,
      statistic = NA_real_,
      p.value   = NA_real_,
      iteration = iteration,
      seed      = seed,
      warnings  = fit$warnings,
      errors    = fit$errors
    )
    
    # 2. Append extra parameters from ...
    params <- list(...)
    for (name in names(params)) {
      res[name] <- params[name]
    }
    
    return(res)
  }
  
  return(NULL)
}

# Create a function to extract the fixed and random effects from the model object
extract_sim_results <- function(mod_sim) {
  
  # Extract the fixed effects
  sim_fixed <- broom.mixed::tidy(
    mod_sim,
    effects = "fixed"
  )
  
  # Extract the random effects
  sim_ran <- data.frame(
    effect = c("random", "random"),
    term = c("intercepts", "residuals"),
    estimate = c(
      as.numeric(VarCorr(mod_sim)[1, "StdDev"]),
      as.numeric(VarCorr(mod_sim)[nrow(VarCorr(mod_sim)), "StdDev"])
    )
  )
  
  # Combine the fixed and random effects
  bind_rows(sim_fixed, sim_ran)
}



###################################
########### SUMMARIZING SIMULATIONS
##################################

# Summarize the simulated data means
summarize_simulation <- function(data, alpha = 0.05, original_estimates) {
  
  data %>%
    mutate(term = fct_inorder(term)) %>%
    group_by(term) %>%
    summarise(
      effect = first(effect),
      sim_mean_estimate = mean(estimate),
      sim_mean_se = mean(std.error),
      sim_power = paste0(round(mean(p.value < alpha, na.rm = TRUE) * 100, 1),"%"),
      sim_n = n(),
      .groups = "drop"
    ) %>%
    mutate(original_estimate = original_estimates) %>%
    mutate(across(where(is.numeric), ~ round(., 3))) %>%
    relocate(original_estimate, .before = sim_mean_estimate)
}

# Summarize the simulated data variability in the means
summarize_sim_dist <- function(data, original_estimates) {
  data %>%
    mutate(term = fct_inorder(term)) %>%
    group_by(term) %>%
    summarise(
      sim_mean = mean(estimate, na.rm = TRUE),
      sim_median = median(estimate, na.rm = TRUE),
      sim_q025 = quantile(estimate, .025, na.rm = TRUE),
      sim_q25 = quantile(estimate, .25, na.rm = TRUE),
      sim_q75 = quantile(estimate, .75, na.rm = TRUE),
      sim_q975 = quantile(estimate, .975, na.rm = TRUE),
      sim_min = min(estimate, na.rm = TRUE),
      sim_max = max(estimate, na.rm = TRUE),
      sim_n = length(term),
      .groups = "drop"
    ) %>%
    mutate(
      original_estimate = original_estimates,
      within_q50 = original_estimate > sim_q25 & original_estimate < sim_q75
    ) %>%
    mutate(across(where(is.numeric), ~ round(., 3))) %>%
    relocate(original_estimate, .before = sim_mean)
}
