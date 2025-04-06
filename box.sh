#!/usr/bin/env bash

if type box::make > /dev/null 2>&1; then return; fi

set -o errexit -o pipefail -o nounset -o noclobber

_load_dependencies() {
  local script_dir=${BASH_SOURCE:-$0}
  script_dir="$(dirname "$(realpath "$script_dir")")"
  source "${script_dir}/string.sh"
}
if ! type string::err >/dev/null 2>&1; then
  _load_dependencies
fi
unset _load_dependencies

box::make_lines() {
  for line in "$@"; do
    echo "$line"
  done
}

box::get_width() {
  local string="${1:-}"

  if [ -z "$string" ]; then
    echo 0
    return 0
  fi

  # from string to lines
  local lines=()
  set +e
  IFS=$'\n' read -rd '' -a lines <<< "$string"
  set -e

  echo "$(string::length "${lines[0]}")"
  return 0
}

box::get_height() {
  local string="${1:-}"

  if [ -z "$string" ]; then
    echo 0
    return 0
  fi

  # from string to lines
  local lines=()
  set +e
  IFS=$'\n' read -rd '' -a lines <<< "$string"
  set -e

  echo "${#lines[@]}"
  return 0
}

box::exec() {
  local string="$1"
  local pad=' '

  # from string to lines
  local lines=()
  set +e
  IFS=$'\n' read -rd '' -a lines <<< "$string"
  set -e

  shift
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      set_pad | sp)
        shift
        pad="$1"
        local pad_clean=$(string::clean "$pad")
        if [[ "${#pad_clean}" -ne 1 ]]; then
          string::err "Error: Invalid pad character '$1'"
          return 1
        fi
        ;;

      norm | normalize | n)
        shift
        local align="$1"
        case "$align" in
          l | left)
            align="l"
            ;;
          r | right)
            align="r"
            ;;
          c | center)
            align="c"
            ;;
          *)
            string::err "Error: Invalid alignment '$1'"
            return 1
            ;;
        esac

        local max_length=0
        for line in "${lines[@]}"; do
          local line_length=$(string::length "$line")
          if [[ "$line_length" -gt "$max_length" ]]; then
            max_length="$line_length"
          fi
        done

        for i in "${!lines[@]}"; do
          local pad_left=0
          local pad_right=0
          local diff=$((max_length - ${#lines[i]}))
          if [[ "$align" == "l" ]]; then
            pad_right="$diff"
          elif [[ "$align" == "r" ]]; then
            pad_left="$diff"
          elif [[ "$align" == "c" ]]; then
            pad_left=$((diff / 2))
            pad_right=$((diff - pad_left))
          fi
          lines[i]=$(string::pad "${lines[i]}" "$max_length" "$align" "$pad")
        done
        ;;

      pad_lr | ph)
        shift
        local left="$1"
        shift
        local right="$1"

        local pad_left=$(string::make_pad "$left" "$pad")
        local pad_right=$(string::make_pad "$right" "$pad")
        for i in "${!lines[@]}"; do
          lines[i]=$(printf "%s%s%s" "$pad_left" "${lines[i]}" "$pad_right")
        done
        ;;

      pad_tb | pv)
        shift
        local top="$1"
        shift
        local bottom="$1"

        local pad_string=$(string::make_pad "$(string::length "${lines[0]}")" "$pad")

        local temp_lines=()
        for ((i=0; i<top; ++i)); do
          temp_lines+=("$pad_string")
        done

        for line in "${lines[@]}"; do
          temp_lines+=("$line")
        done

        for ((i=0; i<bottom; ++i)); do
          temp_lines+=("$pad_string")
        done

        lines=("${temp_lines[@]}")
        ;;

      align_lr | ah)
        shift
        local align="$1"
        shift
        local length="$1"

        case "$align" in
          l | left)
            align="l"
            ;;
          r | right)
            align="r"
            ;;
          c | center)
            align="c"
            ;;
          *)
            string::err "Error: Invalid alignment '$1'"
            return 1
            ;;
        esac

        local left=0
        local right=0
        local diff=$((length - ${#lines[0]}))
        if [[ "$align" == "l" ]]; then
          right="$diff"
        elif [[ "$align" == "r" ]]; then
          left="$diff"
        elif [[ "$align" == "c" ]]; then
          left=$((diff / 2))
          right=$((diff - left))
        fi

        local pad_left=$(string::make_pad "$left" "$pad")
        local pad_right=$(string::make_pad "$right" "$pad")
        for i in "${!lines[@]}"; do
          lines[i]=$(printf "%s%s%s" "$pad_left" "${lines[i]}" "$pad_right")
        done
        ;;

      align_tb | av)
        shift
        local align="$1"
        shift
        local length="$1"

        case "$align" in
          t | top)
            align="t"
            ;;
          b | bottom)
            align="b"
            ;;
          c | center)
            align="c"
            ;;
          *)
            string::err "Error: Invalid alignment '$1'"
            return 1
            ;;
        esac

        local top=0
        local bottom=0
        local diff=$((length - ${#lines[@]}))
        if [[ "$align" == "t" ]]; then
          bottom="$diff"
        elif [[ "$align" == "b" ]]; then
          top="$diff"
        elif [[ "$align" == "c" ]]; then
          top=$((diff / 2))
          bottom=$((diff - top))
        fi

        local pad_string=$(string::make_pad "$(string::length "${lines[0]}")" "$pad")

        local temp_lines=()
        for ((i=0; i<top; ++i)); do
          temp_lines+=("$pad_string")
        done

        for line in "${lines[@]}"; do
          temp_lines+=("$line")
        done

        for ((i=0; i<bottom; ++i)); do
          temp_lines+=("$pad_string")
        done

        lines=(${temp_lines[@]})
        ;;

      clean | c)
        for i in "${!lines[@]}"; do
          lines[i]=$(string::clean "${lines[i]}")
        done
        ;;

      extract | e)
        shift
        local from="$1"
        shift
        local count="$1"

        lines=("${lines[@]:$from:$count}")
        ;;

      *)
        string::err "Error: Invalid option '$1'"
        return 1
        ;;
    esac
    shift
  done

  # from lines to string
  for line in "${lines[@]}"; do
    echo "$line"
  done
  return 0
}

box::make() {
  box::exec "$(box::make_lines "$@")" normalize left
}

box::stack_lr() {
  local string1="$1"
  local string2="$2"

  # from string to lines
  local lines1=()
  set +e
  IFS=$'\n' read -rd '' -a lines1 <<< "$string1"
  set -e

  local lines2=()
  set +e
  IFS=$'\n' read -rd '' -a lines2 <<< "$string2"
  set -e

  if [ "${#lines1[@]}" -ne "${#lines2[@]}" ]; then
    string::err "Error: Strings have different number of lines"
    return 1
  fi

  # add left
  for i in "${!lines1[@]}"; do
    lines1[i]=$(printf "%s%s" "${lines1[i]}" "${lines2[i]}")
  done

  # from lines to string
  for line in "${lines1[@]}"; do
    echo "$line"
  done
  return 0
}

box::stack_tb() {
  local string1="$1"
  local string2="$2"

  # from string to lines
  local lines1=()
  set +e
  IFS=$'\n' read -rd '' -a lines1 <<< "$string1"
  set -e

  local lines2=()
  set +e
  IFS=$'\n' read -rd '' -a lines2 <<< "$string2"
  set -e

  if [ "${#lines1[0]}" -ne "${#lines2[0]}" ]; then
    string::err "Error: Strings have different width"
    return 1
  fi

  # add bottom
  lines1+=("${lines2[@]}")

  # from lines to string
  for line in "${lines1[@]}"; do
    echo "$line"
  done
}

box::err() {
  local string="$1"

  # from string to lines
  local lines=()
  set +e
  IFS=$'\n' read -rd '' -a lines <<< "$string"
  set -e

  # from lines to string
  if [[ -t 2 || -z "$TERM" ]]; then
    for line in "${lines[@]}"; do
      echo -e "$line" >&2
    done
    return 1
  fi

  for line in "${lines[@]}"; do
    echo -e "$(string::clean "$line")" >&2
  done
  return 1
}

box::out() {
  local string="$1"

  # from string to lines
  local lines=()
  set +e
  IFS=$'\n' read -rd '' -a lines <<< "$string"
  set -e

  # from lines to string
  if [[ -t 1 || -z "$TERM" ]]; then
    for line in "${lines[@]}"; do
      echo -e "$line"
    done
    return 0
  fi

  for line in "${lines[@]}"; do
    echo -e "$(string::clean "$line")"
  done
  return 0
}
