#!/bin/bash

repository=$1
search_dir=$2
search_head_only=$3

# Go to the repository root or the specified directory
if [ -z "$repository" ]; then
  if [ -z "$search_dir" ]; then
    cd "$GITHUB_WORKSPACE" || exit
  else
    cd "$GITHUB_WORKSPACE/$search_dir" || exit
  fi
else
  # Clone the repository
  git clone "$repository" /tmp/repo

  if [ -z "$search_dir" ]; then
    cd /tmp/repo || exit
  else
    cd /tmp/repo/"$search_dir" || exit
  fi
fi

if [ -z "$search_head_only" ]; then

  # Search for OpenAPI 3.x.x specifications
  spec_files=$(find . -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.json" \) -print0 | xargs -0 grep -l "openapi: 3")

  # Search for Swagger 2.0 specifications
  spec_files+=$(find . -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.json" \) -print0 | xargs -0 grep -l "swagger: \"2.0\"")

else

  git diff-tree --no-commit-id --name-only HEAD -r > changeset.txt

  while IFS="" read -r p || [ -n "$p" ]
  do
    if [[ $p == *.yaml ]] || [[ $p == *.yml ]] || [[ $p == *.json ]]; then

      # shellcheck disable=SC2143
      if [[ $(grep -E -q 'openapi: 3|swagger: \"2.0\"' "$p") ]]; then
        spec_files+=$p
      fi

    fi
  done < changeset.txt

fi

echo "::set-output name=spec_files::$spec_files"