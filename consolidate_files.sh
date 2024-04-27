#!/bin/bash

# Check if the correct number of arguments was provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <directory_to_explore> <output_file>"
    exit 1
fi

# Variables for directory and output file
DIR="$1"
OUTFILE="${2:-$(basename "$DIR").txt}"

# Check if the directory exists
if [ ! -d "$DIR" ]; then
    echo "The directory $DIR does not exist."
    exit 1
fi

# Creating/Clearing the output file
> "$OUTFILE"

# Function to append file content with header
append_file_content() {
    echo "# $1" >> "$OUTFILE" # Append the file path as a comment
    cat "$1" >> "$OUTFILE"   # Append the file content
    echo "" >> "$OUTFILE"    # Append a newline for separation
}

# Export the function so it can be used by child processes
export -f append_file_content
export OUTFILE

# Find all files in the directory and process them
find "$DIR" -type f -exec bash -c 'append_file_content "$0"' {} \;

echo "All files have been processed into $OUTFILE."