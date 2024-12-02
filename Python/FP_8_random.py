import random

def generate_fp8_number():
    """Generate a random FP8 E5M2 number in binary format."""
    sign = random.randint(0, 1)  # 1-bit sign
    exponent = random.randint(0, 31)  # 5-bit exponent
    mantissa = random.randint(0, 3)  # 2-bit mantissa
    fp8 = (sign << 7) | (exponent << 2) | mantissa
    return fp8

def write_random_numbers(num_pairs=50):
    """Write 50 random FP8 numbers into two separate text files."""
    
    # Open the two files, one for 'a' and one for 'b'
    with open('a_rnd.txt', 'w') as a_file, open('b_rnd.txt', 'w') as b_file:
        for _ in range(num_pairs):
            a = generate_fp8_number()
            b = generate_fp8_number()
            
            # Write the random FP8 numbers to their respective files in binary format
            a_file.write(f'{a:08b}\n')
            b_file.write(f'{b:08b}\n')

if __name__ == "__main__":
    write_random_numbers(50)
