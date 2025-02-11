# Define the number of words and create the list of values
num_words = 4096
words = [0] * num_words

# Set the specified values
for i in range(0, num_words, 64):
    words[i] = (i // 64) + 1
    if i > 0:
        words[i] = 64 * (i // 64)

# Also set values for every 63rd word
for i in range(63, num_words, 64):
    words[i] = (i // 64) + 1

# Write the words to a text file, each on a new line
with open('w_test.txt', 'w') as file:
    for word in words:
        file.write(f"{word:016b}\n")
