# Load Libraries -----------------------------------------------------------
# Load necessary libraries for data manipulation, visualization, and statistical modeling.
library(tidyverse) # Data manipulation and visualization
library(easystats) # Easy statistical modeling
library(lmerTest) # Mixed-effect models
library(GGally) # Plotting relationships between variables
library(faux) # Simulating correlated variables

# Set Options --------------------------------------------------------------
# Set display options to control how numbers are shown in the output.
options("scipen" = 10, "digits" = 4) # Prevent scientific notation, display up to 4 digits
# set.seed(8675309) # Uncomment to set a seed for reproducibility

# Variables ----------------------------------------------------------------
# Define parameters and settings for the simulation.
n_subjects <- 20 # Number of subjects
trialn = 20
random_intercept_sd <- 150 # Standard deviation of the random intercept for subjects
random_slope_sd <- 8 # Standard deviation of the random slope for trial number by subject
random_intercept_slope_cor <- -0.2 # Correlation between intercept and slope for trial number

grand_mean_dv <- 400 # Grand mean of the dependent variable (DV)
# fixed_categorical_effect <- -10 # Fixed effect: difference between categorical levels (e.g., Spoon vs. Hammer)
# fixed_continuous_effect <- 10 # Fixed effect of continuous variable (e.g., trial number)
# interaction_effect <- 6 # Interaction effect between categorical and continuous variables
# residual_sd <- 30 # Residual standard deviation


# Adjust the fixed effects so that one effect increases DV and the other decreases DV slightly.
fixed_categorical_effect <- -50 # When effect-coded: Spoon becomes +4 and Hammer becomes -4
fixed_continuous_effect <- -8 # Each additional trial increases DV by 8 units
interaction_effect <- -4 # Interaction adds/subtracts 4 units per trial depending on the condition
residual_sd <- 30


# Random Effects for Subjects ----------------------------------------------

# This section generates subject-specific random effects. It simulates a random intercept
# and a random slope for the continuous variable (trial number) for each subject.
# The correlation between these two random effects is controlled by `random_intercept_slope_cor`.

subjects <- faux::rnorm_multi(
  n = n_subjects, # Number of subjects
  vars = 2, # Number of random effect variables to generate
  r = random_intercept_slope_cor, # Correlation between intercept and slope
  mu = 0, # Mean of random effects
  sd = c(random_intercept_sd, random_slope_sd), # Standard deviations for intercept and slope
  varnames = c("random_intercept", "random_slope_trial") # Names for the random effects
) %>%
  mutate(subject_id = 1:n_subjects) # Add a unique subject ID for identification


# Trials ------------------------------------------------------------------

# This section simulates trial-level data for each subject by expanding the subject
# data to include every possible combination of subjects and trial conditions.
# Each subject will complete multiple trials, and each trial will appear under two different
# conditions ("Spoon" and "Hammer"). The code then joins these trials with each subject's
# random effects (intercept and slope), allowing the trial data to inherit subject-specific
# random effects.

trial_data <- crossing(
  subject_id = subjects$subject_id, # Generate subject IDs from the "subjects" data frame
  categorical_condition = c("Spoon", "Hammer"), # Each subject sees both versions ("Spoon" and "Hammer")
  trial_number = 1:trialn
) # Each subject completes trialn trials per condition

# Merge with subject-level random effects to include individual variations.
trial_data <- left_join(trial_data, subjects, by = "subject_id")


# Dependent Variable Calculation ------------------------------------------

# This section calculates the dependent variable (DV) for each trial based on the simulated
# random and fixed effects. The `mutate` function is used to create additional columns:
# one for the effect-coded version of the categorical condition, and others for the calculated
# trial-specific effects. The DV is then computed by combining the grand mean, random intercept,
# random slope, fixed effects for the categorical and continuous variables, and their interactions.
# A normally distributed error term is added to simulate measurement variability, producing
# realistic trial-level dependent variable values.
P1 = -Inf
P2 = -Inf
iter = 1
while(P1 <0.05 | P2 < 0.05){
  print(iter)
  iter = iter + 1
  
  simulated_data <- trial_data %>%
    mutate(
      categorical_coded = recode(
        categorical_condition,
        "Spoon" = -0.5,
        "Hammer" = 0.5
      ), # Effect-code the categorical variable
      fixed_categorical = fixed_categorical_effect * categorical_coded, # Fixed effect of categorical variable
      interaction_term = categorical_coded * trial_number * interaction_effect, # Interaction effect between categorical and continuous variable
      random_error = rnorm(nrow(.), 0, residual_sd), # Normally distributed error term
  
      # Calculate dependent variable from intercepts, random slopes, and trial-specific effects
      dependent_variable = grand_mean_dv +
        (random_intercept) + # Subject-specific random intercept
        (random_slope_trial * trial_number) + # Subject-specific random slope for trial number
        (fixed_continuous_effect * trial_number) + # Fixed effect of continuous variable (trial number)
        fixed_categorical + # Fixed effect of categorical variable (e.g., tool condition)
        interaction_term + # Interaction effect between categorical and continuous variable
        random_error # Residual error
    )
  
  simulated_data$dependent_variable = rescale(
    simulated_data$dependent_variable,
    to = c(400, 1980)
  )
  
  
  
  # Check model performance -------------------------------------------------
  
  # Linear Model (LM)
  mod_lm <- lm(
    dependent_variable ~ categorical_condition * trial_number,
    data = simulated_data
  )
  # summary(mod_lm)
  # check_model(mod_lm)
  
  # Mixed-Effects Model (LMM)
  mod_mixed <- lmer(
    dependent_variable ~
      categorical_condition * trial_number + (1 + trial_number | subject_id),
    data = simulated_data
  )
  # summary(mod_mixed)
  # check_model(mod_mixed)
  
  
  P1 = parameters(mod_lm)[4,'p']
  P2 = check_normality(mod_mixed)

}

write.csv(simulated_data, "CONTENT\\Simulation\\simulatedNormal.csv", row.names = FALSE)


check_model(mod_lm)
check_model(mod_mixed)

# Visualize the Simulated Data --------------------------------------------

# This section creates a visualization of the simulated data. Each subject's dependent variable
# is plotted across the trial numbers, with separate lines for each categorical condition ("Spoon" vs. "Hammer").
# The `facet_wrap` function is used to create separate panels for each subject, allowing for an
# individual comparison of trends over time.

ggplot(
  simulated_data,
  aes(x = dependent_variable, fill = categorical_condition)
) +
  geom_density(alpha = 0.3, color = "transparent") +
  geom_density(color = "black", fill = "transparent") +
  theme_modern()


ggplot(
  simulated_data,
  aes(x = trial_number, y = dependent_variable, color = categorical_condition)
) +
  geom_line() +
  geom_point() +
  labs(
    title = "Simulated Data: Random Intercept and Slope by Trial Number with Categorical and Interaction Effects",
    x = "Trial Number",
    y = "Dependent Variable (DV)",
    color = "Condition"
  ) +
  theme_minimal() +
  facet_wrap(vars(subject_id), scales = 'free')



# Estimated Expectation ---------------------------------------------------

# This section uses the fitted mixed-effects model to estimate expected values for the dependent variable
# across trial numbers and categorical conditions. A confidence interval is calculated and visualized
# using a ribbon plot, showing the expected trends and their uncertainty for each categorical condition.

Est <- estimate_expectation(
  mod_mixed,
  get_datagrid(mod_mixed, by = c('categorical_condition', 'trial_number'))
)
ggplot(
  Est,
  aes(
    x = trial_number,
    y = Predicted,
    color = categorical_condition,
    fill = categorical_condition
  )
) +
  geom_ribbon(aes(ymin = Predicted - SE, ymax = Predicted + SE), alpha = 0.4) +
  geom_line() +
  theme_bw()


