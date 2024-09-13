# Example Python script to convert binary text file to COE format with binary radix
def bin_txt_to_coe(input_file, output_file, radix=2):
    with open(input_file, 'r') as f:
        data = f.readlines()
    
    with open(output_file, 'w') as f:
        f.write(f"memory_initialization_radix={radix};\n")
        f.write("memory_initialization_vector=\n")
        
        for i, line in enumerate(data):
            binary_value = line.strip()  # Keep the binary value as is
            f.write(f"{binary_value}")
            
            if i < len(data) - 1:
                f.write(",\n")  # Add a comma between entries
            else:
                f.write(";\n")  # Semicolon to end the vector

# Example usage:
bin_txt_to_coe("Wf_f.txt", "Wf.coe", radix=2)
