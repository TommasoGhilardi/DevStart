import numpy as np
import pandas as pd
import matplotlib.pyplot as plt



def set_and_record_seed(seed=None):
    if seed is None:
        seed = np.random.randint(0, 1000000)  # Generate a random seed if not provided
    np.random.seed(seed)
    print(f"The seed used was: {seed}")
    return seed

seed = set_and_record_seed()


# Define the time variable ranging from 50 to 120 in steps of 0.25
time = np.linspace(50, 120, num=100)  # Same number of steps as before

# Number of subjects
n_subjects = 25

# Define the tools
tools = ['spoon', 'hammer', 'brush']

# Define intercept and slope parameters together for each tool
tool_params = {
    'spoon': {'intercept_mean': 5, 'intercept_std_dev': 4, 'slope_mean': 0.5, 'slope_std_dev': 0.3, 'noise': 6},
    'hammer': {'intercept_mean': 5, 'intercept_std_dev': 2, 'slope_mean': 0.1, 'slope_std_dev': 0.05, 'noise': 15},
    'brush': {'intercept_mean': 3, 'intercept_std_dev': 2, 'slope_mean': 0.05, 'slope_std_dev': 0.1, 'noise': 11}
}

# Generate intercepts and slopes for each tool
true_params = {
    tool: {
        'intercepts': np.random.normal(loc=tool_params[tool]['intercept_mean'], scale=tool_params[tool]['intercept_std_dev'], size=n_subjects),
        'slopes': np.random.normal(loc=tool_params[tool]['slope_mean'], scale=tool_params[tool]['slope_std_dev'], size=n_subjects)
    }
    for tool in tools
}

# Simulate performance data with noise
performance_data = []

for tool in tools:
    for i in range(n_subjects):
        performance = true_params[tool]['intercepts'][i] + true_params[tool]['slopes'][i] * time + np.random.normal(0, tool_params[tool]['noise'], size=len(time))
        subject_data = pd.DataFrame({
            'subject': i+1,
            'time': time,
            'performance': performance,
            'tool': tool
        })
        # Introduce random missing data (about 10% missing)
        missing_indices = np.random.choice(subject_data.index, size=int(len(subject_data) * 0.1), replace=False)
        subject_data.loc[missing_indices, 'performance'] = np.nan
        
        performance_data.append(subject_data)

# Combine all subjects' data into one DataFrame
df = pd.concat(performance_data)

# Plot the simulated data for each tool in separate subplots
fig, axes = plt.subplots(1, 3, figsize=(18, 6), sharey=True)

for idx, tool in enumerate(tools):
    ax = axes[idx]
    for i in range(n_subjects):
        subject_data = df[(df['subject'] == i+1) & (df['tool'] == tool)]
        ax.plot(subject_data['time'], subject_data['performance'], label=f'Subject {i+1}')
        ax.scatter(subject_data['time'], subject_data['performance'])
    ax.set_title(f'{tool}')
    ax.set_xlabel('Time')
    if idx == 0:
        ax.set_ylabel('Performance')

plt.suptitle('Simulated Performance Data by Time for Each Tool')
plt.tight_layout(rect=[0, 0, 1, 0.95])
plt.show()

# Save the data to a CSV file
df.to_csv(r'C:\Users\tomma\Desktop\DevStart\resources\Stats\LM_SimulatedData.csv', index=False)
