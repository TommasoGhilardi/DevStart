

library(tidyverse) # for data wrangling, pipes, and good dataviz
library(lmerTest)  # for mixed effect models
library(GGally)    # makes it easy to plot relationships between variables
# devtools::install_github("debruine/faux")
library(faux)      # for simulating correlated variables

options("scipen"=10, "digits"=4) # control scientific notation
set.seed(8675309) # Jenny, I've got your number


# Variables ---------------------------------------------------------------


sub_n  <- 5 # number of subjects in this simulation
sub_sd <- 100 # SD for the subjects' random intercept
sub_version_sd <- 20 # SD for the subjects' random slope
sub_i_version_cor <- -0.2 # correlation between intercept and slope

grand_i          <- 400 # overall mean DV
stim_version_eff <- -50  # mean difference between versions: incongruent - congruent
# cond_version_ixn <-  0  # interaction between version and condition
error_sd         <- 25  # residual (error) SD



# Subject -----------------------------------------------------------------


sub <- faux::rnorm_multi(
  n = sub_n, 
  vars = 2, 
  r = sub_i_version_cor,
  mu = 0, # means of random intercepts and slopes are always 0
  sd = c(sub_sd, sub_version_sd),
  varnames = c("sub_i", "sub_version_slope")
) %>%
  mutate(
    sub_id = 1:sub_n)



# Trials ------------------------------------------------------------------

trials <- crossing(
  sub_id = sub$sub_id, # get subject IDs from the sub data table
  stim_version = c("Spoon", "Hammmer"), # all subjects see both congruent and incongruent versions of all stimuli
  trial_n= 1:10
) %>%
  left_join(sub, by = "sub_id") # includes the intercept and conditin for each subject

trials = trials %>%
  mutate(
    NoiseI = rnorm(n(), mean = sub_i * 0.05, sd = abs(sub_i * 0.0005)),
    NoiseS = rnorm(n(), mean = sub_version_slope * 0.05, sd = abs(sub_version_slope * 0.0005))
    
  )



# DV ----------------------------------------------------------------------

dat <- trials %>%
  mutate(
    # effect-code subject condition and stimulus version
    stim_version.e = recode(stim_version, "Spoon" = -0.5, "Hammmer" = +0.5),
    
    # calculate trial-specific effects by adding overall effects and slopes
    version_eff = stim_version_eff + (sub_version_slope),
    
    # calculate error term (normally distributed residual with SD set above)
    err = rnorm(nrow(.), 0, error_sd),
    
    # calculate DV from intercepts, effects, and error
    dv = grand_i + (sub_i )  + err +
      (stim_version.e * version_eff) + 
      ( stim_version.e )
    )


# Plot --------------------------------------------------------------------

ggplot(dat, aes(y=dv, x=stim_version, color = factor(sub_id)))+
  geom_boxplot()+
  facet_wrap(~sub_id)



# Model -------------------------------------------------------------------


mod <- lmer(dv ~  stim_version.e +
              (1 + stim_version.e | sub_id),  data = dat)
summary(mod)
