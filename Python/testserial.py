import serial

# UART Configuration
uart = serial.Serial(port='COM4', baudrate=115200, timeout=1)  # Adjust port to match your setup
output_file = "x_100.txt"

# Open a file to save the data
with open(output_file, "w") as file:
    print("Receiving data... Press Ctrl+C to stop.")
    try:
        while True:
            data = uart.readline().decode().strip()  # Read and decode UART data
            if data:
                if ";" in data:  # Ensure complete data line has been received
                    file.write(data.replace(";", "") + "\n")  # Save to file without semicolon
                    print(data)  # Optional: print to console
    except KeyboardInterrupt:
        print("\nStopped by user.")
        print(f"Data saved to {output_file}.")
