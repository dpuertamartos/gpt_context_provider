#!/usr/bin/env bats

# Load the helpers for bats-assert and bats-support
load 'test/test_helper/bats-support/load'
load 'test/test_helper/bats-assert/load'

# Test setup - create directories and files for testing
setup() {
    rm -rf test_dir
    mkdir -p test_dir
    mkdir -p test_dir/nested_dir
    touch test_dir/file1.txt
    echo "This is file1 content." > test_dir/file1.txt
    touch test_dir/file2.txt
    echo "This is file2 content." > test_dir/file2.txt
    touch test_dir/nested_dir/file3.txt
    echo "This is file3 content in nested_dir." > test_dir/nested_dir/file3.txt
    touch test_dir/nested_dir/file4.txt
    echo "This is file4 content in nested_dir." > test_dir/nested_dir/file4.txt

    # Ignore file2.txt in the root directory
    echo "file2.txt" > test_dir/.gitignore
    echo "Test Prompt" > test_dir/CoT_prompt.txt  # Sample CoT prompt file inside test_dir

    # Creating nested .gitignore and .gptignore files (for additional test cases)
    echo "file4.txt" > test_dir/nested_dir/.gitignore
    echo "file3.txt" > test_dir/nested_dir/.gptignore
}

# Test teardown - clean up the test files
teardown() {
    echo "Debug: Removing test files"
    cd ..  # Move out of test_dir before removing it
    rm -rf test_dir
}

# Check if a file exists using Bash's built-in `[ -f ]` command
assert_file_exists() {
    local file=$1
    [ -f "$file" ] || fail "Expected file '$file' to exist"
}

# Check if a file contains a specific string using `grep`
assert_file_contains() {
    local file=$1
    local content=$2
    grep -q "$content" "$file" || fail "Expected file '$file' to contain '$content'"
}

# Check if a file does not contain a specific string using `grep`
assert_file_not_contains() {
    local file=$1
    local content=$2

    # Debugging output to show what we're testing
    echo "Debug: Checking that $file does not contain \"$content\""
    
    if grep -q "$content" "$file"; then
        echo "Debug: Content \"$content\" was found in $file"
        fail "Expected file '$file' to not contain '$content'"
    else
        echo "Debug: Content \"$content\" was not found in $file"
    fi
}

# Test case 1: Invalid number of arguments
@test "Invalid number of arguments" {
    cd test_dir
    run ../consolidate_files.sh
    [ "$status" -eq 1 ]
    assert_output --partial "Usage: ../consolidate_files.sh <directory_to_explore> [-m think] [output_file]"
}

# Test case 2: Directory does not exist
@test "Directory does not exist" {
    cd test_dir
    run ../consolidate_files.sh non_existent_directory
    [ "$status" -eq 1 ]
    assert_output --partial "The directory non_existent_directory does not exist."
}

# Test case 3: Default output file without -m argument
@test "Default output file without -m argument" {
    cd test_dir
    run ../consolidate_files.sh .
    [ "$status" -eq 0 ]
    assert_file_exists "gpt_context_output.txt"
    echo "Debug: Contents of gpt_context_output.txt"
    cat gpt_context_output.txt  # Display the contents of the file for inspection
    assert_file_contains "gpt_context_output.txt" "This is file1 content."
    assert_file_not_contains "gpt_context_output.txt" "This is file2 content"  # .gitignore should exclude file2.txt
}

# Test case 4: Custom output file without -m argument
@test "Custom output file without -m argument" {
    cd test_dir
    run ../consolidate_files.sh . custom_output.txt
    [ "$status" -eq 0 ]
    assert_file_exists "custom_output.txt"
    assert_output --partial "All files have been processed into custom_output.txt"
    assert_file_contains "custom_output.txt" "This is file1 content."
    assert_file_not_contains "custom_output.txt" "This is file2 content."
}

# Test case 5: -m think mode with default output file
@test "-m think mode with default output file" {
    cd test_dir
    run ../consolidate_files.sh . -m think
    [ "$status" -eq 0 ]
    assert_file_exists "gpt_context_output.txt"
    assert_file_contains "gpt_context_output.txt" "Test Prompt"  # CoT_prompt.txt content should be included
    assert_file_contains "gpt_context_output.txt" "This is file1 content."
    assert_file_not_contains "gpt_context_output.txt" "This is file2 content."
}

# Test case 6: -m think mode with custom output file
@test "-m think mode with custom output file" {
    cd test_dir
    run ../consolidate_files.sh . -m think custom_output.txt
    [ "$status" -eq 0 ]
    assert_file_exists "custom_output.txt"
    assert_file_contains "custom_output.txt" "Test Prompt"
    assert_file_contains "custom_output.txt" "This is file1 content."
    assert_file_not_contains "custom_output.txt" "This is file2 content."
}

# Test case 7: .gitignore file handling
@test ".gitignore file handling" {
    cd test_dir
    run ../consolidate_files.sh .
    [ "$status" -eq 0 ]
    assert_file_exists "gpt_context_output.txt"
    assert_file_contains "gpt_context_output.txt" "This is file1 content."
    assert_file_not_contains "gpt_context_output.txt" "This is file2 content."
}

# Test case 8: .gptignore file handling
@test ".gptignore file handling" {
    cd test_dir
    echo "file1.txt" > .gptignore  # Ignore file1.txt for this test
    rm .gitignore
    run ../consolidate_files.sh .
    [ "$status" -eq 0 ]
    assert_file_exists "gpt_context_output.txt"
    assert_file_not_contains "gpt_context_output.txt" "This is file1 content."
    assert_file_contains "gpt_context_output.txt" "This is file2 content."
}

# Test case 9: Unsupported mode with -m
@test "Unsupported mode with -m" {
    cd test_dir
    run ../consolidate_files.sh . -m unsupported_mode
    [ "$status" -eq 1 ]
    assert_output --partial "Error: Mode 'unsupported_mode' does not exist. Only 'think' mode is supported."
}

# Test case 10: Handle Nested Directories
@test "Handle Nested Directories" {
    cd test_dir
    run ../consolidate_files.sh .
    [ "$status" -eq 0 ]
    assert_file_exists "gpt_context_output.txt"
    assert_file_contains "gpt_context_output.txt" "This is file1 content."
    assert_file_contains "gpt_context_output.txt" "This is file3 content in nested_dir."
}

# Test case 11: Ignore Nested Directories Using .gitignore
@test "Ignore Nested Directories Using .gitignore" {
    cd test_dir
    echo "nested_dir/" > .gitignore  # Ignore the entire nested_dir
    run ../consolidate_files.sh .
    [ "$status" -eq 0 ]
    assert_file_exists "gpt_context_output.txt"
    assert_file_contains "gpt_context_output.txt" "This is file1 content."
    assert_file_not_contains "gpt_context_output.txt" "This is file3 content in nested_dir."
}

# Test case 12: Nested `.gitignore` inside a subdirectory (should not be used)
@test "Nested .gitignore in subdirectory should not affect parent" {
    cd test_dir
    echo "file3.txt" > nested_dir/.gitignore  # Ignore file3.txt only in nested_dir
    run ../consolidate_files.sh .
    [ "$status" -eq 0 ]
    assert_file_exists "gpt_context_output.txt"
    assert_file_contains "gpt_context_output.txt" "This is file1 content."
    assert_file_contains "gpt_context_output.txt" "This is file3 content in nested_dir."
    assert_file_contains "gpt_context_output.txt" "This is file4 content in nested_dir."
}

# Test case 13: Complex nested directories with .gitignore and .gptignore
@test "Complex nested directories with .gitignore and .gptignore" {
    cd test_dir
    echo "file3.txt" > .gptignore  # Ignore file3.txt globally
    echo "nested_dir/file4.txt" > .gitignore  # Ignore file4.txt in nested_dir
    run ../consolidate_files.sh .
    [ "$status" -eq 0 ]
    assert_file_exists "gpt_context_output.txt"
    assert_file_contains "gpt_context_output.txt" "This is file1 content."
    assert_file_not_contains "gpt_context_output.txt" "This is file3 content in nested_dir."  # .gptignore should exclude file3.txt globally
    assert_file_not_contains "gpt_context_output.txt" "This is file4 content in nested_dir."  # .gitignore should exclude file4.txt in nested_dir
}
