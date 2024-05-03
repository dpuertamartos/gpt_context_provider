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

    echo "###%START_CONTENT PATH" $1 >> "$OUTFILE" # Append the file path as a comment
    cat "$1" >> "$OUTFILE"   # Append the file content
    echo "###%END_CONTENT PATH" $1 >> "$OUTFILE"
    echo "" >> "$OUTFILE"    # Append a newline for separation
}

# Export the function so it can be used by child processes
export -f append_file_content
export OUTFILE

# Recursive function to process directories
process_directory() {
    local current_dir="$1"
    local gitignore="$current_dir/.gitignore"
    local find_params=('-type' 'f') # Default parameter to find files

    # Exclude all files and directories starting with a dot
    find_params+=('!' '-path' "${current_dir}/.*" '-prune')

    echo "Processing directory: $current_dir"

    # Handle .gitignore if it exists in the current directory
    if [ -f "$gitignore" ]; then
        echo "Found .gitignore in $current_dir"
        while IFS='' read -r line || [[ -n "$line" ]]; do
            line=$(echo "$line" | tr -d '\r')  # Remove Windows carriage returns if any
            [[ "$line" = "" || "$line" =~ ^#.*$ ]] && continue
            echo "Reading line from .gitignore: '$line'"
            if [[ "$line" == */ ]] || [[ ! "$line" == *.* ]]; then
                # Treat as a directory
                find_params+=('!' '-path' "${current_dir}/${line%/}/*" '-prune')
                echo "Adding directory to exclude: '${current_dir}/${line%/}/*'"
            else
                # Treat as a file or file pattern
                find_params+=('!' '-path' "${current_dir}/${line}")
                echo "Adding file to exclude: '${current_dir}/${line}'"
            fi
        done < "$gitignore"
    fi

    # Display the find command to be executed
    echo "find command: find $current_dir ${find_params[@]}"
    
    # Execute find, excluding specified patterns and directories
    find "$current_dir" "${find_params[@]}" -exec bash -c 'append_file_content "$0"' {} \;
}

# Process the directory
process_directory "$DIR"

echo "All files have been processed into $OUTFILE."



