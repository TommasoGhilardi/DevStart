from psychopy import visual, core
import tobii_research
# Create a window with size 400x400
win = visual.Window(
    size=(600, 400),
    color='white',
    units='pix'
)

# Create the countdown text stimulus
countdown_text = visual.TextStim(
    win,
    text='',
    color='black',
    height=50
)

# Show countdown from 3 to 1
for i in range(3, 0, -1):
    countdown_text.text = str(i)
    countdown_text.draw()
    win.flip()
    core.wait(1)

# Create the final message text stimulus
message = visual.TextStim(
    win,
    text='Fantastic!!\nYou are ready\nfor the workshop!!',
    color='black',
    height=30
)

# Draw the final message
message.draw()
win.flip()

# Wait for 5 seconds to display the message
core.wait(5)

# Close the window
win.close()

# Quit PsychoPy
core.quit()
