# File Consolidation Script

This Bash script recursively explores a specified directory, appending the contents of all files found within that directory and its subdirectories into a single text file. Each file's path and name is included in the output as a comment line, followed by the actual contents of the file.

The main utility of this file is to use to give full context of your project to a Large Language Model, such as GPT.

## Features

- **Recursive File Processing**: The script searches through all subdirectories of the specified directory, processing all files.
- **Flexible Output Filename**: If only the directory path is provided when running the script, the output file will automatically be named `gpt_contenxt_output.txt`. If an output file name is provided, the script will use that instead.
- **Ability to Ignore Files**: The script ignores the folders and files in both files **.gitignore** and **.gptignore**

## Prerequisites

To use this script, you will need:

- Bash shell
- Basic command-line utilities (find, cat, echo)
- A Unix-like environment is recommended (Linux, WSL, macOS)

## Installation


1. Download the script `consolidate_files.sh` or simplely clone the repo.
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


## How to exclude files from being added to output

Create a file as `path/to/directory/.gptignore` with the contents you don't want to add to the output file. Also the `.gitignore` is taken into account in the same way

Example of `.gptignore` or `.gitignore`

```bash
folder/file_to_ignore.py
folder/subfolder_to_ignore
README.md
__pycache__
```

This will ignore:
- All contents and subdirectories of `folder/subfolder_to_ignore`
- Specifically the file `folder/file_to_ignore.py`
- All `__pycache__` files in all folders/subfolders
- All README.md files in all folders/subfolders

**Important**

If the content added to .gptignore is a **folder**, it will ignore all contents and subfolders
If the content added to .gptignore is a **file**:

1. It will ignore only that specific file if character `/` is present in the name, for example `folder/file_to_ignore.py`
2. It will ignore that file name everywhere if no `/` is present, for example `__pycache__`

## Notes

The script handles plain text files. Binary files or files with special characters in their names may not be processed correctly.