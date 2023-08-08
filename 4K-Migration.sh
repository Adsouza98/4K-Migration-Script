#!/bin/bash

# Set color variables
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
TEAL=$(tput setaf 6)
NC=$(tput sgr0)  # Reset color

# Log File Setup
time_stamp=$(date +"%Y-%m-%d_%H-%M-%S")
echo "${BLUE}Start Time: ${time_stamp}${NC}"

# Global Variable Setup
search_directory=""
destination_directory=""
log_file=""

# Function to display script usage
function display_usage {
    echo "Usage: $0 [-m] [-t]"
    echo "  -m   Move files with '2160' in the name from '/mnt/Starlink/Movies' to '/mnt/Starlink/Movies-4K'"
    echo "  -t   Move files with '2160' in the name from '/mnt/Starlink/TvShows' to '/mnt/Starlink/TvShows-4K'"
    exit 1
}

# Function to handle options and arguments
handle_options() {
    while [ $# -gt 0 ]; do
      case $1 in
        -h | --help)
              display_usage
              ;;
        -m | --movies)
              search_directory="/mnt/Starlink/Movies"
              destination_directory="/mnt/Starlink/Movies-4K"
              log_file="logs/Movie-4K-Migration_${time_stamp}.log"
              ;;
        -t | --tvshows)
              search_directory="/mnt/Starlink/TvShows"
              destination_directory="/mnt/Starlink/TvShows-4K"
              log_file="logs/TvShows-4K-Migration_${time_stamp}.log"
              ;;
        # *)
        #       echo "Invalid option: $1" >&2
        #       display_usage
        #       ;;
      esac
      shift
    done
}

handle_options "$@"

# If no argument provided, display usage
if [ -z "$search_directory" ] || [ -z "$destination_directory" ] || [ -z "$log_file" ]; then
    echo "Invalid directories"
    display_usage
fi

# Redirects both stderr and stdout outputs to log_file and stdout simultaneously
test x$1 = x$'\x00' && shift || { set -o pipefail ; ( exec 2>&1 ; $0 $'\x00' "$@" ) | tee "$log_file" ; exit $? ; }

# Step 1: Find all files with 2160 in the name
echo "${YELLOW}=================================== Step 1: Find all files within ${search_directory} with 2160 in the name ==========================================${NC}"

mapfile -t files < <(find "$search_directory" -type f -name '*2160*')

# Count the total number of files
total_files=${#files[@]}
echo "${GREEN}Total files found: $total_files${NC}"
count=0

IFS=$'\n' # Set the input field separator to handle file names with spaces correctly

# Step 2: Create a new folder for each file's parent folder in /mnt/Startlink/Movies-4K
echo "${YELLOW}========================= Step 2: Moving files to ${destination_directory} ===========${NC}"

for file in "${files[@]}"; do
    parent_dir=$(dirname "$file")
    #new_folder="/mnt/Starlink/Movies-4K/$(basename "$parent_dir")"
    new_folder="$destination_directory/$(echo "$parent_dir" | awk -v search_dir="$search_directory/" '{sub(search_dir, ""); print}')"

    #Check if the new folder already exists
    if [ ! -d "$new_folder" ]; then
       mkdir -p "$new_folder"
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
echo "${BLUE}End Time: $(date +"%Y-%m-%d_%H-%M-%S")${NC}"
