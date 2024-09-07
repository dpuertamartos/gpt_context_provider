#!/usr/bin/env bats

# Load the helpers for bats-assert and bats-support
load 'test/test_helper/bats-support/load'
load 'test/test_helper/bats-assert/load'

# Test setup - create directories and files for testing
setup() {
    mkdir -p test_dir
    touch test_dir/file1.txt
    echo "This is file1 content." > test_dir/file1.txt
    touch test_dir/file2.txt
    echo "This is file2 content." > test_dir/file2.txt

    echo "file2.txt" > test_dir/.gitignore  # Ignore file2.txt for test
    echo "Test Prompt" > CoT_prompt.txt     # Sample CoT prompt file
}

# Test teardown - clean up the test files
teardown() {
    echo "Debug: Removing test files"
    rm -rf test_dir
    rm -f gpt_context_output.txt custom_output.txt
    rm -f CoT_prompt.txt
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
    run ./consolidate_files.sh
    [ "$status" -eq 1 ]
    assert_output --partial "Usage: ./consolidate_files.sh <directory_to_explore> [-m think] [output_file]"
}

# Test case 2: Directory does not exist
@test "Directory does not exist" {
    run ./consolidate_files.sh non_existent_directory
    [ "$status" -eq 1 ]
    assert_output --partial "The directory non_existent_directory does not exist."
}

# Test case 3: Default output file without -m argument
@test "Default output file without -m argument" {
    run ./consolidate_files.sh test_dir
    [ "$status" -eq 0 ]
    assert_file_exists "gpt_context_output.txt"
    echo "Debug: Contents of gpt_context_output.txt"
    cat gpt_context_output.txt  # Display the contents of the file for inspection
    assert_file_contains "gpt_context_output.txt" "This is file1 content."
    assert_file_not_contains "gpt_context_output.txt" "This is file2 content"  # .gitignore should exclude file2.txt
}

# Test case 4: Custom output file without -m argument
@test "Custom output file without -m argument" {
    run ./consolidate_files.sh test_dir custom_output.txt
    [ "$status" -eq 0 ]
    assert_file_exists "custom_output.txt"
    assert_output --partial "All files have been processed into custom_output.txt"
    assert_file_contains "custom_output.txt" "This is file1 content."
    assert_file_not_contains "custom_output.txt" "This is file2 content."
}

# Test case 5: -m think mode with default output file
@test "-m think mode with default output file" {
    run ./consolidate_files.sh test_dir -m think
    [ "$status" -eq 0 ]
    assert_file_exists "gpt_context_output.txt"
    assert_file_contains "gpt_context_output.txt" "Test Prompt"  # CoT_prompt.txt content should be included
    assert_file_contains "gpt_context_output.txt" "This is file1 content."
    assert_file_not_contains "gpt_context_output.txt" "This is file2 content."
}

# Test case 6: -m think mode with custom output file
@test "-m think mode with custom output file" {
    run ./consolidate_files.sh test_dir -m think custom_output.txt
    [ "$status" -eq 0 ]
    assert_file_exists "custom_output.txt"
    assert_file_contains "custom_output.txt" "Test Prompt"
    assert_file_contains "custom_output.txt" "This is file1 content."
    assert_file_not_contains "custom_output.txt" "This is file2 content."
}

# Test case 7: .gitignore file handling
@test ".gitignore file handling" {
    run ./consolidate_files.sh test_dir
    [ "$status" -eq 0 ]
    assert_file_exists "gpt_context_output.txt"
    assert_file_contains "gpt_context_output.txt" "This is file1 content."
    assert_file_not_contains "gpt_context_output.txt" "This is file2 content."
}

# Test case 8: .gptignore file handling
@test ".gptignore file handling" {
    echo "file1.txt" > test_dir/.gptignore  # Ignore file1.txt for this test
    rm test_dir/.gitignore
    run ./consolidate_files.sh test_dir
    [ "$status" -eq 0 ]
    assert_file_exists "gpt_context_output.txt"
    assert_file_not_contains "gpt_context_output.txt" "This is file1 content."
    assert_file_contains "gpt_context_output.txt" "This is file2 content."
}

# Test case 9: Unsupported mode with -m
@test "Unsupported mode with -m" {
    run ./consolidate_files.sh test_dir -m unsupported_mode
    [ "$status" -eq 1 ]
    assert_output --partial "Error: Mode 'unsupported_mode' does not exist. Only 'think' mode is supported."
}
