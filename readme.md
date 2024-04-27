# File Consolidation Script

This Bash script recursively explores a specified directory, appending the contents of all files found within that directory and its subdirectories into a single text file. Each file's path and name is included in the output as a comment line, followed by the actual contents of the file.

The main utility of this file is to use to give full context of your project to a Large Language Model, such as GPT.

## Features

- **Recursive File Processing**: The script searches through all subdirectories of the specified directory, processing all files.
- **Flexible Output Filename**: If only the directory path is provided when running the script, the output file will automatically be named after the directory, suffixed with `.txt`. If an output file name is provided, the script will use that instead.

## Prerequisites

To use this script, you will need:
- A Unix-like environment (Linux, BSD, macOS)
- Bash shell
- Basic command-line utilities (find, cat, echo)

## Installation

1. Download the script `consolidate_files.sh`.
2. Make the script executable:
```bash
   chmod +x consolidate_files.sh
```

## Usage
To run the script, you can use the following commands:

```bash
./consolidate_files.sh /path/to/directory output.txt
```

This command specifies both the directory to explore and the name of the output file.

```bash
./consolidate_files.sh /path/to/directory
```
If the output filename is not provided, the script will name the output file based on the last segment of the directory path, adding a .txt suffix.

## Notes

The script handles plain text files. Binary files or files with special characters in their names may not be processed correctly.