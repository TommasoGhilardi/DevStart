# Load Libraries -----------------------------------------------------------
library(tidyverse)  # Data manipulation and visualization
library(easystats)
library(lmerTest)   # Mixed-effect models
library(GGally)     # Plotting relationships between variables
# devtools::install_github("debruine/faux")  # Install 'faux' from GitHub if not installed
library(faux)       # Simulating correlated variables

# Set Options --------------------------------------------------------------
options("scipen" = 10, "digits" = 4) # Display options
# set.seed(8675309) # Seed for reproducibility



# TODO --------------------------------------------------------------------

# Add random slope for trial as now it is only for the categorical effect of tool




# Variables ----------------------------------------------------------------
sub_n  <- 20            # Number of subjects
sub_sd <- 150           # SD of random intercept
sub_version_sd <- 60    # SD of random slope
sub_i_version_cor <- -0.3 # Correlation between intercept and slope

grand_i <- 400          # Grand mean of the dependent variable (DV)
stim_version_eff <- -60 # Fixed effect: difference between versions
error_sd <- 10          # Residual SD

## Trial-Specific Variables -------------------------------------------------
stim_trial_eff = 5     # Effect of trials
int_trialver = 10       # Interaction effect


## Random Effects for Trials ------------------------------------------------
sub_trial_sd = 30       # SD of trial random effects
sub_trial_cor = -0.2    # Correlation between trial intercept and slope



# Subject-level Random Effects Simulation ----------------------------------

# This section generates the random effects for each subject 
# Specifically, it creates two key random variables:
# (1) a random intercept that represents the baseline deviation of each subject
#   from the overall mean,
# (2) a random slope indicating how each subject's response changes depending on
#   the condition or version. By setting a correlation between these random effects,
#   it accounts for how variations in baseline performance might relate to changes
#   in condition-specific performance.
# 
# This will enable the model to capture individual differences in both the starting
# point and reaction patterns across different experimental conditions.

sub <- faux::rnorm_multi(
  n = sub_n,              # Number of subjects
  vars = 2,               # Number of variables to generate
  r = sub_i_version_cor,  # Correlation between intercept and slope
  mu = 0,                 # Mean of random effects
  sd = c(sub_sd, sub_version_sd),  # SDs for intercept and slope
  varnames = c("sub_i", "sub_version_slope")  # Names of random effects
) %>%
  mutate(sub_id = 1:sub_n) # Add subject ID



# Trials ------------------------------------------------------------------

# This section simulates trial-level data for each subject by expanding the subject
# data to include every possible combination of subjects and trial conditions. Each 
# subject will complete multiple trials, and each trial will appear under two different 
# conditions ("Spoon" and "Hammer"). The code then joins these trials with each subject's 
# random effects (intercept and slope), allowing the trial data to inherit subject-specific 
# random effects.

trials <- crossing(
  sub_id = sub$sub_id,               # Generate subject IDs from the "sub" data frame
  stim_version = c("Spoon", "Hammer"), # Each subject sees both versions ("Spoon" and "Hammer")
  trial_n = 1:10) %>%                     # Each subject completes 10 trials per condition

  left_join(sub, by = "sub_id")       # Merge with subject data to include random effects for each trial



# DV ----------------------------------------------------------------------

# This section calculates the dependent variable (DV) for each trial based on the simulated 
# random and fixed effects. The `mutate` function is used to create additional columns: 
# one for the effect-coded version of the stimulus condition, and others for the calculated 
# trial-specific effects. Then, the DV is computed by combining the grand intercept, random 
# intercept, and trial effects, along with the fixed effects for stimulus condition and 
# their interactions. A normally distributed error term is added to simulate variability 
# in measurements, producing a realistic trial-level dependent variable.


dat <- trials %>%
  mutate(
    stim_version.e = recode(stim_version, "Spoon" = -0.5, "Hammmer" = +0.5), # Effect-code condition
    version_eff = stim_version_eff + (sub_version_slope), # Trial-specific version effect
    trial_eff = stim_trial_eff,                          # Trial-specific effect
    err = rnorm(nrow(.), 0, error_sd),                   # Normally distributed error term
    
    # Calculate dependent variable from intercepts, effects, and error
    dv = grand_i + (sub_i) + err + 
      (trial_eff * trial_n) + 
      (stim_version.e * version_eff) +
      (stim_version.e * trial_n * int_trialver)          # Interaction effects
  )



# Plot --------------------------------------------------------------------

ggplot(dat, aes(y=dv, x=trial_n, color = stim_version))+
  geom_point()+
  facet_wrap(~sub_id, scales = 'free')+
  theme_bw()



# Model -------------------------------------------------------------------

lm_mod = lm(dv ~  stim_version * trial_n,  data = dat)
summary(lm_mod)


mod <- lmer(dv ~  stim_version * trial_n + 
              (1 + stim_version | sub_id),  data = dat)
summary(mod)


Est = estimate_expectation(mod, get_datagrid(mod, by = c('stim_version','trial_n')))


ggplot(Est, aes(x = trial_n, y = Predicted, color = stim_version, fill = stim_version))+
  geom_ribbon(aes(ymin = Predicted-SE, ymax = Predicted+SE), alpha = 0.4)+
  geom_line()+
  theme_bw()
