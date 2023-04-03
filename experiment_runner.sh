#!/usr/bin/env bash
#
# Purpose: Run large scale experiments with EvoSuite
# Author: Mitchell Olsthoorn

set -u # Treat unset variables as an error when substituting

# Default values
MEMORY=4000         # The memory limit (MB) for the EvoSuite client process
PARALLEL_INSTANCES=4 # The amount of parallel executions the experiment should use
ROUNDS=10             # The number of rounds to perform of the experiment
SEEDS_FILE='SEEDS'   # The file for storing the random seeds for the experiment
TIMEOUT=2m          # The amount of time before the EvoSuite process is killed

# Constants
readonly PROJECTS_DIRECTORY='subjects' # Directory where the projects are stored
readonly RESULTS_DIRECTORY='results'   # Directory where the results should be stored
readonly CLASS_PATH_FILE='CLASSPATH'   # Filename of manual classpath override

# Warn helper functions
warn() {
  echo ":: [$(date +'%Y-%m-%dT%H:%M:%S%z')] $*" >&2
}

# Die helper functions
die() {
  echo ":: [$(date +'%Y-%m-%dT%H:%M:%S%z')] $*" >&2
  exit 1
}

# Log helper functions
log() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] RUNNER: $*"
}

# Interruption handler
int_handler() {
    warn "Interrupted"
    kill $PPID # Kill the parent process of the script.
    exit 1
}

#######################################
# Determines the classpath based on the project and outputs this.
# Expects the following file structure: projects/<project>/<jars>
#
# Globals:
#   PROJECTS_DIRECTORY
# Arguments:
#   Project name
#   Search depth (default: 1)
# Returns:
#   Colon seperated class path
#######################################
get_project_class_path() {
  local project_name=$1
  local search_depth=${2:-1} # Search depth (default: 1)

  local project_path="${PROJECTS_DIRECTORY}/${project_name}"         # Location of project
  local project_class_path_file="${project_path}/${CLASS_PATH_FILE}" # Location of project class path file
  local project_class_path
  if [[ -f "${project_class_path_file}" ]]; then # If a manual classpath has been defined use that
    read -r project_class_path < "${project_class_path_file}"
  else # Otherwise include all jars in the directory
    # Find all paths of jars in the search directory and combine with a colon separator
    project_class_path="$(find "${project_path}" -maxdepth "${search_depth}" -type f -name "*.jar" -printf '%p:' | sed 's/:$//')"
  fi

  echo ${project_class_path}
}

#######################################
# Runs a single configuration of EvoSuite.
#
# Globals:
#   IFS
#   MEMORY
#   RESULTS_DIRECTORY
#   TIMEOUT
# Arguments:
#   Execution number
#   Number of total executions
#   Round number
#   Name of the configuration
#   User configuration of EvoSuite
#   Project name
#   Full class name
#   Seed
# Outputs:
#   Writes execution configuration to stdout
#   Writes execution results to disk
#######################################
run_evosuite() {
  local execution=$1
  local num_executions=$2
  local round=$3
  local project_name=$4
  local class=$5
  local seed=$6

  local project_class_path="$(get_project_class_path "${project_name}")"
  local class_name=$(echo "${class}" | tr '.' '_') # Replace dots in class with underscores

  # Output locations
  local report_dir="${RESULTS_DIRECTORY}/${project_name}/${class_name}/reports/${round}"
  local test_dir="${RESULTS_DIRECTORY}/${project_name}/${class_name}/tests/${round}"
  local log_dir="${RESULTS_DIRECTORY}/${project_name}/${class_name}/logs/"
  local log_file="${RESULTS_DIRECTORY}/${project_name}/${class_name}/logs/${round}"

  mkdir -p "${log_dir}" # Create log directory



  log "Execution (${execution} / ${num_executions}): Running round (${round})  for class (${class}) in project (${project_name}) with seed (${seed})"

  # Run EvoSuite in background
   java -jar "evosuite-master-1.2.1.jar" \
  -mem "${MEMORY}" \
  -Dconfiguration_id="EVOSUITE" \
  -Dgroup_id="${project_name}" \
  -projectCP "${project_class_path}" \
  -class "${class}" \
  -Dreport_dir="${report_dir}" \
  -Dtest_dir="${test_dir}" \
  -Dshow_progress='true' \
  -Dplot='false' \
  -Dclient_on_thread='false' \
  -Dstrategy='EVOSUITE' \
  -Dinheritance_file="${PROJECTS_DIRECTORY}/${project_name}/evosuite-files/inheritance.xml.gz" \
  &> "${log_file}" &
}

#######################################
# Runs large scale experiment.
#
# Globals:
#   CONFIGURATIONS_FILE
#   IFS
#   MEMORY
#   PARALLEL_INSTANCES
#   PROJECTS_FILE
#   RESULTS_DIRECTORY
#   ROUNDS
#   SEEDS_FILE
#   TIMEOUT
# Arguments:
#   None
# Outputs:
#   Writes error messages to stderr
#   Writes info messages to stdout
#   Writes seeds file to disk
#######################################
run_experiment() {

  [[ ! -f "${PROJECTS_FILE}" ]] && { die "(${PROJECTS_FILE}) file not found, cancelling experiment"; }

  # Cancel experiment if the results directory is present
  [[ -d "${RESULTS_DIRECTORY}" ]] && { die "($RESULTS_DIRECTORY) directory is present, cancelling experiment"; }

  # Check for duplicates in the pairs of the projects file
  for line in $(sort -t, -k1 -k2 <(tail -n +2 "${PROJECTS_FILE}") | uniq -d); do
    die "(${PROJECTS_FILE}) file contains a duplicate pair, cancelling experiment"
    grep -n -- "${line}" "${PROJECTS_FILE}"
  done

  local num_configurations="3" # Number of configurations in experiment
  local num_classes="$(( $(wc -l < "${PROJECTS_FILE}") - 1 ))"              # Number of classes in experiment
  local num_executions="$(( ROUNDS * num_configurations * num_classes ))"   # Number of total executions

  log "Start experiment with (${num_executions}) total executions across (${PARALLEL_INSTANCES}) parallel instances"
  log "Perform (${ROUNDS}) rounds with (${num_configurations}) configurations of (${num_classes}) classes"
  log "Run the EvoSuite client with (${MEMORY}) MBs of memory and a timeout of (${TIMEOUT})"

  local seeds=()   # Array containing all seeds for the experiment
  local seed_value # Seed value for creating and loading the seeds file

  # Seeds file creating or loading
  if [[ ! -f "${SEEDS_FILE}" ]]; then # Create random seeds file if it doesn't exist and load it in memory
    log "Creating random seeds file (${SEEDS_FILE})"
    log "Store this file with your experiment to replicate the experiment later"

    for i in $(seq 1 1 "${num_executions}")
    do
      local seed_value="$(od -vAn -N4 -t u4 < /dev/urandom | tr -d ' ')"
      local seeds+=("${seed_value}")
      echo "${seed_value}" >> "${SEEDS_FILE}"
    done
  else # Load random seeds file in memory
    log "Using existing seeds file (${SEEDS_FILE})"
    log "REPLICATING EXPERIMENT"

    local seeds_entries="$(wc -l < "${SEEDS_FILE}")"
    (( seeds_entries != num_executions )) && { die "Number of entries (${seeds_entries}) in (${SEEDS_FILE}) does not match the number of executions (${num_executions})"; }

    while read seed_value; do
      local seeds+=("${seed_value}")
    done < "${SEEDS_FILE}"
  fi

  local execution=1 # The current execution

  # Define local variables
  local round              # Round number
  local project_name       # Project name
  local class              # Full class name
  local seed               # Seed

  for round in $(seq 1 1 "${ROUNDS}"); do # Rounds loop

    local old_ifs="${IFS}" # Maintain the old separator
    IFS=','                # Set separator for CSV

    while read project_name class; do # Projects and classes loop
        local seed_index="$(( execution - 1 ))"
        local seed="${seeds[${seed_index}]}"

        # Run a single configuration of EvoSuite as a sub-process
        run_evosuite "${execution}" "${num_executions}" "${round}" "${project_name}" "${class}" "${seed}"

        (( execution++ )) # Increment execution number

        # Wait when the program reaches the limit of parallel executions
        while (( $(jobs -p | wc -l) >= PARALLEL_INSTANCES )); do
      	  wait -n       # Wait for the first sub-process to finish
      	  local code=$? # Exit code of sub-process
        done
    done < <(tail -n +2 "${PROJECTS_FILE}") # Load projects file without header

    IFS="${old_ifs}" # Restore old separator
  done

  wait     # Wait for all sub-processes (individual EvoSuite configurations) to be done
  sleep 30 # Allow some extra time for the sub-process to write out the files

  log "Experiment done with (${num_executions}) total executions"
  local num_results="$(find ${RESULTS_DIRECTORY} -mindepth 1 -type f -name "*.csv" -printf x | wc -c)"
  log "(${num_results}) of which produced results"

  log "Store  ${PROJECTS_FILE}, ${SEEDS_FILE}, and the 'projects' directory with the results to replicate the experiment"
}

# Usage prompt
usage() {
cat << EOF

Usage
  $0 [options] <configurations_file> <projects_file>

Options:
  <configurations_file>    CSV file with configurations for EvoSuite (columns: name,configuration)
  <projects_file>          CSV file with projects and their corresponding classes to run (columns: project,class)
  -h                       print help and exit
  -m <memory>              memory limit (MB) for the EvoSuite client process (default: 2500)
  -p <parallel_instances>  limit for the number of parallel executions (default: 1)
  -r <rounds>              number of rounds to execute each experiment (default: 1)
  -s <seeds_file>          file with the seeds for the executions of the experiment (default: SEEDS)
  -t <timeout>             amount of time before EvoSuite process is killed (default: 10m)

Examples:
  $0 configurations.csv projects.csv
  $0 -r 10 -p 4 configurations.csv projects.csv
  $0 -t 1h -m 4096 configurations.csv projects.csv

EOF
}

#######################################
# Runs main program.
#
# Globals:
#   CONFIGURATIONS_FILE
#   MEMORY
#   OPTARG
#   OPTIND
#   PARALLEL_INSTANCES
#   PROJECTS_FILE
#   RESULTS_DIRECTORY
#   ROUNDS
#   SEEDS_FILE
#   TIMEOUT
# Arguments:
#   Script input
# Outputs:
#   Writes error messages to stderr
#   Writes usage information to stdout
#######################################
main() {
  trap 'int_handler' INT # Set interupt handler

  # Argument parsing
  local o
  while getopts ":hm:p:r:s:t:" o; do
    case "${o}" in
      h)
        usage
        exit 0
        ;;
      m)
        MEMORY="${OPTARG}"

        # Exit when the MEMORY is below 1
        (( MEMORY < 1 )) && { warn "The amount of memory should be at least 1"; usage; exit 1; }
        ;;
      p)
        PARALLEL_INSTANCES="${OPTARG}"

        # Exit when the PARALLEL_INSTANCES is below 1
        (( PARALLEL_INSTANCES < 1 )) && { warn "The number of parallel instances should be at least 1"; usage; exit 1; }
        ;;
      r)
        ROUNDS="${OPTARG}"

        # Exit when the ROUNDS are below 1
        (( ROUNDS < 1 )) && { warn "Rounds should be at least 1"; usage; exit 1; }
        ;;
      s)
        SEEDS_FILE="${OPTARG}"
        ;;
      t)
        TIMEOUT="${OPTARG}"
        ;;
      \?)
        warn "Invalid option: -${OPTARG}"
        usage
        exit 1
        ;;
      :)
        warn "Option -${OPTARG} requires an argument"
        usage
        exit 1
        ;;
      *)
        usage
        exit 1
        ;;
    esac
  done

  readonly MEMORY
  readonly PARALLEL_INSTANCES
  readonly ROUNDS
  readonly SEEDS_FILE
  readonly TIMEOUT

  shift "$(( OPTIND - 1 ))" # Remove parsed flags from argument pool


  readonly PROJECTS_FILE=$1       # CSV file with projects and their corresponding classes to run

  run_experiment # Start experiment
}

main $* # Run script
