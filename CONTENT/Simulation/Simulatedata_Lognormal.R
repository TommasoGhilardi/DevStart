# Load Libraries -----------------------------------------------------------
# Load necessary libraries for data manipulation, visualization, and statistical modeling.
library(tidyverse)  # Data manipulation and visualization
library(easystats)  # Easy statistical modeling
library(lmerTest)   # Mixed-effect models
library(GGally)     # Plotting relationships between variables
library(faux)       # Simulating correlated variables

# Set Options --------------------------------------------------------------
# Set display options to control how numbers are shown in the output.
options("scipen" = 10, "digits" = 4) # Prevent scientific notation, display up to 4 digits


# Variables ----------------------------------------------------------------
# Define parameters and settings for the simulation.
n_subjects  <- 20                        # Number of subjects
ntrials = 20                              # Number of trials per subject
random_intercept_sd <- 0.3               # Standard deviation of the random intercept (on log scale)
random_slope_sd <- 0.02                  # Standard deviation of the random slope (on log scale)
random_intercept_slope_cor <- -0.2       # Correlation between intercept and slope for trial number

# Parameters for log scale (these will be exponentiated to get ms reaction times)
grand_mean_log_rt <- 6                   # Grand mean on log scale (exp(6) ≈ 400ms)
fixed_categorical_effect <- -0.1         # Fixed effect: difference between categorical levels
fixed_continuous_effect <- -0.02         # Fixed effect of continuous variable (learning/practice effect)
interaction_effect <- -0.034              # Interaction effect between categorical and continuous variables
residual_sd <- 0.07                      # Residual standard deviation (on log scale)


# Random Effects for Subjects ----------------------------------------------
subjects <- faux::rnorm_multi(
  n = n_subjects,
  vars = 2,
  r = random_intercept_slope_cor,
  mu = 0,
  sd = c(random_intercept_sd, random_slope_sd),
  varnames = c("random_intercept", "random_slope_trial")
) %>%
  mutate(subject_id = 1:n_subjects)


# Trials ------------------------------------------------------------------
trial_data <- crossing(
  subject_id = subjects$subject_id,
  categorical_condition = c("Spoon", "Hammer"),
  trial_number = 1:ntrials)

# Merge with subject-level random effects to include individual variations.
trial_data <- left_join(trial_data, subjects, by = "subject_id")
trial_data$subject_id <- as.factor(trial_data$subject_id)


# Dependent Variable Calculation (Lognormal Reaction Times) ----------------

##### Simulate Data ####
simulated_data <- trial_data %>%
  mutate(
    categorical_coded = recode(categorical_condition, "Spoon" = -0.5, "Hammer" = 0.5),
    fixed_categorical = fixed_categorical_effect * categorical_coded,
    interaction_term = categorical_coded * trial_number * interaction_effect,
    random_error = rnorm(nrow(.), 0, residual_sd),
    
    # Calculate log of reaction time (normal distribution on log scale)
    log_rt = grand_mean_log_rt + 
      (random_intercept) +
      (random_slope_trial * trial_number) +
      (fixed_continuous_effect * trial_number) +
      fixed_categorical +
      interaction_term +
      random_error,
    
    # Convert from log scale to milliseconds (this creates the lognormal distribution)
    reaction_time = exp(log_rt),
    # remove too fast with NA
    treshold = rnorm(nrow(.), 210, 10),
    reaction_time = ifelse(reaction_time < treshold, NA, reaction_time)
    
  )


# Models ------------------------------------------------------------------

# Mixed-Effects Model on log-transformed data
mod_rt <- lmer(reaction_time ~ categorical_condition * trial_number + 
                 (1 + trial_number | subject_id), data = simulated_data)


# Mixed-Effects Model using Gamma distribution
simulated_data$stand_TrialN = datawizard::standardise(simulated_data$trial_number)
mod_gam = glmer(reaction_time ~ categorical_condition * stand_TrialN + 
                  (1 + stand_TrialN | subject_id),
                family = Gamma(link = 'log'), data = simulated_data)


#### Check models ####

summary(mod_rt)
check_model(mod_rt)

summary(mod_gam)
check_model(mod_gam)



#### Save data ####
write.csv(simulated_data, "CONTENT\\Simulation\\simulatedLognormal.csv", row.names = FALSE)



# Visualize the Simulated Data --------------------------------------------
# Plot on original scale (milliseconds)
ggplot(simulated_data, aes(x = trial_number, y = reaction_time, color = categorical_condition)) +
  geom_line() +
  geom_point() +
  labs(title = "Simulated Reaction Times (ms)",
       x = "Trial Number",
       y = "Reaction Time (ms)",
       color = "Condition") +
  theme_minimal() +
  facet_wrap(vars(subject_id), scales = 'free')


# Histogram to show distribution shape
ggplot(simulated_data, aes(x = reaction_time, fill = categorical_condition)) +
  geom_density(alpha = 0.3, color = "black") +
  labs(title = "Distribution of Reaction Times",
       x = "Reaction Time (ms)",
       y = "Count",
       fill = "Condition") +
  theme_minimal()




# Estimated Expectation ---------------------------------------------------

Pred = estimate_expectation(mod_gam, by = c('stand_TrialN', 'categorical_condition'), transform = T)

ggplot(Pred, aes(x = stand_TrialN, y = Predicted, color = categorical_condition, fill = categorical_condition)) +
  geom_ribbon(aes(ymin = CI_low, ymax = CI_high), alpha = .5, color = 'transparent') +
  geom_line(lwd = 1.3)+
  theme_modern()


estimate_contrasts(mod_gam, contrast = 'stand_TrialN', by = 'categorical_condition', transform = T)
