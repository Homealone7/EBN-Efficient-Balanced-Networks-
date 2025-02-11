import numpy as np
import matplotlib.pyplot as plt

# Load the float32 data from x_32.bin for comparison
filename_fp32 = 'x_32.bin'
data_fp32 = np.fromfile(filename_fp32, dtype=np.float32)

# Ensure the data length is even to avoid dimension mismatch
if len(data_fp32) % 2 != 0:
    data_fp32 = data_fp32[:-1]

# Reshape the data to the original matrix size (2 rows, -1 columns)
data_matrix_fp32 = data_fp32.reshape((2, -1), order='F')

# Extract velocity and position from float32 data
velocity_fp32 = data_matrix_fp32[0, :]
position_fp32 = data_matrix_fp32[1, :]

# Create time axis assuming uniform time steps
time = np.arange(velocity_fp32.size)

# Plot velocity comparison
plt.figure()
plt.plot(time, velocity_fp32, label='Velocity (x1) - x_fp32', color='red', linestyle=':')
plt.xlabel('Time Step')
plt.ylabel('Velocity (x1)')
plt.title('Velocity vs Time Comparison')
plt.legend()
plt.grid(True)

# Plot position comparison
plt.figure()
plt.plot(time, position_fp32, label='Position (x2) - x_fp32', color='orange', linestyle=':')
plt.xlabel('Time Step')
plt.ylabel('Position (x2)')
plt.title('Position vs Time Comparison')
plt.legend()
plt.grid(True)

# Show both plots
plt.show()
