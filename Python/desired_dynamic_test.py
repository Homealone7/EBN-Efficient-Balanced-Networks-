import numpy as np
import matplotlib.pyplot as plt
import math

# FP8 Multiplication function
def fp8_mult_python(a, b):
    # Extract components from inputs A and B
    a_sign = (a >> 7) & 0x1
    a_exp = (a >> 2) & 0x1F
    a_mant = (a & 0x3) | 0x4  # Add hidden bit

    b_sign = (b >> 7) & 0x1
    b_exp = (b >> 2) & 0x1F
    b_mant = (b & 0x3) | 0x4  # Add hidden bit

    # Calculate product sign, exponent, and mantissa
    product_sign = a_sign ^ b_sign
    product_exp = a_exp + b_exp - 15
    mult_mant = a_mant * b_mant

    # Normalize mantissa
    if mult_mant & 0x20:  # Overflow in mantissa
        round_mant = (mult_mant >> 1) & 0xF
        product_exp += 1
    else:
        round_mant = mult_mant & 0xF

    # Rounding
    if (round_mant & 0x3) == 0x2 and (round_mant & 0x1) == 0:
        product_mant = (round_mant >> 2) & 0x3
    else:
        product_mant = ((round_mant >> 2) & 0x3) + 1

    # Handle special cases
    if product_exp > 30:
        return 0x7B  # Overflow case
    if product_exp < 0:
        return 0x01  # Underflow case
    if (a & 0x7F) == 0 or (b & 0x7F) == 0:
        return 0  # One of the inputs is zero

    # Construct result
    result = (product_sign << 7) | (product_exp << 2) | product_mant
    return result

# FP8 Addition function
def fp8_add_python(a, b, add=True):
    # Extract components from inputs A and B
    a_sign = (a >> 7) & 0x1
    a_exp = (a >> 2) & 0x1F
    a_mant = (a & 0x3) | 0x4  # Add hidden bit

    b_sign = (b >> 7) & 0x1
    b_exp = (b >> 2) & 0x1F
    b_mant = (b & 0x3) | 0x4  # Add hidden bit

    # Assign larger number to 'a'
    if (a & 0x7F) < (b & 0x7F):
        a, b = b, a
        a_sign, b_sign = b_sign, a_sign
        a_exp, b_exp = b_exp, a_exp
        a_mant, b_mant = b_mant, a_mant

    # Determine if we are adding or subtracting
    add_sub = (a_sign == b_sign) if add else (a_sign != b_sign)
    exp_shift = max(0, a_exp - b_exp)

    # Align b mantissa with a exponent
    b_mant >>= exp_shift

    if add_sub:
        # Addition
        mant_sum = a_mant + b_mant
        if mant_sum & 0x20:  # Check for overflow
            mant_sum >>= 1
            a_exp += 1
    else:
        # Subtraction
        mant_sum = a_mant - b_mant
        sub_shift = 0
        if mant_sum != 0:
            while (mant_sum & 0x10) == 0 and sub_shift < 5:
                mant_sum <<= 1
                sub_shift += 1
        a_exp -= sub_shift

    # Rounding
    round_mant = (mant_sum >> 2) & 0xF
    if (round_mant & 0x3) == 0x2 and (round_mant & 0x1) == 0:
        mant_sum = (mant_sum >> 2) & 0x3
    else:
        mant_sum = ((mant_sum >> 2) & 0x3) + 1

    # Handle special cases
    if a_exp > 30:
        return 0x7B  # Overflow case
    if mant_sum == 0:
        return 0  # Result is zero

    # Construct result
    sum_sign = a_sign
    result = (sum_sign << 7) | (a_exp << 2) | mant_sum
    return result

# Load c from text file
with open('Command_8.txt', 'r') as infile:
    c = [int(line.strip(), 2) for line in infile]

# Step 2: Write the values to 'c_out.txt' for verification
with open('c_out_bin.txt', 'w') as outfile:
    for value in c:
        outfile.write(f"{format(value, '08b')}\n")

# Parameters
num_iterations = 15000
dt = 0b00000111  # Binary representation of dt in FP8 (E5M2)
dynprm = 0b11001000 # Binary representation of dynprm in FP8 (E5M2)

# Initialize x (2 elements, initially zero)
x = np.zeros((2, num_iterations + 1), dtype=np.int8)
with open('x_out.txt', 'w') as f:
    for row in x.T:
        binary_row = ' '.join(format(val, '08b') for val in row)
        f.write(binary_row + '\n')

# Time stepping loop
for t in range(num_iterations):
    # Calculate desiredDyn (y1 and y2) using FP8 multiplication and addition
    step = fp8_mult_python(dt, 0b01000010)
    y1 = fp8_mult_python(dynprm, x[1, t])
    if t < 10:
        print(f"y1 at iteration {t}: {format(y1, '08b')}")
        print(f"x2 at iteration {t}: {format(x[1, t], '08b')}")
    y1 = fp8_add_python(y1, x[0, t], add=False)
    if t < 10:
        print(f"y1 at iteration {t}: {format(y1, '08b')}")
    y1 = fp8_mult_python(y1, step)
    if t < 10:
        print(f"y1 at iteration {t}: {format(y1, '08b')}")
    y1 = fp8_add_python(y1, c[2 * t], add=True)
    if t < 10:
        print(f"y1 at iteration {t}: {format(y1, '08b')}")
        print(f"c1 at iteration {t}: {format(c[2 * t], '08b')}")

    y2 = fp8_mult_python(step, x[0, t])
    y2 = fp8_add_python(y2, c[2 * t + 1], add=True)
    
    # Update x for the next iteration using FP8 addition
    x[0, t + 1] = fp8_add_python(x[0, t], y1, add=True)
    x[1, t + 1] = fp8_add_python(x[1, t], y2, add=True)

# Save x to a text file, column-based
with open('x_output_binary.txt', 'w') as f:
    for row in x.T:
        binary_row = ' '.join(format(val, '08b') for val in row)
        f.write(binary_row + '\n')
# Plotting the results
time = np.linspace(0, num_iterations * 0.0001, num_iterations + 1)

plt.figure(figsize=(10, 5))
plt.plot(time, x[0, :], label='x1 (Velocity)', color='b')
plt.plot(time, x[1, :], label='x2 (Position)', color='r')
plt.xlabel('Time')
plt.ylabel('State Variables (FP8 Approximated)')
plt.title('Damped Harmonic Oscillator Dynamics in FP8 E5M2 Format')
plt.legend()
plt.grid()
plt.show()