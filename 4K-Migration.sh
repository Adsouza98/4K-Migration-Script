#!/bin/bash

# Log File Setup
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
log_file="move_files_${timestamp}.log"

# Redirects both stderr and stdout outputs to log_file and stdout simultaneously
test x$1 = x$'\x00' && shift || { set -o pipefail ; ( exec 2>&1 ; $0 $'\x00' "$@" ) | tee "$log_file" ; exit $? ; }

# Set color variables
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
TEAL=$(tput setaf 6)
NC=$(tput sgr0)  # Reset color

# Step 1: Find all files with 2160 in the name
echo "${YELLOW}=================================== Step 1: Find all files with 2160 in the name ==========================================${NC}"

search_directory="/mnt/Starlink/Movies"
mapfile -t files < <(find "$search_directory" -type f -name '*2160*')

# Count the total number of files
total_files=${#files[@]}
echo "${GREEN}Total files found: $total_files${NC}"
count=0

IFS=$'\n' # Set the input field separator to handle file names with spaces correctly

# Step 2: Create a new folder for each file's parent folder in /mnt/Startlink/Movies-4K
echo "${YELLOW}========================= Step 2: Create a new folder for each file's parent folder in /mnt/Startlink/Movies-4K ===========${NC}"

for file in "${files[@]}"; do
    parent_dir=$(dirname "$file")
    new_folder="/mnt/Starlink/Movies-4K/$(basename "$parent_dir")"

    #Check if the new folder already exists
    if [ ! -d "$new_folder" ]; then
       mkdir "$new_folder"
       chown apps:apps "$new_folder"
       echo "${TEAL}Created Folder: \"$new_folder\"${NC}"
    fi

    # Step 3: Move the found files into the newly created folder
    rsync -a --info=progress2 --remove-source-files "$file" "$new_folder"

    echo "${TEAL}Moved \"$file\" to \"$new_folder\"${NC}"

    # Update progress and estimate time remaining
    count=$((count + 1))
    progress=$((count * 100 / total_files))
    remaining=$((total_files - count))
    echo "${GREEN}$progress% completed ($count/$total_files), estimated files remaining: $remaining${NC}"
done | pv -l -s "$total_files" -p -t -e

echo "${YELLOW}########################################### All files moved successfully #################################################${NC}"