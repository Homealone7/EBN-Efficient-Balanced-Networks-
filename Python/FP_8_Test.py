import torch

def to_fp8(tensor, exponent_bits=5, mantissa_bits=2):
    """Convert a tensor to approximate FP8 (E5M2) format using float16."""
    # Simulate FP8 by limiting the precision based on mantissa bits
    scale = 2 ** mantissa_bits
    return torch.round(tensor * scale) / scale

def fp8_add_torch(a_fp16, b_fp16):
    """Perform FP8 addition using PyTorch, approximating FP8 with float16."""
    # Perform addition in float16
    result = a_fp16 + b_fp16
    
    # Convert the result to an approximate FP8 representation
    result_fp8 = to_fp8(result)
    
    return result_fp8

def compare_results():
    """Compare results from Verilog and PyTorch."""
    with open('a_rnd.txt', 'r') as f_a, open('b_rnd.txt', 'r') as f_b, open('verilog_fp8_results.txt', 'r') as f_out:
        for line_a, line_b, line_out in zip(f_a, f_b, f_out):
            a_bin = line_a.strip()  # Read from a_rnd.txt
            b_bin = line_b.strip()  # Read from b_rnd.txt
            a = int(a_bin, 2)  # Convert binary string to integer
            b = int(b_bin, 2)

            # Convert binary integers to PyTorch tensors in float16 format
            a_fp16 = torch.tensor(float(a), dtype=torch.float16)
            b_fp16 = torch.tensor(float(b), dtype=torch.float16)

            # Perform FP8 addition using PyTorch
            python_result_fp8 = fp8_add_torch(a_fp16, b_fp16)

            # Verilog result from file (single value per line)
            verilog_result_bin = line_out.strip()  # Only the result in verilog_fp8_results.txt
            verilog_result = int(verilog_result_bin, 2)  # Convert binary string to integer

            # Convert the PyTorch result back to integer format
            python_result = int(python_result_fp8.item())

            # Compare the results
            if python_result == verilog_result:
                print(f"PASS: a={a_bin}, b={b_bin}, result={verilog_result_bin}")
            else:
                print(f"FAIL: a={a_bin}, b={b_bin}, Verilog result={verilog_result_bin}, Python result={bin(python_result)[2:].zfill(8)}")

if __name__ == "__main__":
    compare_results()
