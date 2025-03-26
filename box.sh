#!/usr/bin/env bash

set -o errexit -o pipefail -o nounset -o noclobber

box::err() {
  local msg="$1"
  echo "$msg" >&2
  return 1
}

box::string::clean() {
  local string="$1"
  sed 's/\x1B\[[0-9;]*[a-zA-Z]//g' <<< "$string"
}

box::string::length() {
  local string="$1"
  local string_clean=$(box::string::clean "$string")
  echo "${#string_clean}"
}

box::string::make_pad() {
  local length="$1"
  local pad="${2:- }"

  local pad_clean=$(box::string::clean "$pad")
  if [[ "${#pad_clean}" -ne 1 ]]; then
    box::err "Error: Invalid pad character '$1'"
    return 1
  fi

  if [[ "$pad" == ' ' ]]; then
    printf "%${length}s" ''
  else
    printf "%${length}s" '' | tr ' ' "$pad_clean"
  fi
}

box::string::pad() {
  local string="$1"
  local length="$2"
  local align="${3:-l}"
  local pad="${4:- }"

  local string_clean=$(box::string::clean "$string")
  local diff=$((length - ${#string_clean}))

  local pad_left=0
  local pad_right=0

  case "$align" in
    l | left)
      pad_right="$diff"
      ;;
    r | right)
      pad_left="$diff"
      ;;
    c | center)
      pad_left=$((diff / 2))
      pad_right=$((diff - pad_left))
      ;;
  esac

  local pad_left_str=$(box::string::make_pad "$pad_left" "$pad")
  local pad_right_str=$(box::string::make_pad "$pad_right" "$pad")

  printf "%s%s%s" "$pad_left_str" "$string_clean" "$pad_right_str"
}

box::make_lines() {
  for line in "$@"; do
    echo -e "$line"
  done
}

box::get_width() {
  local string="$1"

  # from string to lines
  local lines=()
  set +e
  IFS=$'\n' read -rd '' -a lines <<< "$string"
  set -e

  echo "$(box::string::length "${lines[0]}")"
  return 0
}

box::get_height() {
  local string="$1"

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
        local pad_clean=$(box::string::clean "$pad")
        if [[ "${#pad_clean}" -ne 1 ]]; then
          box::err "Error: Invalid pad character '$1'"
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
            box::err "Error: Invalid alignment '$1'"
            return 1
            ;;
        esac

        local max_length=0
        for line in "${lines[@]}"; do
          local line_length=$(box::string::length "$line")
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
          lines[i]=$(box::string::pad "${lines[i]}" "$max_length" "$align" "$pad")
        done
        ;;

      pad_lr | ph)
        shift
        local left="$1"
        shift
        local right="$1"

        local pad_left=$(box::string::make_pad "$left" "$pad")
        local pad_right=$(box::string::make_pad "$right" "$pad")
        for i in "${!lines[@]}"; do
          lines[i]=$(printf "%s%s%s" "$pad_left" "${lines[i]}" "$pad_right")
        done
        ;;

      pad_tb | pv)
        shift
        local top="$1"
        shift
        local bottom="$1"

        local pad_string=$(box::string::make_pad "$(box::string::length "${lines[0]}")" "$pad")

        local temp_lines=()
        for i in $(seq 1 "$top"); do
          temp_lines+=("$pad_string")
        done

        for line in "${lines[@]}"; do
          temp_lines+=("$line")
        done

        for i in $(seq 1 "$bottom"); do
          temp_lines+=("$pad_string")
        done

        lines=(${temp_lines[@]})
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
            box::err "Error: Invalid alignment '$1'"
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

        local pad_left=$(box::string::make_pad "$left" "$pad")
        local pad_right=$(box::string::make_pad "$right" "$pad")
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
            box::err "Error: Invalid alignment '$1'"
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

        local pad_string=$(box::string::make_pad "$(box::string::length "${lines[0]}")" "$pad")

        local temp_lines=()
        for i in $(seq 1 "$top"); do
          temp_lines+=("$pad_string")
        done

        for line in "${lines[@]}"; do
          temp_lines+=("$line")
        done

        for i in $(seq 1 "$bottom"); do
          temp_lines+=("$pad_string")
        done

        lines=(${temp_lines[@]})
        ;;

      clean | c)
        for i in "${!lines[@]}"; do
          lines[i]=$(box::string::clean "${lines[i]}")
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
        box::err "Error: Invalid option '$1'"
        return 1
        ;;
    esac
    shift
  done

  # from lines to string
  for line in "${lines[@]}"; do
    echo -e "$line"
  done
  return 0
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
    box::err "Error: Strings have different number of lines"
    return 1
  fi

  # add left
  for i in "${!lines1[@]}"; do
    lines1[i]=$(printf "%s%s" "${lines1[i]}" "${lines2[i]}")
  done

  # from lines to string
  for line in "${lines1[@]}"; do
    echo -e "$line"
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
    box::err "Error: Strings have different width"
    return 1
  fi

  # add bottom
  lines1+=("${lines2[@]}")

  # from lines to string
  for line in "${lines1[@]}"; do
    echo -e "$line"
  done
  return 0
}

box::echo() {
  local string="$1"

  # from string to lines
  local lines=()
  set +e
  IFS=$'\n' read -rd '' -a lines <<< "$string"
  set -e

  # from lines to string
  for line in "${lines[@]}"; do
    echo -e "$line"
  done
  return 0
}
