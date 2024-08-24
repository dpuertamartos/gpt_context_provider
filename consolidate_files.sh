#!/bin/bash

# Check if the correct number of arguments was provided
if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Usage: $0 <directory_to_explore> [output_file]"
    exit 1
fi

# Variables for directory and output file
DIR="$1"
OUTFILE="${2:-gpt_context_output.txt}"  # Default output file name if not provided

# Check if the directory exists
if [ ! -d "$DIR" ]; then
    echo "The directory $DIR does not exist."
    exit 1
fi

# Creating/Clearing the output file
> "$OUTFILE"

# Function to append file content with header
append_file_content() {
    local file="$1"
    echo "###%START_CONTENT PATH $file" >> "$OUTFILE" # Append the file path as a comment
    cat "$file" >> "$OUTFILE"   # Append the file content
    echo "###%END_CONTENT PATH $file" >> "$OUTFILE"
    echo "" >> "$OUTFILE"    # Append a newline for separation
}

# Export the function so it can be used by child processes
export -f append_file_content
export OUTFILE

# Function to process .gitignore and .gptignore files
process_ignore_file() {
    local ignore_file="$1"
    local current_dir="$2"
    local -n find_params_ref="$3"

    if [ -f "$ignore_file" ]; then
        echo "Found $ignore_file in $current_dir"
        while IFS='' read -r line || [[ -n "$line" ]]; do
            line=$(echo "$line" | tr -d '\r')  # Remove Windows carriage returns if any
            [[ "$line" = "" || "$line" =~ ^#.*$ ]] && continue
            echo "Reading line from $ignore_file: '$line'"
            
            # Check if the pattern is a directory, a file, or a global pattern
            if [[ -d "$current_dir/$line" || "$line" == */ ]]; then
                # Treat as a directory and exclude its contents recursively
                find_params_ref+=('!' '-path' "$current_dir/${line%/}/*" '-prune')
                echo "Adding directory to exclude: '$current_dir/${line%/}/*'"
            elif [[ "$line" == */* ]]; then
                # Treat as a specific file or pattern with path
                find_params_ref+=('!' '-path' "$current_dir/$line")
                echo "Adding file to exclude: '$current_dir/$line'"
            else
                # Treat as a global pattern that applies to all subdirectories
                find_params_ref+=('!' '-name' "$line")
                echo "Adding global pattern to exclude: '$line'"
            fi
        done < "$ignore_file"
    fi
}

# Recursive function to process directories
process_directory() {
    local current_dir="$1"
    local find_params=() # Initialize find parameters

    # Add default parameter to find files
    find_params+=('-type' 'f')

    # Exclude .git folder by default
    find_params+=('!' '-path' "$current_dir/.git/*" '-prune')
    echo "Adding .git directory to exclude (by default): '$current_dir/.git/*'"

    # Exclude .gptignore file by default
    find_params+=('!' '-name' ".gptignore")
    echo "Adding .gptignore files in directory to exclude (by default): '.gptignore'"
    
    # Exclude the output file from the search
    find_params+=('!' '-name' "$(basename "$OUTFILE")")

    echo "Processing directory: $current_dir"

    # Handle .gitignore if it exists in the current directory
    process_ignore_file "$current_dir/.gitignore" "$current_dir" find_params

    # Handle .gptignore if it exists in the current directory
    process_ignore_file "$current_dir/.gptignore" "$current_dir" find_params

    # Display the find command to be executed
    echo "find command: find $current_dir ${find_params[@]}"
    
    # Execute find, excluding specified patterns and directories
    find "$current_dir" "${find_params[@]}" -exec bash -c 'append_file_content "$0"' {} \;
}

# Process the directory
process_directory "$DIR"

echo "All files have been processed into $OUTFILE."
