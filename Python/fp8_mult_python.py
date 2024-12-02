def fp8_mult_python(a, b):
    """Perform FP8 multiplication in Python (E5M2 FP8 format)."""
    # Extract sign, exponent, and mantissa for a
    sign_a = (a >> 7) & 0x1
    exp_a = (a >> 2) & 0x1F  # 5-bit exponent
    mant_a = a & 0x3  # 2-bit mantissa
    mant_a = mant_a | 0x4  # Add hidden bit (implicit leading 1)

    # Extract sign, exponent, and mantissa for b
    sign_b = (b >> 7) & 0x1
    exp_b = (b >> 2) & 0x1F
    mant_b = b & 0x3
    mant_b = mant_b | 0x4  # Add hidden bit (implicit leading 1)

    # Calculate the sign of the result
    sign_out = sign_a ^ sign_b

    # Multiply the mantissas (result will be up to 6 bits)
    mant_out = mant_a * mant_b

    # Add the exponents and adjust for the bias (15 for E5M2)
    exp_out = exp_a + exp_b - 15

    # Normalize the result if needed
    if mant_out >= 0x20:  # If mantissa is 6 bits (overflow), shift right
        mant_out >>= 1
        exp_out += 1

    # Handle cases where exponent goes out of range (overflow/underflow)
    if exp_out < 0:
        # Underflow to zero
        exp_out = 0
        mant_out = 0
        sign_out = 0
    elif exp_out > 31:
        # Overflow to infinity
        exp_out = 31
        mant_out = 0

    # Apply rounding based on the guard bits
    guard = (mant_out >> 2) & 0x1  # Guard bit (bit just after the last mantissa bit)
    round_bit = (mant_out >> 1) & 0x1  # Round bit (bit after the guard bit)
    sticky = mant_out & 0x1  # Sticky bit (remaining bits after the round bit)

    # Round to nearest even if guard bit is set
    if guard == 1 and (round_bit == 1 or sticky == 1 or (mant_out & 0x1) == 1):
        mant_out += 1  # Round up

    # Normalize again if rounding caused an overflow
    if mant_out >= 0x8:  # Mantissa overflow after rounding
        mant_out >>= 1
        exp_out += 1

    # Pack the result into FP8 format
    mant_out &= 0x3  # Keep only the bottom 2 bits of mantissa
    result = (sign_out << 7) | (exp_out << 2) | mant_out  # Combine sign, exponent, mantissa

    return result

def compare_mult_results():
    """Compare multiplication results from Verilog and Python."""
    with open('a_rnd.txt', 'r') as f_a, open('b_rnd.txt', 'r') as f_b, open('verilog_fp8_Mult_results.txt', 'r') as f_out:
        for line_a, line_b, line_out in zip(f_a, f_b, f_out):
            a_bin = line_a.strip()  # Read from a_rnd.txt
            b_bin = line_b.strip()  # Read from b_rnd.txt
            a = int(a_bin, 2)  # Convert binary string to integer
            b = int(b_bin, 2)

            # Python calculation for multiplication
            python_result = fp8_mult_python(a, b)

            # Verilog result from file (single value per line)
            verilog_result_bin = line_out.strip()  # Only the result in verilog_fp8_Mult_results.txt
            verilog_result = int(verilog_result_bin, 2)  # Convert binary string to integer

            # Extract sign, exponent, and mantissa bits for comparison
            python_sign = (python_result >> 7) & 0x1
            python_exp = (python_result >> 2) & 0x1F  # Extract 5-bit exponent
            python_mantissa = python_result & 0x3  # Extract 2-bit mantissa

            verilog_sign = (verilog_result >> 7) & 0x1
            verilog_exp = (verilog_result >> 2) & 0x1F
            verilog_mantissa = verilog_result & 0x3

            # Compare the sign, exponent, and mantissa bits and print in hex
            if (python_sign != verilog_sign) or (python_exp != verilog_exp) or (python_mantissa != verilog_mantissa):
                print(f"FAIL: a=0x{a:02X}, b=0x{b:02X}, "
                      f"Sign (Verilog={verilog_sign:X}, Python={python_sign:X}), "
                      f"Exponent (Verilog=0x{verilog_exp:X}, Python=0x{python_exp:X}), "
                      f"Mantissas (Verilog=0x{verilog_mantissa:X}, Python=0x{python_mantissa:X}), "
                      f"Full Verilog Result=0x{verilog_result:02X}")
            else:
                print(f"PASS: a=0x{a:02X}, b=0x{b:02X}, "
                      f"Full Verilog Result=0x{verilog_result:02X}")

if __name__ == "__main__":
    compare_mult_results()

