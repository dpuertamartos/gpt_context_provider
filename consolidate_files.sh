#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPT_FILE="$SCRIPT_DIR/CoT_prompt.txt"

# Check if the correct number of arguments was provided
if [ "$#" -lt 1 ] || [ "$#" -gt 4 ]; then
    echo "Usage: $0 <directory_to_explore> [-m think] [output_file]"
    exit 1
fi

# Variables for directory, optional mode, and output file
DIR="$1"

# If no mode is provided, check for the output file in position 2, otherwise default
if [ "$2" != "-m" ]; then
    OUTFILE="${2:-gpt_context_output.txt}"
else
    OUTFILE="${4:-gpt_context_output.txt}"  # Output file provided as 4th argument if -m is present
fi

# Check if the second argument is '-m' and the mode is 'think'
if [ "$2" == "-m" ]; then
    if [ "$3" != "think" ]; then
        echo "Error: Mode '$3' does not exist. Only 'think' mode is supported."
        exit 1
    fi
fi

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

# Function to insert CoT_prompt.txt content if mode is 'think'
insert_prompt_content() {
    if [ -f "$PROMPT_FILE" ]; then
        echo "###------ Follow these instructions to solve the PROBLEM, this is crucial: " >> "$OUTFILE"
        cat "$PROMPT_FILE" >> "$OUTFILE"
        echo "" >> "$OUTFILE"
    else
        echo "Error: CoT_prompt.txt file not found in the script's directory ($SCRIPT_DIR)."
        exit 1
    fi
}

echo "### Description of PROBLEM TO SOLVE:" >> "$OUTFILE"
echo "{}" >> "$OUTFILE"

# Insert the CoT prompt content if the -m think option was provided
if [ "$2" == "-m" ] && [ "$3" == "think" ]; then
    insert_prompt_content
fi

echo "###------ End of instructions. NOW CODE CONTEXT WILL BE PROVIDED. FULLY UNDERSTAND IT BEFORE STARTING YOUR THINKING ------###" >> "$OUTFILE"


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
            
            if [[ -d "$current_dir/$line" || "$line" == */ ]]; then
                find_params_ref+=('!' '-path' "$current_dir/${line%/}/*" '-prune')
                echo "Adding directory to exclude: '$current_dir/${line%/}/*'"
            elif [[ "$line" == */* ]]; then
                find_params_ref+=('!' '-path' "$current_dir/$line")
                echo "Adding file to exclude: '$current_dir/$line'"
            else
                find_params_ref+=('!' '-name' "$line")
                echo "Adding global pattern to exclude: '$line'"
            fi
        done < "$ignore_file"
    fi
}

# Recursive function to process directories
process_directory() {
    local current_dir="$1"
    local find_params=()

    find_params+=('-type' 'f')
    find_params+=('!' '-path' "$current_dir/.git/*" '-prune')
    find_params+=('!' '-name' ".gptignore")
    find_params+=('!' '-name' "$(basename "$OUTFILE")")

    echo "Processing directory: $current_dir"
    process_ignore_file "$current_dir/.gitignore" "$current_dir" find_params
    process_ignore_file "$current_dir/.gptignore" "$current_dir" find_params

    echo "find command: find $current_dir ${find_params[@]}"
    find "$current_dir" "${find_params[@]}" -exec bash -c 'append_file_content "$0"' {} \;
}

# Process the directory
process_directory "$DIR"

echo "All files have been processed into $OUTFILE."
