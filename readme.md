
# File Consolidation Script

This Bash script recursively explores a specified directory, appending the contents of all files found within that directory and its subdirectories into a single text file. Each file's path and name is included in the output as a comment line, followed by the actual contents of the file.

The main utility of this file is to give full context of your project to a Large Language Model, such as GPT.

## Features

- **Recursive File Processing**: The script searches through all subdirectories of the specified directory, processing all files.
- **Flexible Output Filename**: If only the directory path is provided when running the script, the output file will automatically be named `gpt_context_output.txt`. If an output file name is provided, the script will use that instead.
- **Ability to Ignore Files**: The script ignores the folders and files listed in **.gitignore** and **.gptignore** files.
- **Optional Mode with `-m think`**: If the `-m think` option is provided, the script will insert the content of a predefined file `CoT_prompt.txt` located in the same directory as the script (`consolidate_files.sh`) before processing the files in the specified directory. If any other mode is provided with `-m`, the script will show an error message indicating that the mode is not supported.

## Prerequisites

To use this script, you will need:

- Bash shell
- Basic command-line utilities (find, cat, echo)
- A Unix-like environment is recommended (Linux, WSL, macOS)

## Installation

1. Download the script `consolidate_files.sh` and `CoT_prompt.txt`, or clone the repository:
   ```bash
   git clone https://github.com/dpuertamartos/gpt_context_provider.git
   ```

2. Make the script executable:
   ```bash
   sudo chmod +x consolidate_files.sh
   ```

## Usage

To run the script, you can use the following commands:

### Without the `-m` option:
```bash
./consolidate_files.sh /path/to/directory output.txt
```
This command specifies both the directory to explore and the name of the output file.

```bash
./consolidate_files.sh /path/to/directory
```
If the output filename is not provided, the script will name the output file `gpt_context_output.txt`.

### With the `-m think` option:
```bash
./consolidate_files.sh /path/to/directory -m think output.txt
```
This command will insert the content of `CoT_prompt.txt` from the same directory as the script into the output `output.txt` file before processing the contents of the specified directory.

```bash
./consolidate_files.sh /path/to/directory -m think
```
This command will insert the content of `CoT_prompt.txt` from the same directory as the script into the default output file  `gpt_context_output.txt` before processing the contents of the specified directory.

### Error Handling for Invalid Modes:
If an unsupported mode is provided with the `-m` option, the script will raise an error:
```bash
./consolidate_files.sh /path/to/directory -m unsupported_mode
```
Output:
```
Error: Mode 'unsupported_mode' does not exist. Only 'think' mode is supported.
```

## How to Exclude Files from Being Added to Output

Create a file as `path/to/directory/.gptignore` with the files or folders you don't want to add to the output file. The `.gitignore` is also taken into account in the same way.

### Example of `.gptignore` or `.gitignore`

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
- All `README.md` files in all folders/subfolders

**Important**:
- If the content added to `.gptignore` is a **folder**, it will ignore all contents and subfolders of that folder.
- If the content added to `.gptignore` is a **file**:
  1. It will ignore only that specific file if a `/` is present in the name, for example `folder/file_to_ignore.py`.
  2. It will ignore that file name everywhere if no `/` is present, for example `__pycache__`.

## Notes

- The script handles plain text files. Binary files or files with special characters in their names may not be processed correctly.
- The `CoT_prompt.txt` must be placed in the same directory as `consolidate_files.sh` for the `-m think` mode to work.


## Setting up the test suite of this repo

This project uses [BATS](https://github.com/bats-core/bats-core) to run the test suite. You need to install the dependencies via git submodules.

1. Initialize and update the submodules:
   ```bash
   git submodule init
   git submodule update
   ```

2. Install the necessary dependencies for BATS:
   ```bash
   git submodule update --init --recursive
   ```

3. Ensure the test files have execution permission:
   ```bash
   chmod +x test/bats/bin/bats
   ```

4. Run the tests:
   ```bash
   ./test/bats/bin/bats test.bats
   ```
