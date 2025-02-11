import struct
import numpy as np
import matplotlib.pyplot as plt

# Load velocity data from hex text file
def load_hex_velocity(file_name):
    with open(file_name, "r") as file:
        hex_data = file.readlines()
    return [struct.unpack('!f', bytes.fromhex(line.strip()))[0] for line in hex_data]

# Load the float32 data from binary file
def load_binary_data(file_name):
    data_fp32 = np.fromfile(file_name, dtype=np.float32)
    if len(data_fp32) % 2 != 0:  # Ensure the data length is even
        data_fp32 = data_fp32[:-1]
    return data_fp32.reshape((2, -1), order='F')  # Reshape as [velocity, position]

def main():
    # File paths
    hex_file = "xfp64_it_100.txt"
    binary_file = "x_32.bin"

    # Load hex velocity data
    velocity_hex = load_hex_velocity(hex_file)

    # Load binary velocity and position data
    data_matrix_fp32 = load_binary_data(binary_file)
    velocity_fp32 = data_matrix_fp32[0, :]  # First row is velocity

    # Create time axis for both datasets
    time_hex = np.arange(len(velocity_hex))
    time_binary = np.arange(len(velocity_fp32))

    # Plot velocity comparison
    plt.figure(figsize=(10, 6))
    plt.plot(time_hex, velocity_hex, label="Velocity - Estimate", color="blue")
    plt.plot(time_binary, velocity_fp32, label="Velocity - Expected", color="red", linestyle="--")
    plt.title("Velocity Comparison")
    plt.xlabel("Time (steps)")
    plt.ylabel("Velocity")
    plt.legend()
    plt.grid(True)

    # Show the plot
    plt.show()

if __name__ == "__main__":
    main()
