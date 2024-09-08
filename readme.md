# File Consolidation Script to provide context to LLMs

This Bash script recursively explores a specified directory, appending the contents of all files found within that directory and its subdirectories into a single text file. Each file's path and name is included in the output as a comment line, followed by the actual contents of the file.

The main utility of this file is to give full context of your project to a Large Language Model, such as GPT, Claude, Bard, or others.

## 0. Index
1. [Features](#1-features)
2. [Prerequisites](#2-prerequisites)
3. [Running the Script with Docker](#3-running-the-script-with-docker)
   - [3.1. Pulling and Running the Docker Container](#31-pulling-and-running-the-docker-container)
   - [3.2. Example Single Line Commands](#32-example-single-line-commands)
   - [3.3. Build Your Own Docker Image](#33-build-your-own-docker-image)
4. [Installation Without Docker](#4-installation-without-docker)
   - [4.1. Usage Without Docker](#41-usage-without-docker)
5. [Error Handling](#5-error-handling)
6. [Excluding Files from Output](#6-excluding-files-from-output)
   - [6.1 Example of `.gptignore` or `.gitignore`](#61-example-of-gptignore-or-gitignore)
7. [Notes](#7-notes)
8. [Setting Up the Test Suite](#8-setting-up-the-test-suite)

## 1. Features

- **Recursive File Processing**: The script searches through all subdirectories of the specified directory, processing all files.
- **Flexible Output Filename**: If only the directory path is provided when running the script, the output file will automatically be named `gpt_context_output.txt`. If an output file name is provided, the script will use that instead.
- **Ability to Ignore Files**: The script ignores the folders and files listed in **.gitignore** and **.gptignore** files.
- **Optional Mode with `-m think`**: If the `-m think` option is provided, the script will insert the content of a predefined file `CoT_prompt.txt` located in the same directory as the script (`consolidate_files.sh`) before processing the files in the specified directory. If any other mode is provided with `-m`, the script will show an error message indicating that the mode is not supported. Feel free to change the con

## 2. Prerequisites

To use this script, you will need:

- Docker

Make sure you have Docker installed. You can download it from [Docker's official site](https://www.docker.com/).

Or:

- Bash shell
- Basic command-line utilities (find, cat, echo)

## 3. Running the Script with Docker

To avoid having to set up the environment manually, you can use Docker to run the script. This is especially useful in non-Linux environments (like Windows). 

**You will be able to run all the functionalities without installing anything (apart from Docker) and with single line commands**.


### 3.1. Pulling and Running the Docker Container

You can run the Docker container by mounting any local directory that you want to process to `/context` inside the container and running the script. This will automatically pull the docker image from the public Docker registry:

```bash
docker run --rm -v {/directory/to/process}:/context dpuertamartos/gpt_context_provider /context -m think output.txt
```

- `-v {/directory/to/process}:/context`: Mounts directory to `/context` in the container. 

Replace the `{/directory/to/process}`. 
Provide the directory as absolute path or use `.`, `${pwd}` (windows powershell), `$(pwd)` (bash). Take into account that the output `.txt` will be produced in the directory processed.

- `/context`: **Do not change it**. The directory to be processed inside the container. 
- `-m think`: **Optional** Runs the script in "think" mode, which adds the `CoT_prompt.txt` to the output.
- `output.txt`: **Optional** The custom file where the consolidated output will be written.

### 3.2. Example single line commands

In this examples we will asume we are in the directory to be processed and use `.` to point our current directory.

1. **Default run**:
   ```bash
   docker run --rm -v .:/context dpuertamartos/gpt_context_provider /context
   ```

2. **Run with custom output**:
   ```bash
   docker run --rm -v .:/context dpuertamartos/gpt_context_provider /context output.txt
   ```

3. **Run in "think" mode and process uurrent directory**:
   ```bash
   docker run --rm -v .:/context dpuertamartos/gpt_context_provider /context -m think 
   ```

4. **Run in "think" mode and custom output**:
   ```bash
   docker run --rm -v .:/context dpuertamartos/gpt_context_provider /context -m think output.txt
   ```

### 3.3. Build your own Docker Image

**Optional**

Once Docker is installed, you need to build the Docker image for the script:

1. Clone the repository:
   ```bash
   git clone https://github.com/dpuertamartos/gpt_context_provider.git
   ```

2. Build the docker image
   ```bash
   docker build -t gpt_context_provider .
   ```

This will build an image named `gpt_context_provider`.

## 4. Installation without docker (BASH required)

1. Download the script `consolidate_files.sh` and `CoT_prompt.txt`, or clone the repository:
   ```bash
   git clone https://github.com/dpuertamartos/gpt_context_provider.git
   ```

2. Make the script executable:
   ```bash
   sudo chmod +x consolidate_files.sh
   ```

### 4.1. Usage without docker

To run the script, you can use the following commands:

1. Without the `-m` option:
```bash
./consolidate_files.sh /path/to/directory output.txt
```
This command specifies both the directory to explore and the name of the output file.

```bash
./consolidate_files.sh /path/to/directory
```
If the output filename is not provided, the script will name the output file `gpt_context_output.txt`.

2. With the `-m think` option:
```bash
./consolidate_files.sh /path/to/directory -m think output.txt
```
This command will insert the content of `CoT_prompt.txt` from the same directory as the script into the output `output.txt` file before processing the contents of the specified directory.

```bash
./consolidate_files.sh /path/to/directory -m think
```
This command will insert the content of `CoT_prompt.txt` from the same directory as the script into the default output file  `gpt_context_output.txt` before processing the contents of the specified directory.

## 5. Error Handling:

If an unsupported mode is provided with the `-m` option, the script will raise an error:
```bash
./consolidate_files.sh /path/to/directory -m unsupported_mode
```
Output:
```
Error: Mode 'unsupported_mode' does not exist. Only 'think' mode is supported.
```

## 6. Excluding Files from Output

Create a file as `path/to/directory/.gptignore` with the files or folders you don't want to add to the output file. The `.gitignore` is also taken into account in the same way.

### 6.1 Example of `.gptignore` or `.gitignore`

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

## 7. Notes

- The script handles plain text files. Binary files or files with special characters in their names may not be processed correctly.
- The `CoT_prompt.txt` must be placed in the same directory as `consolidate_files.sh` for the `-m think` mode to work.


## 8. Setting up the test suite

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
