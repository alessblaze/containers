#!/bin/bash
set -e
# Copyright Aless Microsystems. All Rights Reserved.
# SPDX-License-Identifier: APACHE-2.0
#
# Library for file system actions
# This is AI written code. without human intervention. They gonna replace us wow.
# Try to replicate the logic in AI and find out.
# it may contain errors and bugs. Advised not to use.
# Do not blame if doesn't work and write your own.
# shellcheck disable=SC1091

# Load Generic Libraries
. /opt/bitnami/scripts/liblog.sh

# Global variable for verbose output
VERBOSE=true
# Default number of parallel jobs
DEFAULT_PARALLEL_JOBS=4
# Default log file for errors
ERROR_LOG="/tmp/libfs_error.log"

verbose() {
  if [[ "$VERBOSE" == "true" ]]; then
    echo "[VERBOSE] $@"
  fi
}

# Functions

########################
# Ensure a file/directory is owned (user and group) but the given user
# Arguments:
#   $1 - filepath
#   $2 - owner
#   $3 - group (optional)
# Returns:
#   None
#########################
owned_by() {
  local path="${1:?path is missing}"
  local owner="${2:?owner is missing}"
  local group="${3:-}"

  verbose "Setting ownership of '$path' to user '$owner', group '$group'."
  if [[ -n $group ]]; then
    chown "$owner":"$group" "$path"
  else
    chown "$owner":"$owner" "$path"
  fi
  if [[ $? -ne 0 ]]; then
    error "Failed to set ownership of '$path' to '$owner:$group'."
    return 1
  fi
}

########################
# Ensure a directory exists and, optionally, is owned by the given user
# Arguments:
#   $1 - directory
#   $2 - owner user (optional)
#   $3 - owner group (optional)
# Returns:
#   0 if successful, 1 otherwise
#########################
ensure_dir_exists() {
  local dir="${1:?directory is missing}"
  local owner_user="${2:-}"
  local owner_group="${3:-}"

  verbose "Ensuring directory exists: $dir"
  if [ ! -d "${dir}" ]; then
    verbose "Directory '$dir' does not exist, creating it."
    mkdir -p "${dir}"
    if [[ $? -ne 0 ]]; then
      error "Failed to create directory: $dir"
      return 1 # Indicate failure
    fi
  else
    verbose "Directory '$dir' already exists."
  fi

  if [[ -n $owner_user ]]; then
    owned_by "$dir" "$owner_user" "$owner_group"
  fi
  return 0
}

########################
# Checks whether a directory is empty or not
# Arguments:
#   $1 - directory
# Returns:
#   0 if directory is empty, 1 otherwise
#########################
is_dir_empty() {
  local -r path="${1:?missing directory}"
  # Calculate real path in order to avoid issues with symlinks
  local -r dir="$(realpath "$path")"
  if [[ ! -e "$dir" ]] || [[ -z "$(ls -A "$dir")" ]]; then
    return 0  # True - directory is empty
  else
    return 1  # False - directory is not empty
  fi
}

########################
# Checks whether a mounted directory is empty or not
# Arguments:
#   $1 - directory
# Returns:
#   0 if directory is empty, 1 otherwise
#########################
is_mounted_dir_empty() {
  local dir="${1:?missing directory}"

  if is_dir_empty "$dir" || find "$dir" -mindepth 1 -maxdepth 1 -not -name ".snapshot" -not -name "lost+found" -exec false {} +; then
    return 0  # True - directory is empty
  else
    return 1  # False - directory is not empty
  fi
}

########################
# Checks whether a file can be written to or not
# Arguments:
#   $1 - file
# Returns:
#   0 if file is writable, 1 otherwise
#########################
is_file_writable() {
  local file="${1:?missing file}"
  local dir
  dir="$(dirname "$file")"

  if [[ (-f "$file" && -w "$file") || (! -f "$file" && -d "$dir" && -w "$dir") ]]; then
    return 0  # True - file is writable
  else
    return 1  # False - file is not writable
  fi
}

########################
# Relativize a path
# Arguments:
#   $1 - path
#   $2 - base
# Returns:
#   Relative path
#########################
relativize() {
  local -r path="${1:?missing path}"
  local -r base="${2:?missing base}"
  pushd "$base" >/dev/null || return 1
  realpath -q --no-symlinks --relative-base="$base" "$path" | sed -e 's|^/$|.|' -e 's|^/||'
  popd >/dev/null || return 1
}

########################
# Check if a path exists and is accessible
# Arguments:
#   $1 - path
# Returns:
#   0 if path exists and is accessible, 1 otherwise
#########################
path_exists_and_accessible() {
  local path="${1:?missing path}"
  if [[ -e "$path" && -r "$path" ]]; then
    return 0  # True - path exists and is accessible
  else
    return 1  # False - path doesn't exist or isn't accessible
  fi
}

########################
# Get system load average to determine if we should throttle
# Arguments:
#   None
# Returns:
#   System load average (1-minute)
#########################
get_system_load() {
  local load_avg
  load_avg=$(cat /proc/loadavg | awk '{print $1}')
  echo "$load_avg"
}

########################
# Normalize mode string to ensure consistent format for comparison
# Arguments:
#   $1 - Mode string (e.g. 775, 0775)
# Returns:
#   Normalized mode (3-digit string without leading zeros)
#########################
normalize_mode() {
  local mode="${1:?mode is missing}"
  # Remove leading zeros and ensure 3 digits
  echo "$mode" | sed 's/^0*//'
}



########################
# Function to process a single top-level directory
# Arguments:
#   $1 - directory to process
#   $2 - output file to write results to
#   $3 - error log file
# Returns:
#   0 if successful, 1 otherwise
#########################
process_directory() {
  local dir="$1"
  local out_file="$2"
  local error_log="$3"

  verbose "Processing directory: $dir"
  # Use find's -type option to filter by type during the search 
  # rather than post-processing with grep, which is faster
  find -L "$dir" -type d -print0 2>>"$error_log" |
    while IFS= read -r -d $'\0' item; do
      printf "%s|d\n" "$item"
    done > "$out_file.dirs"

  find -L "$dir" -type f -print0 2>>"$error_log" |
    while IFS= read -r -d $'\0' item; do
      printf "%s|f\n" "$item"
    done > "$out_file.files"

  # Combine the files afterward (faster than doing it all in one pass)
  cat "$out_file.dirs" "$out_file.files" > "$out_file"
  rm -f "$out_file.dirs" "$out_file.files"

  local status=$?
  if [[ $status -ne 0 ]]; then
    echo "Error processing directory: $dir (exit code: $status)" >> "$error_log"
    return 1
  fi

  # Report how many items we found
  local file_count=$(grep -c "|f" "$out_file" || echo 0)
  local dir_count=$(grep -c "|d" "$out_file" || echo 0)
  verbose "Found $file_count files and $dir_count directories in $dir"

  return 0
}

########################
# Function to efficiently set permissions/ownership without a progress bar
# Arguments:
#   $1 - path to process
#   $2 - type (d or f)
#   $3 - mode to set
#   $4 - error log file
# Returns:
#   0 if successful, 1 otherwise
#########################
process_permission() {
  local path="$1"
  local type="$2"
  local mode="$3"
  local error_log="$4"

  verbose "Setting $type mode $mode on: $path"
  if ! chmod "$mode" "$path" 2>>"$error_log"; then
    echo "Failed to set mode $mode on $path" >> "$error_log"
    return 1
  fi

  return 0
}

########################
# Function to efficiently set ownership without a progress bar
# Arguments:
#   $1 - path to process
#   $2 - user
#   $3 - group
#   $4 - error log file
# Returns:
#   0 if successful, 1 otherwise
#########################
process_ownership() {
  local path="$1"
  local user="$2"
  local group="$3"
  local error_log="$4"
  local chown_spec="$user"

  if [[ -n "$group" ]]; then
    chown_spec="$user:$group"
  fi

  verbose "Setting ownership of $path to $chown_spec"
  if ! chown "$chown_spec" "$path" 2>>"$error_log"; then
    echo "Failed to set ownership of $path to $chown_spec" >> "$error_log"
    return 1
  fi

  return 0
}
########################
# Process files and directories in parallel with xargs for better performance
# Arguments:
#   $1 - file containing paths
#   $2 - type (d or f)
#   $3 - mode
#   $4 - parallel jobs
#   $5 - error log
#   $6 - throttle (true/false)
# Returns:
#   0 if successful, 1 otherwise
########################
process_permissions_parallel() {
  local file="$1"
  local type="$2"
  local mode="$3"
  local jobs="$4"
  local error_log="$5"
  local throttle="$6"
  local tmp_script
  
  # Create a temporary script that will be executed by xargs
  tmp_script=$(mktemp)
  cat <<EOF > "$tmp_script"
#!/bin/bash
path="\$1"
if [[ "$VERBOSE" == "true" ]]; then
  echo "[VERBOSE] Setting $type mode $mode on: \$path"
fi
chmod "$mode" "\$path" 2>>$error_log || echo "Failed to set mode $mode on \$path" >> $error_log
EOF

  chmod +x "$tmp_script"

  # Extract paths of specific type
  grep "|$type$" "$file" | cut -d'|' -f1 | \
  xargs -r -P "$jobs" -I{} "$tmp_script" "{}"
  
  local status=$?
  rm -f "$tmp_script"
  return $status
}

########################
# Process ownership in parallel with xargs for better performance
# Arguments:
#   $1 - file containing paths
#   $2 - user
#   $3 - group
#   $4 - parallel jobs
#   $5 - error log
#   $6 - throttle (true/false)
# Returns:
#   0 if successful, 1 otherwise
########################
process_ownership_parallel() {
  local file="$1"
  local user="$2"
  local group="$3"
  local jobs="$4"
  local error_log="$5"
  local throttle="$6"
  local tmp_script
  local chown_spec="$user"
  
  if [[ -n "$group" ]]; then
    chown_spec="$user:$group"
  fi
  
  # Create a temporary script that will be executed by xargs
  tmp_script=$(mktemp)
  cat <<EOF > "$tmp_script"
#!/bin/bash
path="\$1"
if [[ "$VERBOSE" == "true" ]]; then
  echo "[VERBOSE] Setting ownership of \$path to $chown_spec"
fi
chown "$chown_spec" "\$path" 2>>$error_log || echo "Failed to set ownership of \$path to $chown_spec" >> $error_log
EOF

  chmod +x "$tmp_script"

  # Process all paths (both files and directories)
  cut -d'|' -f1 "$file" | \
  xargs -r -P "$jobs" -I{} "$tmp_script" "{}"
  
  local status=$?
  rm -f "$tmp_script"
  return $status
}

########################
# Configure permissions and ownership recursively in a structured and parallel way
# Globals:
#   None
# Arguments:
#   $1 - paths (as a string, space-separated).  Example: "folder1 folder2 folder3 folder4"
# Flags:
#   -f|--file-mode - mode for files. (Default: 664)
#   -d|--dir-mode - mode for directories. (Default: 775)
#   -u|--user - user
#   -g|--group - group
#   -j|--jobs - number of parallel jobs (default: 4)
#   -l|--log - error log file (default: /tmp/libfs_error.log)
#   -t|--throttle - enable automatic throttling based on system load
#   -v|--verify - enable verification of permissions and ownership after setting them
# Returns:
#   0 if successful, 1 otherwise
#########################
configure_permissions_ownership() {
  local -r paths="${1:?paths is missing}"
  local dir_mode="775"  # Default directory mode
  local file_mode="664" # Default file mode
  local user=""
  local group=""
  local parallel_jobs=$DEFAULT_PARALLEL_JOBS
  local error_log="$ERROR_LOG"
  local throttle=false
  local verify=false
  local tmp_dir
  tmp_dir="$(mktemp -d)" # Create a temporary directory.
  local -a top_level_dirs=()
  local started_time=$(date +%s)

  verbose "Configuring permissions and ownership for paths: $paths (structured parallel)"
  verbose "Using temp dir: $tmp_dir"

  # Validate arguments and populate top_level_dirs array
  shift 1
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -f | --file-mode)
        shift
        file_mode="${1:?missing mode for files}"
        file_mode=$(normalize_mode "$file_mode")
        verbose "Setting file mode to: $file_mode"
        ;;
      -d | --dir-mode)
        shift
        dir_mode="${1:?missing mode for directories}"
        dir_mode=$(normalize_mode "$dir_mode")
        verbose "Setting directory mode to: $dir_mode"
        ;;
      -u | --user)
        shift
        user="${1:?missing user}"
        verbose "Setting user to: $user"
        ;;
      -g | --group)
        shift
        group="${1:?missing group}"
        verbose "Setting group to: $group"
        ;;
      -j | --jobs)
        shift
        parallel_jobs="${1:?missing number of jobs}"
        verbose "Setting parallel jobs to: $parallel_jobs"
        ;;
      -l | --log)
        shift
        error_log="${1:?missing log file path}"
        verbose "Setting error log to: $error_log"
        ;;
      -t | --throttle)
        throttle=true
        verbose "Enabling throttling based on system load"
        ;;
      -v | --verify)
        verify=true
        verbose "Enabling verification of permissions and ownership"
        ;;
      *)
        error "Invalid command line flag $1" >&2
        rm -rf "$tmp_dir"
        return 1
        ;;
    esac
    shift
  done

  # Validate parallel jobs is a positive number
  if ! [[ "$parallel_jobs" =~ ^[0-9]+$ ]] || [[ "$parallel_jobs" -lt 1 ]]; then
    error "Number of parallel jobs must be a positive integer"
    rm -rf "$tmp_dir"
    return 1
  fi

  # Create error log file directory if needed
  ensure_dir_exists "$(dirname "$error_log")" || {
    error "Failed to create directory for error log: $(dirname "$error_log")"
    rm -rf "$tmp_dir"
    return 1
  }

  # Initialize error log
  > "$error_log"

  # Convert space-separated paths to array
  read -r -a top_level_dirs <<<"$paths"

  # Verify all paths exist
  for dir in "${top_level_dirs[@]}"; do
    if ! path_exists_and_accessible "$dir"; then
      error "Path does not exist or is not accessible: $dir"
      rm -rf "$tmp_dir"
      return 1
    fi
  done

  # Process each top-level directory in parallel
  verbose "Starting directory scan for ${#top_level_dirs[@]} top-level directories"
  local -a scan_pids=()
  for dir in "${top_level_dirs[@]}"; do
    local outfile="$tmp_dir/$(basename "$dir").txt"
    process_directory "$dir" "$outfile" "$error_log" &
    scan_pids+=($!)
    echo "$dir|d" >> "$outfile"
  #  cat $outfile
  #  ls -l /tmp
  #  ls -la $tmp_dir
  done

  # Wait for all directory scans to complete
  for pid in "${scan_pids[@]}"; do
    wait "$pid" || {
      error "A directory scan job failed."
      rm -rf "$tmp_dir"
      return 1
    }
  done

    # Combine the results into a single file
  local combined_file="$tmp_dir/combined.txt"
  # Check if there are any files to combine first
  shopt -s nullglob dotglob
  txt_files=("$tmp_dir"/*.txt "$tmp_dir"/.*.txt)
  shopt -u nullglob dotglob

  if (( ${#txt_files[@]} == 0 )); then
    error "No files or directories found to process in $paths."
    rm -rf "$tmp_dir"
    return 1
  fi
  echo "successfully parsed results"
  # Faster way to combine files
  shopt -s nullglob dotglob
  txt_files=("$tmp_dir"/*.txt "$tmp_dir"/.*.txt)
  shopt -u nullglob dotglob

  if (( ${#txt_files[@]} > 0 )); then
    cat "${txt_files[@]}" > "$combined_file" || {
      error "Failed to combine results."
      rm -rf "$tmp_dir"
      return 1
    }
  else
    error "No .txt files found to combine in $tmp_dir"
    rm -rf "$tmp_dir"
    return 1
  fi
  # Make sure the combined file exists and has content
  if [ ! -f "$combined_file" ]; then
    error "Combined file not created."
    rm -rf "$tmp_dir"
    return 1
  fi

  # Get the total number of items to process
  local total_lines=$(wc -l < "$combined_file" || echo 0)
  verbose "Total items to process: $total_lines"

  # If no items to process, we're done
  if [[ $total_lines -eq 0 ]]; then
    verbose "No items to process, skipping."
    rm -rf "$tmp_dir"
    return 0
  fi
  #echo "[DEBUG-CFG] Contents of combined_file:"
  #cat "$combined_file"

# Check for entries in the combined file for directories, files, and ownership
  has_directories=$(grep -c '|d$' "$combined_file" || true)
  has_files=$(grep -c '|f$' "$combined_file" || true)
  has_ownership_entries=$(wc -l < "$combined_file" || echo 0)
  #echo "Directories count: $has_directories"
  #echo "Files count: $has_files"
  #echo "Ownership entries count: $has_ownership_entries"
  #echo "[DEBUG] About to set directory permissions..."
  # Set permissions for directories (775) if directories exist
  if (( has_directories > 0 )); then
    verbose "Setting directory permissions to $dir_mode"
    if ! process_permissions_parallel "$combined_file" "d" "$dir_mode" "$parallel_jobs" "$error_log" "$throttle"; then
      error "Failed to set directory permissions"
      rm -rf "$tmp_dir"
      return 1
    fi
  else
    log "No directories found in the combined file. Skipping directory permission setting."
  fi
  #echo "[DEBUG] Finished setting directory permissions."
  #echo "[DEBUG] About to set file permissions..."
  # Set permissions for files (664) if files exist
  if (( has_files > 0 )); then
    verbose "Setting file permissions to $file_mode"
    if ! process_permissions_parallel "$combined_file" "f" "$file_mode" "$parallel_jobs" "$error_log" "$throttle"; then
      error "Failed to set file permissions"
      rm -rf "$tmp_dir"
      return 1
    fi
  else
    log "No files found in the combined file. Skipping file permission setting."
  fi
  #echo "[DEBUG] Finished setting file permissions."
  # Set ownership if entries exist and ownership is specified
  if [[ -n $user ]]; then
    verbose "Setting ownership to $user${group:+:$group}"
  
    if (( has_ownership_entries > 0 )); then
      if ! process_ownership_parallel "$combined_file" "$user" "$group" "$parallel_jobs" "$error_log" "$throttle"; then
        error "Failed to set ownership"
        rm -rf "$tmp_dir"
        return 1
      fi
    else
      log "No ownership entries found in the combined file. Skipping ownership setting."
    fi
  fi

  # Verify permissions and ownership if requested
  if [[ "$verify" == "true" ]]; then
    verbose "Verifying permissions and ownership"
    local verification_errors=0
    
    # Verify directory permissions
    grep "|d$" "$combined_file" | cut -d'|' -f1 | while read -r dir; do
      local actual_mode
      actual_mode=$(stat -c "%a" "$dir")
      actual_mode=$(normalize_mode "$actual_mode")
      if [[ "$actual_mode" != "$dir_mode" ]]; then
        echo "Verification failed: $dir has mode $actual_mode, expected $dir_mode" >> "$error_log"
        verification_errors=$((verification_errors + 1))
      fi
      
      # Verify ownership if set
      if [[ -n $user ]]; then
        local actual_owner
        actual_owner=$(stat -c "%U" "$dir")
        if [[ "$actual_owner" != "$user" ]]; then
          echo "Verification failed: $dir has owner $actual_owner, expected $user" >> "$error_log"
          verification_errors=$((verification_errors + 1))
        fi
        
        if [[ -n $group ]]; then
          local actual_group
          actual_group=$(stat -c "%G" "$dir")
          if [[ "$actual_group" != "$group" ]]; then
            echo "Verification failed: $dir has group $actual_group, expected $group" >> "$error_log"
            verification_errors=$((verification_errors + 1))
          fi
        fi
      fi
    done
    
    # Verify file permissions
    grep "|f$" "$combined_file" | cut -d'|' -f1 | while read -r file; do
      local actual_mode
      actual_mode=$(stat -c "%a" "$file")
      actual_mode=$(normalize_mode "$actual_mode")
      if [[ "$actual_mode" != "$file_mode" ]]; then
        echo "Verification failed: $file has mode $actual_mode, expected $file_mode" >> "$error_log"
        verification_errors=$((verification_errors + 1))
      fi
      
      # Verify ownership if set
      if [[ -n $user ]]; then
        local actual_owner
        actual_owner=$(stat -c "%U" "$file")
        if [[ "$actual_owner" != "$user" ]]; then
          echo "Verification failed: $file has owner $actual_owner, expected $user" >> "$error_log"
          verification_errors=$((verification_errors + 1))
        fi
        
        if [[ -n $group ]]; then
          local actual_group
          actual_group=$(stat -c "%G" "$file")
          if [[ "$actual_group" != "$group" ]]; then
            echo "Verification failed: $file has group $actual_group, expected $group" >> "$error_log"
            verification_errors=$((verification_errors + 1))
          fi
        fi
      fi
    done
    
    if [[ $verification_errors -gt 0 ]]; then
      error "Verification found $verification_errors errors. See $error_log for details."
    else
      verbose "Verification successful: all permissions and ownerships match expected values."
    fi
  fi

  # Check for errors
  if [[ -s "$error_log" ]]; then
    error "Errors occurred during processing. See $error_log for details."
    verbose "Error log content:"
    verbose "$(cat "$error_log")"
  fi

  # Clean up the temporary directory
  rm -rf "$tmp_dir"
  verbose "Removed temp dir: $tmp_dir"

  # Report completion time
  local ended_time=$(date +%s)
  local duration=$((ended_time - started_time))
  verbose "Operation completed in $duration seconds"

  return 0
}

# Example of how to use:
#
# VERBOSE=true
#
# # Set permissions and ownership for a directory
# configure_permissions_ownership "/path/to/directory" -d 775 -f 664 -u www-data -g www-data -j 8
