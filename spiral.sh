#!/usr/bin/env bash

CONFIG_DIR="$HOME/.config/spiral"
CONFIG_FILE="$CONFIG_DIR/config"
mkdir -p "$CONFIG_DIR"

# Function to set active YAML file
set_active_file() {
    local yaml_file="$1"
    echo "active_file=$(realpath "$yaml_file")" > "$CONFIG_FILE"
    echo "Set active file to: $yaml_file"
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
    echo "  spiral                          # List all YAML files"
    echo "  spiral use <yaml-file>          # Set active YAML file"
    echo "  spiral current                  # Show current active file"
    echo "  spiral list                     # Show available sections"
    echo "  spiral schema <section>         # Show schema fields for section"
    echo "  spiral add <section> <key=value> ...  # Add new entry (auto-fills missing fields)"
    echo "  spiral m|modify <section> <id> <field=value>  # Modify a value"
    echo "  spiral show <section> [fields]  # Show entries"
    echo ""
    echo "Examples:"
    echo "  spiral use roadmap/v1.yml       # Set active file"
    echo "  spiral schema milestones        # Show all fields in milestones"
    echo "  spiral add milestones week=W8 version=0.8.0 id=R8.8  # Auto-fills other fields"
    echo "  spiral m milestones D3.2 release_status=done"
    echo "  spiral show milestones id title"
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
    yq eval ".$section.$field.$key" "$HOME/.config/spiral/schema.yml"
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
        if [ -n "$active_file" ]; then
            echo "Current active file: $active_file"
        else
            echo "No active file set. Use 'spiral use <yaml-file>' to set one."
        fi
        ;;

    list|schema|add|m|modify|show|commit|tui)
        active_file=$(get_active_file)
        if [ -z "$active_file" ]; then
            echo "Error: No active file set. Use 'spiral use <yaml-file>' first."
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

                fields=$(yq eval "keys | .[]" "$HOME/.config/spiral/schema.yml")
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

                            declare -A input_map
                            fields=$(yq eval "keys | .[]" "$HOME/.config/spiral/schema.yml")

                            for field in $fields; do
                                required=$(yq eval ".milestones.$field.required" "$HOME/.config/spiral/schema.yml")
                                enum_vals=$(yq eval ".milestones.$field.enum[]" "$HOME/.config/spiral/schema.yml" 2>/dev/null)

                                prompt="Enter value for $field"
                                if [ "$required" = "true" ]; then
                                    prompt="$prompt (required)"
                                fi
                                if [ -n "$enum_vals" ]; then
                                    prompt="$prompt [Options: $enum_vals]"
                                fi
                                prompt="$prompt: "

                                read -p "$prompt" value
                                value="${value:-null}"
                                input_map["$field"]="$value"
                            done

                            args=()
                            for key in "${!input_map[@]}"; do
                                args+=("$key=${input_map[$key]}")
                            done

                            spiral add "$section" "${args[@]}"
                            echo ""
                            read -p "Press enter to return to menu..." dummy
                            ;;
                        m)
                            read -p "Section (e.g. milestones): " section
                            read -p "ID: " id
                            read -p "Field and new value (field=value): " fv
                            spiral m "$section" "$id" "$fv"
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