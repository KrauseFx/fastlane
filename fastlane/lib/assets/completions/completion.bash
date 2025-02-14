#!/bin/bash

_fastlane_complete() {
  COMPREPLY=()
  local word="${COMP_WORDS[COMP_CWORD]}"
  local completions=""

  # look for Fastfile either in this directory or fastlane/ then grab the lane names
  if [[ -e "Fastfile" ]]; then
    dir="."
  elif [[ -e "fastlane/Fastfile" ]]; then
    dir="fastlane"
  elif [[ -e ".fastlane/Fastfile" ]]; then
    dir=".fastlane"
  else
    return 1
  fi
  local imported_files=('Fastfile')
  # parse imports and grab lane names
  imported_files+=($(cd $dir && sed -En "s/^[ 	]*import\([\"']([^\"']+)[\"']\)[ 	]*$/\1/p" "Fastfile"))
  for imported_file in "${imported_files[@]}"; do
    if [[ -e "$dir/$imported_file" ]]; then
      # parse 'beta' out of 'lane :beta do', etc
      completions+=$(cd $dir && sed -En 's/^[ 	]*lane +:([^ 	]+).*$/\1/p' "$imported_file")
    fi
  done
  completions="$completions update_fastlane"

  COMPREPLY=( $(compgen -W "$completions" -- "$word") )
}

