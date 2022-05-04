#!/bin/bash
#
# Executes a command in every subdirectory.

# ------------------------------------ BEGIN GLOBAL VARIABLES ------------------------------------ #

declare __NAME
declare __DIR
declare CMD
declare STDOUT_CACHE_FILE

__NAME="$(basename "${0}")"
__DIR="$(cd "$(dirname "$(readlink -f "${0}")")" && pwd)"
STDOUT_CACHE_FILE="/tmp/${__NAME}/stdout.tmp"

# ------------------------------------- END GLOBAL VARIABLES ------------------------------------- #

# ################################################################################################ #

# ----------------------------------------- BEGIN TRAPS ------------------------------------------ #

trap_exit_on() {
  trap 'trap_exit' EXIT
}

trap_exit_off() {
  trap - EXIT
}

trap_exit() {
  rm -rf "$(dirname "${STDOUT_CACHE_FILE}")"
}

# ------------------------------------------ END TRAPS ------------------------------------------- #

# ################################################################################################ #

# ----------------------------------------- BEGIN DEBUG ------------------------------------------ #

debug_off() {
  set +x
}

debug_on() {
  set -x
}

# ------------------------------------------ END DEBUG ------------------------------------------- #

# ################################################################################################ #

# ----------------------------------------- BEGIN ERROR ------------------------------------------ #

err_off() {
  set +eo pipefail
}

err_on() {
  set -eo pipefail
}

# ------------------------------------------ END ERROR ------------------------------------------- #

# ################################################################################################ #

# -------------------------------------- BEGIN STDOUT_CACHE -------------------------------------- #

cache_stdout_on() {
  exec 3<> /dev/null
  exec 3>&1
  mkdir "$(dirname "${STDOUT_CACHE_FILE}")"
  exec 1> "${STDOUT_CACHE_FILE}"
}

cache_stdout_off() {
  exec 1>&3
  exec 3>&-
}

write_stdout_cache() {
  cat "${STDOUT_CACHE_FILE}"
}

flush_stdout_cache() {
  > "${STDOUT_CACHE_FILE}"
}

# --------------------------------------- END STDOUT_CACHE --------------------------------------- #

# ################################################################################################ #

# --------------------------------------- BEGIN FUNCTIONS ---------------------------------------- #

is_command_applicable_to_dir() {
  local DIR
  local ROOT_CMD

  DIR="${1}"
  ROOT_CMD="$(echo "${CMD}" | cut -d ' ' -f 1)"

  case "${ROOT_CMD}" in
    "git")
      if [[ -d "${DIR}/.git" ]]; then
        return 0
      fi
    ;;

    *)
      return 0
    ;;
  esac

  return 1
}

apply_command_to_dir() {
  local DIR

  DIR="${1}"

  printf '\033[1m%s\033[0m\n\n' \
    "$(section "BEGIN PROCESSING - '${DIR}'")"
  
  cd "${DIR}"
  # cache_stdout_on
  eval "${CMD}"
  # cache_stdout_off
  # write_stdout_cache | sed 's/^/  /'
  # flush_stdout_cache
  cd - > /dev/null

  printf '\n\033[1m%s\033[0m\n' \
    "$(section "END PROCESSING - '${DIR}'")"
}

# ---------------------------------------- END FUNCTIONS ----------------------------------------- #

# ################################################################################################ #

# ------------------------------------------ BEGIN MAIN ------------------------------------------ #

main() {
  local DIR
  local -a DIRS
  local -i MAX_NDX

  err_on
  trap_exit_on

  CMD="$@"
  if [[ -z "${CMD}" ]]; then
    echo "${__NAME}: no command provided."
    exit 1
  fi

  # cd "${__DIR}"
  for DIR in $(find "." -maxdepth 1 -type "d" -not -name "." | xargs readlink -f); do
    if is_command_applicable_to_dir "${DIR}"; then
      DIRS+=("${DIR}")
    fi
  done

  MAX_NDX=$(( ${#DIRS[@]} - 1 ))
  for (( i=0; i<=$MAX_NDX; i++ )); do
    DIR="${DIRS[$i]}"
    
    apply_command_to_dir "${DIR}"

    if [[ $i -ne $MAX_NDX ]]; then
      echo
      section --filler "#"
      echo
    fi
  done
}

# ------------------------------------------- END MAIN ------------------------------------------- #

main "$@"
