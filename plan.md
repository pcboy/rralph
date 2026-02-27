Plan: Bash script that prints "IS EVEN" or "IS ODD" based on input.

Input: One integer as command-line argument.  
Output: "IS EVEN" if divisible by 2, "IS ODD" otherwise.  
Error: If no argument or non-integer, print error and exit 1.

Logic: Use % to check remainder. Validate input with regex: ^-?[0-9]+$.

File: odd_even.sh  
Requirements:

- Need to be in bash
- Validate input
- Use conditional with (( ))
- No external tools

Test: 0→EVEN, 7→ODD, -4→EVEN, abc→error, no arg→error

