#!/usr/bin/env bash

if type args::option::completion > /dev/null 2>&1; then return; fi

set -euo pipefail

source "$(dirname "$(realpath "${BASH_SOURCE:-$0}")")/args.sh"

args_completion_format_version=1

args::option::completion() {
  args::completion::generate
  exit 0
}

args::completion::generate() {
  local name="$args_program_name"
  [[ -z "$name" ]] && return 1

  local func_name="_complete_${name//[^a-zA-Z0-9_]/_}"

  local options=()
  local commands=()
  local arg_option_keys=()

  for key in "${args_list[@]}"; do
    local names_str="${args_names[$key]}"
    local names_arr
    IFS=', ' read -ra names_arr <<< "$names_str"
    local is_option=0
    for n in "${names_arr[@]}"; do
      if [[ "$n" == "-"* ]]; then
        options+=("$n")
        is_option=1
      else
        commands+=("$n")
      fi
    done
    if [[ $is_option -eq 1 && -n "${args_option_has_arg[$key]}" ]]; then
      arg_option_keys+=("$key")
    fi
  done

  local options_str="${options[*]}"
  local commands_str=""
  [[ ${#commands[@]} -gt 0 ]] && commands_str="${commands[*]}"

  echo "# options.bash-completion v${args_completion_format_version}"
  echo "# Bash completion for ${name}"
  echo ""
  echo "${func_name}() {"
  echo '  local cur="${COMP_WORDS[COMP_CWORD]}"'
  echo '  local prev="${COMP_WORDS[COMP_CWORD-1]}"'
  echo '  COMPREPLY=()'

  if [[ ${#arg_option_keys[@]} -gt 0 ]]; then
    echo ''
    echo '  case "$prev" in'
    for key in "${arg_option_keys[@]}"; do
      local alias_list=()
      local key_names_str="${args_names[$key]}"
      local key_names_arr
      IFS=', ' read -ra key_names_arr <<< "$key_names_str"
      for n in "${key_names_arr[@]}"; do
        if [[ "$n" == "-"* ]]; then
          alias_list+=("$n")
        fi
      done
      local pattern
      pattern=$(IFS='|'; echo "${alias_list[*]}")
      echo "    ${pattern}) COMPREPLY=(\$(compgen -f -- \"\$cur\")); return ;;"
    done
    echo '  esac'
  fi

  if [[ ${#options[@]} -gt 0 ]]; then
    echo ''
    echo '  if [[ "$cur" == -* ]]; then'
    echo "    COMPREPLY=(\$(compgen -W \"${options_str}\" -- \"\$cur\"))"
    echo '    return'
    echo '  fi'
  fi

  if [[ ${#commands[@]} -gt 0 ]]; then
    local cmd_pattern
    cmd_pattern=$(IFS='|'; echo "${commands[*]}")
    echo ''
    echo '  local has_command=0'
    echo '  for ((i=1; i<COMP_CWORD; i++)); do'
    echo '    case "${COMP_WORDS[i]}" in'
    echo "      ${cmd_pattern}) has_command=1; break ;;"
    echo '    esac'
    echo '  done'
    echo ''
    echo '  if [[ $has_command -eq 0 ]]; then'
    echo "    COMPREPLY=(\$(compgen -W \"${commands_str}\" -- \"\$cur\"))"
    echo '    if [[ ${#COMPREPLY[@]} -eq 0 ]]; then'
    echo '      COMPREPLY=($(compgen -f -- "$cur"))'
    echo '    fi'
    echo '    return'
    echo '  fi'
  fi

  echo ''
  echo '  COMPREPLY=($(compgen -f -- "$cur"))'
  echo '}'
  echo ''
  echo "complete -o bashdefault -o default -F ${func_name} ${name}"
}

args::completion::register() {
  local name="$args_program_name"
  [[ -z "$name" ]] && return 0

  local comp_dir="$HOME/.local/share/bash-completion/completions"
  local comp_file="${comp_dir}/${name}"
  local script_path
  script_path="$(realpath "$0")"

  if [[ -f "$comp_file" ]]; then
    local existing_ver
    existing_ver="$(head -1 "$comp_file" 2>/dev/null || true)"
    if [[ "$existing_ver" == "# options.bash-completion v${args_completion_format_version}" && "$comp_file" -nt "$script_path" ]]; then
      return 0
    fi
  fi

  mkdir -p "$comp_dir" 2>/dev/null || return 0
  args::completion::generate >| "$comp_file" 2>/dev/null || return 0
}

args::completion::_on_options() {
  if [[ -v args_aliases["--bash-completion"] ]]; then
    args::completion::register
  fi
}

args::on_options args::completion::_on_options
