#!/bin/bash

# Function to add a key to a widget definition
add_key() {
  local file="$1"
  local pattern="$2"
  local line_number="$3"
  local class_name="$4"

  # Generate a unique key string
  local key_name="uniqueKey${RANDOM}"
  local key_definition="  final GlobalKey $key_name = GlobalKey();"

  # Escape special characters in the pattern for sed
  local escaped_pattern=$(echo "$pattern" | sed 's/[]\/$*.^|[]/\\&/g')

  # Find the line number of the class definition
  class_start_line=$(grep -n "class $class_name" "$file" | cut -d: -f1)
  insert_line=$((class_start_line + 1))

  # Check if the key definition already exists in the class
  if ! grep -q "$key_definition" "$file"; then
    # Insert the key definition after the class definition
    sed -i "" "${insert_line}i\\
$key_definition" "$file"
  fi

  # Update the pattern line to include the key
  sed -i "" "${line_number}s/$escaped_pattern/$escaped_pattern key: $key_name,/" "$file"

  echo "Added key '$key_name' to widget in '$file' under class '$class_name'"
}

# Function to record an existing key
record_key() {
  local file="$1"
  local pattern="$2"
  local line_number="$3"

  local key_name=$(sed -n "${line_number}p" "$file" | grep -Eo 'key: [a-zA-Z0-9_]*')

  echo "Found existing key '$key_name' for widget in '$file'"
}

# Function to get the class name of a given line number
get_class_name() {
  local file="$1"
  local line_number="$2"
  awk -v line="$line_number" '
    NR <= line {
      if ($0 ~ /class /) {
        match($0, /class[ \t]+([^ \t{]+)/, arr)
        class_name = arr[1]
      }
    }
    END { print class_name }
  ' "$file"
}

# List of patterns to search for
patterns=(
  'ListView('
  'ListView.builder('
  'ListView.separated('
)

# Find all Dart files recursively
all_dart_files=$(find . -type f -name "*.dart")

for file in $all_dart_files; do
  for pattern in "${patterns[@]}"; do
    # Find lines containing the pattern
    matches=$(grep -n "$pattern" "$file")

    for match in $matches; do
      # Extract line number
      line_number=${match%%:*}

      # Get the class name for the current line
      class_name=$(get_class_name "$file" "$line_number")

      # Check if there's already a key
      key_line=$(sed -n "${line_number}p" "$file" | grep -Eo 'key: [a-zA-Z0-9_]*' || true)

      if [ -z "$key_line" ]; then
        # No key found, add one
        if ! grep -q "final GlobalKey" "$file"; then
          add_key "$file" "$pattern" "$line_number" "$class_name"
        fi
      else
        # Key found, record it
        record_key "$file" "$pattern" "$line_number"
      fi
    done
  done
done
