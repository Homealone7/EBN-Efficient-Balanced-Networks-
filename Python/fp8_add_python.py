def fp8_add_python(a, b):
    """Perform FP8 addition in Python (E5M2 FP8 format) with rounding."""
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

    # Align the smaller exponent to the larger one by shifting the mantissa
    if exp_a > exp_b:
        shift = exp_a - exp_b
        mant_b >>= shift  # Right shift mantissa b to align with mantissa a
        exp_out = exp_a
    elif exp_b > exp_a:
        shift = exp_b - exp_a
        mant_a >>= shift  # Right shift mantissa a to align with mantissa b
        exp_out = exp_b
    else:
        exp_out = exp_a  # Exponents are the same

    # Perform addition or subtraction depending on the signs
    if sign_a == sign_b:
        mant_out = mant_a + mant_b
        sign_out = sign_a
    else:
        if mant_a > mant_b:
            mant_out = mant_a - mant_b
            sign_out = sign_a
        else:
            mant_out = mant_b - mant_a
            sign_out = sign_b

    # Handle overflow in mantissa (normalization)
    guard = (mant_out >> 2) & 0x1  # Guard bit (bit just after the last mantissa bit)
    round_bit = (mant_out >> 1) & 0x1  # Round bit (bit after the guard bit)
    sticky = mant_out & 0x1  # Sticky bit (remaining bits after the round bit)

    # Check if the result needs to be normalized
    if mant_out >= 0x8:  # Mantissa overflow (larger than 3 bits after addition)
        mant_out >>= 1  # Shift right and increase exponent
        exp_out += 1

    # Now apply rounding logic based on the guard and round bits
    if guard == 1 and (round_bit == 1 or sticky == 1 or (mant_out & 0x1) == 1):
        mant_out += 1  # Round up if needed

    # Normalize result again after rounding if needed
    if mant_out >= 0x8:  # Mantissa overflow after rounding
        mant_out >>= 1  # Shift right and increase exponent again
        exp_out += 1

    # Pack the result into FP8 format
    mant_out &= 0x3  # Keep only the bottom 2 bits of mantissa
    result = (sign_out << 7) | (exp_out << 2) | mant_out  # Combine sign, exponent, mantissa

    return result
  

def compare_results():
    """Compare results from Verilog and Python, focusing on sign and exponent bits."""
    with open('a_rnd.txt', 'r') as f_a, open('b_rnd.txt', 'r') as f_b, open('verilog_fp8_results.txt', 'r') as f_out:
        for line_a, line_b, line_out in zip(f_a, f_b, f_out):
            a_bin = line_a.strip()  # Read from a_rnd.txt
            b_bin = line_b.strip()  # Read from b_rnd.txt
            a = int(a_bin, 2)  # Convert binary string to integer
            b = int(b_bin, 2)

            # Python calculation
            python_result = fp8_add_python(a, b)

            # Verilog result from file (single value per line)
            verilog_result_bin = line_out.strip()  # Only the result in verilog_fp8_results.txt
            verilog_result = int(verilog_result_bin, 2)  # Convert binary string to integer

            # Extract sign, exponent, and mantissa bits for comparison
            python_sign = (python_result >> 7) & 0x1
            python_exp = (python_result >> 2) & 0x1F  # Extract 5-bit exponent
            python_mantissa = python_result & 0x3  # Extract 2-bit mantissa

            verilog_sign = (verilog_result >> 7) & 0x1
            verilog_exp = (verilog_result >> 2) & 0x1F
            verilog_mantissa = verilog_result & 0x3

            # Compare the sign and exponent bits
            if (python_sign != verilog_sign) or (python_exp != verilog_exp):
                print(f"FAIL: a={a_bin}, b={b_bin}, "
                      f"Sign (Verilog={verilog_sign}, Python={python_sign}), "
                      f"Exponent (Verilog={verilog_exp:02X}, Python={python_exp:02X}), "
                      f"Mantissas (Verilog={verilog_mantissa:02b}, Python={python_mantissa:02b})")

if __name__ == "__main__":
    compare_results()