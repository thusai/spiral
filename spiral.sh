#!/usr/bin/env bash

CONFIG_DIR="$HOME/.config/spiral"
CONFIG_FILE="$CONFIG_DIR/config"
mkdir -p "$CONFIG_DIR"

# Function to find schema file for a given YAML file
find_schema_file() {
    local yaml_file="$1"
    local yaml_dir=$(dirname "$(realpath "$yaml_file")")
    
    # Look for schema.yml in the same directory as the YAML file
    if [ -f "$yaml_dir/schema.yml" ]; then
        echo "$yaml_dir/schema.yml"
        return 0
    fi
    
    # Look for config/schema.yml relative to the YAML file directory
    if [ -f "$yaml_dir/config/schema.yml" ]; then
        echo "$yaml_dir/config/schema.yml"
        return 0
    fi
    
    # Look for schema.yml in parent directory
    if [ -f "$yaml_dir/../config/schema.yml" ]; then
        echo "$(realpath "$yaml_dir/../config/schema.yml")"
        return 0
    fi
    
    # Look in current working directory
    if [ -f "./config/schema.yml" ]; then
        echo "$(realpath "./config/schema.yml")"
        return 0
    fi
    
    return 1
}

# Function to set active YAML file and find its schema
set_active_file() {
    local yaml_file="$1"
    local yaml_path=$(realpath "$yaml_file")
    local schema_path=$(find_schema_file "$yaml_file")
    
    if [ -z "$schema_path" ]; then
        echo "❌ Could not find schema.yml for $yaml_file"
        echo "Looked in:"
        echo "  - $(dirname "$yaml_path")/schema.yml"
        echo "  - $(dirname "$yaml_path")/config/schema.yml"
        echo "  - $(dirname "$yaml_path")/../config/schema.yml"
        echo "  - ./config/schema.yml"
        exit 1
    fi
    
    cat > "$CONFIG_FILE" << EOF
active_file="$yaml_path"
schema_path="$schema_path"
EOF
    echo "Set active file to: $yaml_file"
    echo "Using schema: $schema_path"
}

# Function to get active YAML file
get_active_file() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        echo "$active_file"
    else
        echo ""
    fi
}

# Function to get schema path
get_schema_path() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        echo "$schema_path"
    else
        echo ""
    fi
}

# Function to get schema fields for a section
get_schema_fields() {
    local file="$1"
    local section="$2"
    
    # Get all unique keys from existing entries in the section
    yq eval ".$section | map(keys) | flatten | unique" "$file" | sed 's/^- //' | tr '\n' ' '
}

# Function to show usage
show_usage() {
    echo "Usage:"
    echo "  spiral                          # List all YAML files in current directory"
    echo "  spiral use <yaml-file>          # Set active YAML file and project"
    echo "  spiral current                  # Show current active file and schema"
    echo "  spiral projects                 # Show all configured projects"
    echo "  spiral list                     # Show available sections in active file"
    echo "  spiral schema <section>         # Show schema fields for section"
    echo "  spiral add <section> <key=value> ...  # Add new entry (auto-fills missing fields)"
    echo "  spiral m|modify <section> <id> <field=value>  # Modify a value"
    echo "  spiral show <section> [fields]  # Show entries"
    echo "  spiral tui                      # Launch interactive TUI"
    echo ""
    echo "Examples:"
    echo "  spiral use v0.yml               # Set v0.yml as active (works from any directory)"
    echo "  spiral use /path/to/roadmap.yml # Set absolute path as active"
    echo "  spiral schema milestones        # Show all fields in milestones"
    echo "  spiral add milestones week=W8 version=0.8.0 id=R8.8  # Auto-fills other fields"
    echo "  spiral m milestones D3.2 release_status=done"
    echo "  spiral show milestones id title"
    echo ""
    echo "Project Setup:"
    echo "  Spiral looks for schema.yml in these locations (in order):"
    echo "  1. Same directory as the YAML file"
    echo "  2. config/schema.yml relative to the YAML file"
    echo "  3. ../config/schema.yml relative to the YAML file"
    echo "  4. ./config/schema.yml in current directory"
    exit 1
}

# Function to list all YAML files
list_yaml_files() {
    echo "Available YAML files:"
    echo "-------------------"
    find . -type f -name "*.yml" -o -name "*.yaml" | sed 's/^../  /'
}

# Function to show specific fields for a section
show_fields() {
    local file="$1"
    local section="$2"
    shift 2
    local fields=("$@")
    
    # Get the count of items in the section
    local count=$(yq eval ".$section | length" "$file")
    
    for ((i=0; i<count; i++)); do
        local line=""
        for field in "${fields[@]}"; do
            local value=$(yq eval ".$section[$i].$field" "$file")
            if [ "$value" != "null" ]; then
                if [ -z "$line" ]; then
                    line="$value"
                else
                    line="$line | $value"
                fi
            fi
        done
        echo "$line"
    done
}

# Function to load schema for a given section
load_schema_field() {
    local section="$1"
    local field="$2"
    local key="$3"
    local schema_path=$(get_schema_path)
    if [ -z "$schema_path" ]; then
        echo "❌ No active project set. Use 'spiral use <yaml-file>' first."
        exit 1
    fi
    local result=$(yq eval ".$section.$field.$key" "$schema_path")
    if [ "$result" = "null" ]; then
        echo ""
    else
        echo "$result"
    fi
}

# No arguments - list YAML files and show active file
if [ $# -eq 0 ]; then
    active_file=$(get_active_file)
    list_yaml_files
    if [ -n "$active_file" ]; then
        echo ""
        echo "Current active file: $active_file"
    fi
    exit 0
fi

# Process commands
case "$1" in
    use)
        if [ $# -ne 2 ]; then
            echo "Error: Specify YAML file to use"
            exit 1
        fi
        if [ ! -f "$2" ]; then
            echo "Error: File '$2' not found"
            exit 1
        fi
        set_active_file "$2"
        ;;

    current)
        active_file=$(get_active_file)
        schema_path=$(get_schema_path)
        if [ -n "$active_file" ]; then
            echo "Current active file: $active_file"
            if [ -n "$schema_path" ]; then
                echo "Using schema: $schema_path"
            else
                echo "⚠️  No schema found for this file"
            fi
        else
            echo "No active file set. Use 'spiral use <yaml-file>' to set one."
        fi
        ;;

    projects)
        if [ -f "$CONFIG_FILE" ]; then
            echo "Current project configuration:"
            echo "=============================="
            cat "$CONFIG_FILE"
        else
            echo "No projects configured yet. Use 'spiral use <yaml-file>' to set up a project."
        fi
        ;;

    list|schema|add|m|modify|show|commit|tui)
        active_file=$(get_active_file)
        if [ -z "$active_file" ]; then
            echo "Error: No active file set. Use 'spiral use <yaml-file>' first."
            exit 1
        fi
        
        schema_path=$(get_schema_path)
        if [ -z "$schema_path" ]; then
            echo "Error: No schema found for active file. Use 'spiral use <yaml-file>' to reset."
            exit 1
        fi
        
        case "$1" in
            list)
                echo "Available sections in: $active_file"
                yq eval 'keys' "$active_file" | sed 's/^-/  /'
                ;;

            schema)
                if [ $# -ne 2 ]; then
                    echo "Error: Specify section to show schema"
                    exit 1
                fi
                section="$2"
                echo "Schema fields for $section:"
                echo "-------------------------"
                get_schema_fields "$active_file" "$section" | tr ' ' '\n' | grep -v '^$' | sed 's/^/  /'
                ;;

            add)
                if [ $# -lt 2 ]; then
                    echo "Error: Specify section to add to."
                    exit 1
                fi
                section="$2"
                shift 2

                declare -A input_map
                for pair in "$@"; do
                    key="${pair%%=*}"
                    value="${pair#*=}"
                    input_map["$key"]="$value"
                done

                fields=$(yq eval ".$section | keys | .[]" "$schema_path")
                json="{"
                first=true
                for field in $fields; do
                    required=$(load_schema_field "$section" "$field" "required")
                    enum_list=$(load_schema_field "$section" "$field" "enum")

                    # Use provided value if exists
                    value="${input_map[$field]}"
                    if [ -z "$value" ] && [ "$required" = "true" ]; then
                        read -p "Enter value for required field '$field': " value
                    fi

                    if [ -n "$enum_list" ] && [ "$value" != "" ]; then
                        valid=false
                        for enum_val in $enum_list; do
                            if [ "$value" = "$enum_val" ]; then
                                valid=true
                                break
                            fi
                        done
                        if [ "$valid" = false ]; then
                            echo "❌ Invalid value '$value' for field '$field'. Must be one of: $enum_list"
                            exit 1
                        fi
                    fi

                    value="${value:-null}"
                    if [ "$value" = "null" ]; then
                        continue
                    fi
                    if [ "$first" = true ]; then
                        first=false
                    else
                        json+=","
                    fi
                    json+="\"$field\":\"$value\""
                done
                json+="}"

                yq eval ".$section += [$json]" -i "$active_file"
                echo "✅ Added new entry to $section"
                ;;

            m|modify)
                if [ $# -ne 4 ]; then
                    echo "Error: Specify section, id, and field=value"
                    exit 1
                fi
                section="$2"
                id="$3"
                field_value="$4"
                
                field="${field_value%%=*}"
                value="${field_value#*=}"
                
                yq eval "(.$section[] | select(.id == \"$id\").$field) = \"$value\"" -i "$active_file"
                echo "Updated $field to '$value' for ID: $id"
                ;;

            show)
                if [ $# -lt 2 ]; then
                    echo "Error: Specify section to show"
                    exit 1
                fi
                section="$2"
                shift 2
                
                if [ $# -eq 0 ]; then
                    # Show all fields
                    yq eval ".$section" "$active_file"
                else
                    # Show specific fields using our custom function
                    show_fields "$active_file" "$section" "$@"
                fi
                ;;
            commit)
                if [ $# -lt 2 ]; then
                    echo "Error: Provide the ID to fetch commit message, e.g., spiral commit D3.4 [--apply]"
                    exit 1
                fi
                id="$2"
                apply=false
                if [ "$3" = "--apply" ]; then
                    apply=true
                fi

                active_file=$(get_active_file)
                if [ -z "$active_file" ]; then
                    echo "Error: No active file set. Use 'spiral use <yaml-file>' first."
                    exit 1
                fi

                title=$(yq eval ".milestones[] | select(.id == \"$id\") | .title" "$active_file")
                if [ "$title" = "null" ] || [ -z "$title" ]; then
                    echo "❌ ID $id not found in milestones."
                    exit 1
                fi

                commit_msg="[${id}] ${title}"
                echo "$commit_msg"

                if [ "$apply" = true ]; then
                    git commit -m "$commit_msg"
                    # Update roadmap status to 'done'
                    yq eval "( .milestones[] | select(.id == \"$id\") ).release_status = \"done\"" -i "$active_file"
                    echo "✅ Updated release_status to 'done' for $id"
                fi
                ;;
            tui)
                while true; do
                    echo ""
                    echo "Spiral TUI — Choose an option:"
                    echo -e "\033[1;36m[a]\033[0m Add new milestone"
                    echo -e "\033[1;36m[m]\033[0m Modify milestone"
                    echo -e "\033[1;36m[x]\033[0m Pick/unpick milestones for this cycle"
                    echo -e "\033[1;36m[s]\033[0m Show current cycle"
                    echo -e "\033[1;36m[v]\033[0m View roadmap"
                    echo -e "\033[1;36m[y]\033[0m View in-cycle milestones"
                    echo -e "\033[1;36m[c]\033[0m Commit milestone (and mark done)"
                    echo -e "\033[1;36m[q]\033[0m Quit"
                    read -p "> " choice

                    case "$choice" in
                        a)
                            section="milestones"
                            echo "➕ Adding new milestone to section: $section"

                            # Schema is already validated above
                            declare -A input_map
                            fields=$(yq eval ".milestones | keys | .[]" "$schema_path")

                            for field in $fields; do
                                required=$(yq eval ".milestones.$field.required" "$schema_path")
                                enum_vals=$(yq eval ".milestones.$field.enum[]" "$schema_path" 2>/dev/null)

                                while true; do
                                    prompt="Enter value for field '$field'"
                                    if [ "$required" = "true" ]; then
                                        prompt="$prompt (required)"
                                    fi
                                    if [ -n "$enum_vals" ]; then
                                        prompt="$prompt [Options: $enum_vals]"
                                    fi
                                    prompt="$prompt: "

                                    read -p "$prompt" value

                                    # Don't convert empty values to "null" for required fields
                                    if [ "$required" = "true" ] && [ -z "$value" ]; then
                                        echo "❌ Field '$field' is required."
                                        continue
                                    fi

                                    # Set default to null only if value is empty and field is not required
                                    if [ -z "$value" ]; then
                                        value="null"
                                    fi

                                    # Only validate against enum if enum values exist AND value is not null
                                    if [ -n "$enum_vals" ] && [ "$value" != "null" ]; then
                                        valid_enum=false
                                        for enum in $enum_vals; do
                                            if [ "$value" = "$enum" ]; then
                                                valid_enum=true
                                                break
                                            fi
                                        done
                                        if [ "$valid_enum" = false ]; then
                                            echo "❌ Invalid value '$value' for field '$field'. Must be one of: $enum_vals"
                                            continue
                                        fi
                                    fi

                                    input_map["$field"]="$value"
                                    break
                                done
                            done

                            args=()
                            for key in "${!input_map[@]}"; do
                                args+=("$key=${input_map[$key]}")
                            done
                            args+=("from_tui=true")
                            spiral add "$section" "${args[@]}"
                            echo ""
                            read -p "Press enter to return to menu..." dummy
                            ;;
                        m)
                            echo "🔧 Modify existing milestone"
                            echo ""
                            
                            # Show existing milestones
                            echo "Existing milestones:"
                            echo "-------------------"
                            yq eval '.milestones[] | "\(.id) | \(.title) | \(.release_status)"' "$active_file" | nl -w3 -s'. '
                            echo ""
                            
                            # Get milestone ID
                            while true; do
                                read -p "Enter milestone ID to modify: " id
                                
                                # Check if milestone exists
                                title=$(yq eval ".milestones[] | select(.id == \"$id\") | .title" "$active_file")
                                if [ "$title" = "null" ] || [ -z "$title" ]; then
                                    echo "❌ Milestone ID '$id' not found. Please try again."
                                    continue
                                else
                                    echo "✅ Found milestone: $title"
                                    break
                                fi
                            done
                            
                            echo ""
                            echo "Current values for milestone $id:"
                            echo "--------------------------------"
                            
                                                         # Get all fields from schema and show current values
                             fields=$(yq eval ".milestones | keys | .[]" "$schema_path")
                            declare -A current_values
                            field_list=()
                            
                            i=1
                            for field in $fields; do
                                current_value=$(yq eval ".milestones[] | select(.id == \"$id\") | .$field" "$active_file")
                                if [ "$current_value" = "null" ]; then
                                    current_value="(empty)"
                                fi
                                current_values["$field"]="$current_value"
                                field_list+=("$field")
                                echo "$i. $field: $current_value"
                                ((i++))
                            done
                            
                            echo ""
                            while true; do
                                read -p "Enter field number to modify (1-$((i-1)), or 'done' to finish): " choice
                                
                                if [ "$choice" = "done" ]; then
                                    break
                                fi
                                
                                # Validate choice is a number and in range
                                if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt $((i-1)) ]; then
                                    echo "❌ Please enter a number between 1 and $((i-1)), or 'done'"
                                    continue
                                fi
                                
                                field_index=$((choice-1))
                                field="${field_list[$field_index]}"
                                current_value="${current_values[$field]}"
                                if [ "$current_value" = "(empty)" ]; then
                                    current_value=""
                                fi
                                
                                echo ""
                                echo "Modifying field: $field"
                                echo "Current value: $current_value"
                                
                                                                 # Get enum values if they exist
                                 enum_vals=$(yq eval ".milestones.$field.enum[]" "$schema_path" 2>/dev/null)
                                 required=$(yq eval ".milestones.$field.required" "$schema_path")
                                
                                while true; do
                                    prompt="Enter new value for '$field'"
                                    if [ "$required" = "true" ]; then
                                        prompt="$prompt (required)"
                                    fi
                                    if [ -n "$enum_vals" ]; then
                                        prompt="$prompt [Options: $enum_vals]"
                                    fi
                                    prompt="$prompt: "
                                    
                                    read -p "$prompt" new_value
                                    
                                    # Handle empty input
                                    if [ -z "$new_value" ]; then
                                        if [ "$required" = "true" ]; then
                                            echo "❌ Field '$field' is required."
                                            continue
                                        else
                                            new_value="null"
                                        fi
                                    fi
                                    
                                    # Validate enum if needed
                                    if [ -n "$enum_vals" ] && [ "$new_value" != "null" ]; then
                                        valid_enum=false
                                        for enum in $enum_vals; do
                                            if [ "$new_value" = "$enum" ]; then
                                                valid_enum=true
                                                break
                                            fi
                                        done
                                        if [ "$valid_enum" = false ]; then
                                            echo "❌ Invalid value '$new_value' for field '$field'. Must be one of: $enum_vals"
                                            continue
                                        fi
                                    fi
                                    
                                    # Update the milestone
                                    if [ "$new_value" = "null" ]; then
                                        yq eval "(.milestones[] | select(.id == \"$id\") | .$field) = null" -i "$active_file"
                                        echo "✅ Updated $field to (empty)"
                                    else
                                        yq eval "(.milestones[] | select(.id == \"$id\") | .$field) = \"$new_value\"" -i "$active_file"
                                        echo "✅ Updated $field to '$new_value'"
                                    fi
                                    
                                    # Update our tracking
                                    current_values["$field"]="$new_value"
                                    if [ "$new_value" = "null" ]; then
                                        current_values["$field"]="(empty)"
                                    fi
                                    
                                    break
                                done
                                
                                echo ""
                                echo "Current values for milestone $id:"
                                echo "--------------------------------"
                                i=1
                                for field in $fields; do
                                    echo "$i. $field: ${current_values[$field]}"
                                    ((i++))
                                done
                                echo ""
                            done
                            
                            echo "🎉 Milestone modification completed!"
                            echo ""
                            read -p "Press enter to return to menu..." dummy
                            ;;
                        x)
                            spiral cycle status
                            echo ""
                            read -p "Action (pick/unpick): " action
                            read -p "Enter milestone IDs (space-separated): " ids
                            spiral cycle "$action" $ids
                            echo ""
                            read -p "Press enter to return to menu..." dummy
                            ;;
                        s)
                            spiral cycle status
                            echo ""
                            read -p "Press enter to return to menu..." dummy
                            ;;
                        v)
                            spiral show milestones id title
                            echo ""
                            read -p "Press enter to return to menu..." dummy
                            ;;
                        y)
                            echo "In-Cycle Milestones:"
                            yq eval '.milestones[] | select(.cycle_status == "in-cycle") | "\(.id) | \(.title)"' "$active_file"
                            echo ""
                            read -p "Press enter to return to menu..." dummy
                            ;;
                        c)
                            read -p "Enter milestone ID to commit: " id
                            spiral commit "$id" --apply
                            echo ""
                            read -p "Press enter to return to menu..." dummy
                            ;;
                        q)
                            echo "Exiting Spiral TUI."
                            exit 0
                            ;;
                        *)
                            echo "Invalid choice. Try again."
                            read -p "Press enter to return to menu..." dummy
                            ;;
                    esac
                done
                ;;
        esac
        ;;

    cycle)
        # Ensure active roadmap file is set
        active_file=$(get_active_file)
        if [ -z "$active_file" ]; then
            echo "Error: No active file set. Use 'spiral use <yaml-file>' first."
            exit 1
        fi

        if [ $# -lt 2 ]; then
            echo "Usage: spiral cycle <pick|unpick|status> [ID...]"
            exit 1
        fi

        action="$2"
        shift 2

        case "$action" in
            pick)
                if [ $# -lt 1 ]; then
                    echo "Error: Specify at least one ID to pick into cycle."
                    exit 1
                fi
                for id in "$@"; do
                    yq eval "( .milestones[] | select(.id == \"$id\") ).cycle_status = \"in-cycle\"" -i "$active_file"
                    echo "✅ Marked $id as in-cycle"
                done
                ;;
            unpick)
                if [ $# -lt 1 ]; then
                    echo "Error: Specify at least one ID to unpick from cycle."
                    exit 1
                fi
                for id in "$@"; do
                    yq eval "( .milestones[] | select(.id == \"$id\") ).cycle_status = \"planned\"" -i "$active_file"
                    echo "✅ Marked $id as planned"
                done
                ;;
            status)
                echo "🗓 Cycle Status:"
                # Extract "id status" pairs, defaulting status to "planned"
                yq eval '.milestones[] | .id + " " + (.cycle_status // "planned")' "$active_file" | \
                awk '{status=$2; id=$1; groups[status]=groups[status]" "id} END {for (s in groups) print s":"groups[s]}'
                ;;
            *)
                echo "Error: Unknown cycle action '\''$action'\''. Use pick, unpick, or status."
                exit 1
                ;;
        esac
        ;;

    doc)
        # Ensure active roadmap file is set
        active_file=$(get_active_file)
        if [ -z "$active_file" ]; then
            echo "Error: No active file set. Use 'spiral use <yaml-file>' first."
            exit 1
        fi

        if [ $# -ne 2 ]; then
            echo "Usage: spiral doc <ID>"
            exit 1
        fi

        id="$2"

        # Fetch milestone fields
        title=$(yq eval ".milestones[] | select(.id == \"$id\") | .title" "$active_file")
        week=$(yq eval ".milestones[] | select(.id == \"$id\") | .week" "$active_file")
        cycle_status=$(yq eval ".milestones[] | select(.id == \"$id\") | (.cycle_status // \"planned\")" "$active_file")
        success_gates=$(yq eval ".milestones[] | select(.id == \"$id\") | .success_gate[]" "$active_file")

        if [ "$title" = "null" ] || [ -z "$title" ]; then
            echo "❌ ID $id not found in milestones."
            exit 1
        fi

        # Print design doc template
        echo "# Goal: $title [$id]"
        echo ""
        echo "## Hypothesis"
        echo "- _Add hypothesis about the goal here._"
        echo ""
        echo "## Why Now"
        echo "- Week: ${week}"
        echo "- Cycle Status: ${cycle_status}"
        echo ""
        echo "## Success Criteria"
        IFS=$'\n'
        for gate in $success_gates; do
            echo "- $gate"
        done
        unset IFS
        echo ""
        echo "## Risks / Unknowns"
        echo "- _List potential risks or unknowns here._"
        echo ""
        echo "## Experiments / Plan"
        echo "- _Outline the plan or experiments here._"
        echo ""
        exit 0
        ;;

    *)
        show_usage
        ;;
esac