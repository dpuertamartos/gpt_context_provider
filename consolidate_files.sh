#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPT_FILE="$SCRIPT_DIR/CoT_prompt.txt"

# Check if the correct number of arguments was provided
check_arguments() {
    if [ "$#" -lt 1 ] || [ "$#" -gt 4 ]; then
        echo "Usage: $0 <directory_to_explore> [-m think] [output_file]"
        exit 1
    fi
}

# Parse arguments and set variables
parse_arguments() {
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
}

check_directory() {
    if [ ! -d "$DIR" ]; then
        echo "The directory $DIR does not exist."
        exit 1
    fi
}

initialize_output_file() {
    > "$OUTFILE"
}

# Function to append file content with header
append_file_content() {
    local file="$1"
    echo "###%START_CONTENT PATH $file" >> "$OUTFILE" 
    cat "$file" >> "$OUTFILE"   
    echo "###%END_CONTENT PATH $file" >> "$OUTFILE"
    echo "" >> "$OUTFILE"    
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

# Process .gitignore and .gptignore files
process_ignore_file() {
    local ignore_file="$1"
    local current_dir="$2"
    local -n find_params_ref="$3"

    if [ -f "$ignore_file" ]; then
        echo "Found $ignore_file in $current_dir"
        while IFS='' read -r line || [[ -n "$line" ]]; do
            line=$(echo "$line" | tr -d '\r')  # Remove Windows carriage returns if any
            [[ "$line" = "" || "$line" =~ ^#.*$ ]] && continue
            
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
    find "$current_dir" "${find_params[@]}" -exec bash -c 'append_file_content "$0"' {} \;
}

main() {
    check_arguments "$@"
    parse_arguments "$@"
    check_directory
    initialize_output_file

    echo "### Description of PROBLEM TO SOLVE:" >> "$OUTFILE"
    echo "{}" >> "$OUTFILE"

    if [ "$2" == "-m" ] && [ "$3" == "think" ]; then
        insert_prompt_content
    fi

    echo "###------ End of instructions. NOW CODE CONTEXT WILL BE PROVIDED. FULLY UNDERSTAND IT BEFORE STARTING YOUR THINKING ------###" >> "$OUTFILE"

    process_directory "$DIR"
    echo "All files have been processed into $OUTFILE."
}

# Execute the main function with arguments
main "$@"
