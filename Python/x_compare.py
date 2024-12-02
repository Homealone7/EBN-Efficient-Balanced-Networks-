import numpy as np
import matplotlib.pyplot as plt
import tensorflow as tf

# Load the data from the output text file
filename = 'x_100.txt'
data = []

with open(filename, 'r') as file:
    for line in file:
        x1_hex, x2_hex = line.strip().split(',')
        x1 = int(x1_hex, 16)
        x2 = int(x2_hex, 16)
        data.append([x1, x2])

data = np.array(data, dtype=np.uint16).flatten()

# Convert bfloat16 (uint16) data directly to float32 using TensorFlow
float32_tensor = tf.cast(tf.bitcast(tf.convert_to_tensor(data, dtype=tf.uint16), tf.bfloat16), tf.float32)

# Convert the TensorFlow tensor to a NumPy array for reshaping and plotting
float32_data = float32_tensor.numpy()

# Ensure the data length is even to avoid dimension mismatch
if len(float32_data) % 2 != 0:
    float32_data = float32_data[:-1]

# Reshape the data to the original matrix size (2 rows, -1 columns)
data_matrix = float32_data.reshape((2, -1), order='F')

# Extract velocity and position
velocity = data_matrix[0, :]
position = data_matrix[1, :]

# Load the bfloat16 data from x_bf16.txt for comparison
filename_bf16 = 'x_bf16.bin'
data_bf16 = np.fromfile(filename_bf16, dtype=np.uint16)

# Convert bfloat16 (uint16) data directly to float32 using TensorFlow
float32_tensor_bf16 = tf.cast(tf.bitcast(tf.convert_to_tensor(data_bf16, dtype=tf.uint16), tf.bfloat16), tf.float32)

# Convert the TensorFlow tensor to a NumPy array for reshaping and plotting
float32_data_bf16 = float32_tensor_bf16.numpy()

# Ensure the data length is even to avoid dimension mismatch
if len(float32_data_bf16) % 2 != 0:
    float32_data_bf16 = float32_data_bf16[:-1]

# Reshape the data to the original matrix size (2 rows, -1 columns)
data_matrix_bf16 = float32_data_bf16.reshape((2, -1), order='F')

# Extract velocity and position from bfloat16 data
velocity_bf16 = data_matrix_bf16[0, :]
position_bf16 = data_matrix_bf16[1, :]

# Create time axis assuming uniform time steps
time = np.arange(velocity.size)

# Plot velocity comparison
plt.figure()
plt.plot(time, velocity, label='Velocity (x1) - output_data', color='blue', linestyle='-')
plt.plot(time, velocity_bf16, label='Velocity (x1) - x_bf16', color='red', linestyle=':')
plt.xlabel('Time Step')
plt.ylabel('Velocity (x1)')
plt.title('Velocity vs Time Comparison')
plt.legend()
plt.grid(True)

# Plot position comparison
plt.figure()
plt.plot(time, position, label='Position (x2) - output_data', color='green', linestyle='-')
plt.plot(time, position_bf16, label='Position (x2) - x_bf16', color='orange', linestyle=':')
plt.xlabel('Time Step')
plt.ylabel('Position (x2)')
plt.title('Position vs Time Comparison')
plt.legend()
plt.grid(True)

# Show both plots
plt.show()