
library(tidyverse) # Load the package
library(patchwork) # Load the package
library(lmerTest) # Load the package
library(easystats)



ReactionTime = vroom::vroom("CONTENT\\Simulation\\simulatedLognormal.csv") |> 
  rename(ReactionTime = reaction_time,
         Id = subject_id,
         Event = categorical_condition,
         TrialN = trial_number) |> 
  mutate(Event = fct_rev(Event)) |> 
  select(Id, Event, TrialN, ReactionTime)
  
LookingTime = vroom::vroom("CONTENT\\Simulation\\simulatedNormal.csv") |> 
  rename(LookingTime = dependent_variable,
         Id = subject_id,
         Event = categorical_condition,
         TrialN = trial_number) |> 
  select(Id, Event, TrialN, LookingTime)

Df = left_join(ReactionTime, LookingTime, by = c("Id", "Event", "TrialN")) |> 
  mutate(Event = fct_recode(Event, NoReward = "Hammer", Reward = "Spoon"))
Df[is.na(Df$ReactionTime ),]$LookingTime = NA


write_csv(Df, "resources\\Stats\\Dataset.csv")


# Models ------------------------------------------------------------------


mod_l = lmer(LookingTime ~ Event * TrialN + (1 + TrialN | Id), data = Df)

# Mixed-Effects Model using Gamma distribution
Df$Stand_TrialN = datawizard::standardise(Df$TrialN)
mod_gam = glmer(ReactionTime ~ Event * Stand_TrialN + 
                  (1 + Stand_TrialN | Id),
                family = Gamma(link = 'log'), data = Df)


# Plot --------------------------------------------------------------------



D1 = ggplot(Df, aes(x = LookingTime, fill = Event)) +
  geom_density(color = 'transparent', alpha = 0.3) +
  geom_density(fill = 'transparent', color = 'black', lwd =2)+
  theme_minimal()+
  theme(legend.position = "bottom")

D2 = ggplot(Df, aes(x = ReactionTime, fill = Event)) +
  geom_density(color = 'transparent', alpha = 0.3) +
  geom_density(fill = 'transparent', color = 'black', lwd =2)+
  theme_minimal()+
  theme(legend.position = "bottom")


D1 + D2
ggsave("CONTENT\\Simulation\\CombinedDensity.png", width = 20, height = 20, dpi  = 300)


plot(estimate_relation(mod_l), by = c('TrialN', 'Event'))
plot(estimate_relation(mod_l), by = c('Event', 'TrialN'))


plot(estimate_expectation(mod_l, by = c('TrialN', 'Event'), transform = T))



