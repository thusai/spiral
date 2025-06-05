#!/usr/bin/env bash

CONFIG_DIR="$HOME/.config/spiral"
CONFIG_FILE="$CONFIG_DIR/config"
PROJECTS_FILE="$CONFIG_DIR/projects"
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

# Function to auto-detect YAML file in current directory
find_yaml_file() {
    local yaml_files=(*.yml *.yaml)
    local found_files=()
    
    for file in "${yaml_files[@]}"; do
        if [ -f "$file" ]; then
            found_files+=("$file")
        fi
    done
    
    if [ ${#found_files[@]} -eq 1 ]; then
        echo "${found_files[0]}"
        return 0
    elif [ ${#found_files[@]} -gt 1 ]; then
        echo "🔍 Multiple YAML files found:" >&2
        for i in "${!found_files[@]}"; do
            echo "$((i+1)). ${found_files[$i]}" >&2
        done
        echo "" >&2
        while true; do
            read -p "Choose YAML file (1-${#found_files[@]}): " choice >&2
            if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#found_files[@]} ]; then
                echo "${found_files[$((choice-1))]}"
                return 0
            else
                echo "❌ Invalid choice. Please enter a number between 1 and ${#found_files[@]}" >&2
            fi
        done
    else
        echo "❌ No YAML files found in current directory" >&2
        return 1
    fi
}

# Function to create a new project
create_project() {
    local project_name="$1"
    local yaml_file="$2"
    local schema_file="$3"
    
    if [ -z "$project_name" ]; then
        echo "❌ Usage: spiral init <project-name> [yaml-file] [schema-file]"
        exit 1
    fi
    
    # Auto-detect YAML file if not provided
    if [ -z "$yaml_file" ]; then
        echo "🔍 Auto-detecting YAML file..."
        yaml_file=$(find_yaml_file "$project_name")
        if [ $? -ne 0 ]; then
            exit 1
        fi
        echo "✅ Found YAML file: $yaml_file"
    fi
    
    # Auto-detect schema file if not provided
    if [ -z "$schema_file" ]; then
        echo "🔍 Auto-detecting schema file..."
        schema_file=$(find_schema_file "$yaml_file")
        if [ -z "$schema_file" ]; then
            echo "❌ Could not find schema.yml for $yaml_file"
            echo "Looked in:"
            echo "  - $(dirname "$yaml_file")/schema.yml"
            echo "  - $(dirname "$yaml_file")/config/schema.yml" 
            echo "  - $(dirname "$yaml_file")/../config/schema.yml"
            echo "  - ./config/schema.yml"
            echo ""
            echo "Please specify schema file: spiral init $project_name $yaml_file <schema-file>"
            exit 1
        fi
        echo "✅ Found schema file: $schema_file"
    fi
    
    # Check if project already exists
    if [ -f "$PROJECTS_FILE" ] && grep -q "^$project_name=" "$PROJECTS_FILE"; then
        echo "❌ Project '$project_name' already exists"
        exit 1
    fi
    
    # Get absolute paths
    local yaml_path
    local schema_path
    
    # Resolve absolute path for YAML file
    if [[ "$yaml_file" = /* ]]; then
        yaml_path="$yaml_file"
    else
        yaml_path="$PWD/$yaml_file"
    fi
    
    # Resolve absolute path for schema file  
    if [[ "$schema_file" = /* ]]; then
        schema_path="$schema_file"
    else
        schema_path="$PWD/$schema_file"
    fi
    
    # Create directories if they don't exist
    mkdir -p "$(dirname "$yaml_path")"
    mkdir -p "$(dirname "$schema_path")"
    
    # Create empty YAML file if it doesn't exist
    if [ ! -f "$yaml_path" ]; then
        echo "milestones: []" > "$yaml_path"
        echo "✅ Created $yaml_file"
    else
        echo "ℹ️  Using existing $yaml_file"
    fi
    
    # Create basic schema if it doesn't exist
    if [ ! -f "$schema_path" ]; then
        cat > "$schema_path" << 'EOF'
milestones:
  id:
    required: true
  title:
    required: true
  week:
    required: false
  version:
    required: false
  release_status:
    required: true
    enum:
      - parked
      - planned
      - in-progress
      - done
      - cancelled
  cycle_status:
    required: false
    enum:
      - planned
      - in-cycle
  success_gate:
    required: false
  notes:
    required: false
  subtasks:
    required: false

subtasks:
  id:
    required: true
  parent_id:
    required: true
  title:
    required: true
  status:
    required: true
    enum:
      - planned
      - in-progress
      - done
      - cancelled
  notes:
    required: false
EOF
        echo "✅ Created $schema_file with default milestone schema"
    else
        echo "ℹ️  Using existing $schema_file"
    fi
    
    # Add project to projects file
    echo "$project_name=$yaml_path|$schema_path" >> "$PROJECTS_FILE"
    echo "✅ Project '$project_name' created and registered"
    
    # Set as active project
    cat > "$CONFIG_FILE" << EOF
active_file="$yaml_path"
schema_path="$schema_path"
current_project="$project_name"
EOF
    echo "✅ Set '$project_name' as active project"
    echo ""
    echo "You can now:"
    echo "  spiral add milestones id=M1.0 title='My First Milestone' release_status=planned"
    echo "  spiral use $project_name"
    echo "  spiral show milestones"
}

# Function to switch to a project by name
use_project() {
    local identifier="$1"
    
    if [ -z "$identifier" ]; then
        echo "❌ Usage: spiral use <project-name|yaml-file>"
        exit 1
    fi
    
    # First check if it's a project name
    if [ -f "$PROJECTS_FILE" ]; then
        local project_line=$(grep "^$identifier=" "$PROJECTS_FILE")
        if [ -n "$project_line" ]; then
            local yaml_path=$(echo "$project_line" | cut -d'=' -f2 | cut -d'|' -f1)
            local schema_path=$(echo "$project_line" | cut -d'=' -f2 | cut -d'|' -f2)
            
            cat > "$CONFIG_FILE" << EOF
active_file="$yaml_path"
schema_path="$schema_path"
current_project="$identifier"
EOF
            echo "✅ Switched to project '$identifier'"
            echo "   YAML: $yaml_path"
            echo "   Schema: $schema_path"
            return
        fi
    fi
    
    # If not a project name, treat as file path (existing behavior)
    set_active_file "$identifier"
}

# Function to list all projects
list_projects() {
    if [ ! -f "$PROJECTS_FILE" ] || [ ! -s "$PROJECTS_FILE" ]; then
        echo "No projects configured yet."
        echo "Use 'spiral init <project-name> <yaml-file> <schema-file>' to create one."
        return
    fi
    
    echo "Configured Projects:"
    echo "==================="
    
    local current_project=""
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        current_project="$current_project"
    fi
    
    while IFS='=' read -r project_name project_info; do
        local yaml_path=$(echo "$project_info" | cut -d'|' -f1)
        local schema_path=$(echo "$project_info" | cut -d'|' -f2)
        
        local active_marker=""
        if [ "$project_name" = "$current_project" ]; then
            active_marker=" ← ACTIVE"
        fi
        
        echo "$project_name$active_marker"
        echo "  YAML: $yaml_path"
        echo "  Schema: $schema_path"
        echo ""
    done < "$PROJECTS_FILE"
}

# Function to get schema fields for a section
get_schema_fields() {
    local file="$1"
    local section="$2"
    
    # Get all unique keys from existing entries in the section
    yq eval ".$section | map(keys) | flatten | unique" "$file" | sed 's/^- //' | tr '\n' ' '
}

# Function to generate next subtask ID (git-aware)
generate_subtask_id() {
    local parent_id="$1"
    local active_file=$(get_active_file)
    
    # Initialize subtasks array if it doesn't exist
    yq eval ".subtasks //= []" -i "$active_file"
    
    # Find highest existing subtask number from git history (primary source)
    local git_max_num=$(git log --oneline --all | grep -o "\[$parent_id\.[0-9]*\]" | \
                       sed "s/\[$parent_id\.//g; s/\]//g" | sort -n | tail -1)
    
    # Also check YAML as backup
    local yaml_max_num=$(yq eval ".subtasks[] | select(.parent_id == \"$parent_id\") | .id" "$active_file" | \
                        grep "^$parent_id\." | sed "s/^$parent_id\.//" | sort -n | tail -1)
    
    # Use the higher of the two
    local max_num=$git_max_num
    if [ -n "$yaml_max_num" ] && [ "$yaml_max_num" -gt "${max_num:-0}" ]; then
        max_num=$yaml_max_num
    fi
    
    if [ -z "$max_num" ]; then
        echo "$parent_id.1"
    else
        echo "$parent_id.$((max_num + 1))"
    fi
}

# Function to add subtask
add_subtask() {
    local parent_id="$1"
    local title="$2"
    local status="${3:-planned}"
    local active_file=$(get_active_file)
    
    # Validate parent milestone exists
    local parent_title=$(yq eval ".milestones[] | select(.id == \"$parent_id\") | .title" "$active_file")
    if [ "$parent_title" = "null" ] || [ -z "$parent_title" ]; then
        echo "❌ Parent milestone '$parent_id' not found"
        return 1
    fi
    
    # Generate subtask ID
    local subtask_id=$(generate_subtask_id "$parent_id")
    
    # Create subtask object
    local subtask_json="{\"id\":\"$subtask_id\",\"parent_id\":\"$parent_id\",\"title\":\"$title\",\"status\":\"$status\"}"
    
    # Add to subtasks array
    yq eval ".subtasks += [$subtask_json]" -i "$active_file"
    
    echo "✅ Added subtask $subtask_id: $title"
    echo "   Parent: $parent_id ($parent_title)"
    
    # Store context for smart commits (project-scoped)
    local project_name=$(basename "$active_file" .yml)
    echo "$parent_id" > "$CONFIG_DIR/current_context_${project_name}"
    
    return 0
}

# Function to show subtasks for a milestone
show_subtasks() {
    local parent_id="$1"
    local active_file=$(get_active_file)
    
    if [ -z "$parent_id" ]; then
        echo "❌ Usage: spiral subtasks <parent-id>"
        return 1
    fi
    
    # Check if parent exists
    local parent_title=$(yq eval ".milestones[] | select(.id == \"$parent_id\") | .title" "$active_file")
    if [ "$parent_title" = "null" ] || [ -z "$parent_title" ]; then
        echo "❌ Milestone '$parent_id' not found"
        return 1
    fi
    
    echo "Subtasks for $parent_id: $parent_title"
    echo "$(printf '─%.0s' {1..50})"
    
    # Show subtasks
    local subtasks=$(yq eval ".subtasks[]? | select(.parent_id == \"$parent_id\")" "$active_file")
    if [ -z "$subtasks" ] || [ "$subtasks" = "null" ]; then
        echo "No subtasks found"
        return 0
    fi
    
    # Format and display subtasks
    yq eval ".subtasks[]? | select(.parent_id == \"$parent_id\") | \"\(.id)  \(.status)  \(.title)\"" "$active_file" | \
    while read -r line; do
        if [ -n "$line" ]; then
            id=$(echo "$line" | awk '{print $1}')
            status=$(echo "$line" | awk '{print $2}')
            title=$(echo "$line" | cut -d' ' -f3-)
            
            # Colorize status
            case "$status" in
                "done") colored_status="\033[32m$status\033[0m" ;;
                "in-progress") colored_status="\033[33m$status\033[0m" ;;
                "planned") colored_status="\033[36m$status\033[0m" ;;
                "parked") colored_status="\033[91m$status\033[0m" ;;
                "cancelled") colored_status="\033[31m$status\033[0m" ;;
                *) colored_status="$status" ;;
            esac
            
            printf "  %-12s %-15s %s\n" "$id" "$(echo -e "$colored_status")" "$title"
        fi
    done
}

# Function to show recent working context
show_context() {
    local active_file=$(get_active_file)
    
    echo "Recent Working Context:"
    echo "======================"
    
    # Show current context if exists (project-scoped)
    local project_name=$(basename "$active_file" .yml)
    local context_file="$CONFIG_DIR/current_context_${project_name}"
    if [ -f "$context_file" ]; then
        local current_context=$(cat "$context_file")
        local context_title=$(yq eval ".milestones[] | select(.id == \"$current_context\") | .title" "$active_file")
        echo "🎯 Current: $current_context - $context_title"
        echo ""
    fi
    
    # Show recent milestones (last 5 with in-progress or in-cycle status)
    echo "Recent milestones:"
    yq eval '.milestones[] | select(.release_status == "in-progress" or .cycle_status == "in-cycle") | "\(.id)  \(.title)"' "$active_file" | \
    head -5 | while read -r line; do
        if [ -n "$line" ]; then
            echo "  $line"
        fi
    done
}

# Function for smart commit with auto-context detection
smart_commit() {
    local message="$1"
    local auto_mode="$2"
    local active_file=$(get_active_file)
    
    if [ -z "$message" ]; then
        echo "❌ Usage: spiral commit <message> [--auto]"
        return 1
    fi
    
    # Check git status
    if ! git status &>/dev/null; then
        echo "❌ Not in a git repository"
        return 1
    fi
    
    local parent_id=""
    local subtask_id=""
    
    # Try to detect context (project-scoped)
    local project_name=$(basename "$active_file" .yml)
    local context_file="$CONFIG_DIR/current_context_${project_name}"
    if [ -f "$context_file" ]; then
        parent_id=$(cat "$context_file")
        local parent_title=$(yq eval ".milestones[] | select(.id == \"$parent_id\") | .title" "$active_file")
        
        if [ "$auto_mode" = "--auto" ]; then
            echo "🔍 Auto-detected context: $parent_id ($parent_title)"
            echo "Creating subtask automatically..."
        else
            echo "🎯 Current context: $parent_id ($parent_title)"
            read -p "Create subtask for this milestone? [Y/n]: " create_subtask
            
            if [[ "$create_subtask" =~ ^[Nn] ]]; then
                echo "Available milestones:"
                yq eval '.milestones[] | .id + "  " + .title' "$active_file" | head -5
                read -p "Enter milestone ID (or 'skip' for no association): " parent_id
                
                if [ "$parent_id" = "skip" ]; then
                    git add . && git commit -m "$message"
                    echo "✅ Created regular commit: $message"
                    return 0
                fi
            fi
        fi
        
        # Create subtask and commit
        subtask_id=$(generate_subtask_id "$parent_id")
        add_subtask "$parent_id" "$message" "in-progress"
        
        # Create commit with subtask tagging
        local commit_message="[$subtask_id] $message"
        git add . && git commit -m "$commit_message"
        
        echo "✅ Created commit: $commit_message"
        echo "✅ Added subtask: $subtask_id"
        
    else
        # No context
        if [ "$auto_mode" = "--auto" ]; then
            echo "🎯 No working context - auto-creating milestone from message"
            
            # Auto-create milestone from message  
            local auto_title=$(echo "$message" | cut -d'-' -f1 | sed 's/^ *//g; s/ *$//g')
            if [ ${#auto_title} -gt 50 ]; then
                auto_title=$(echo "$auto_title" | cut -c1-47)"..."
            fi
            
            # Generate next milestone ID
            local next_id=$(generate_next_milestone_id)
            
            echo "🎯 Auto-creating milestone: $next_id - $auto_title"
            
            # Add milestone
            yq eval ".milestones += [{\"id\": \"$next_id\", \"title\": \"$auto_title\", \"release_status\": \"in-progress\", \"cycle_status\": \"out-of-cycle\"}]" -i "$active_file"
            
                            # Set as context  
                echo "$next_id" > "$context_file"
            
            # Create subtask
            subtask_id=$(generate_subtask_id "$next_id")
            add_subtask "$next_id" "$message" "in-progress"
            
            local commit_message="[$subtask_id] $message"
            git add . && git commit -m "$commit_message"
            
            echo "✅ Created milestone: $next_id - $auto_title"
            echo "✅ Created commit: $commit_message"
            echo "✅ Added subtask: $subtask_id"
            echo "✅ Set working context to: $next_id"
            return 0
        fi
        
        # Show recent milestones and ask
        echo "Recent milestones:"
        yq eval '.milestones[] | .id + "  " + .title' "$active_file" | head -5
        echo ""
        read -p "Associate with milestone? [ID/auto/new/skip]: " choice
        
        case "$choice" in
            "skip")
                git add . && git commit -m "$message"
                echo "✅ Created regular commit: $message"
                ;;
            "auto")
                # Auto-create milestone from message
                local auto_title=$(echo "$message" | cut -d'-' -f1 | sed 's/^ *//g; s/ *$//g')
                if [ ${#auto_title} -gt 50 ]; then
                    auto_title=$(echo "$auto_title" | cut -c1-47)"..."
                fi
                
                # Generate next milestone ID
                local next_id=$(generate_next_milestone_id)
                
                echo "🎯 Auto-creating milestone: $next_id - $auto_title"
                
                # Add milestone
                yq eval ".milestones += [{\"id\": \"$next_id\", \"title\": \"$auto_title\", \"release_status\": \"in-progress\", \"cycle_status\": \"out-of-cycle\"}]" -i "$active_file"
                
                # Set as context
                echo "$next_id" > "$context_file"
                
                # Create subtask
                subtask_id=$(generate_subtask_id "$next_id")
                add_subtask "$next_id" "$message" "in-progress"
                
                local commit_message="[$subtask_id] $message"
                git add . && git commit -m "$commit_message"
                
                echo "✅ Created milestone: $next_id - $auto_title"
                echo "✅ Created commit: $commit_message"
                echo "✅ Added subtask: $subtask_id"
                echo "✅ Set working context to: $next_id"
                ;;
            "new")
                echo "Create new milestone first with: spiral add milestones"
                return 1
                ;;
            *)
                # Validate milestone exists
                local milestone_title=$(yq eval ".milestones[] | select(.id == \"$choice\") | .title" "$active_file")
                if [ "$milestone_title" = "null" ] || [ -z "$milestone_title" ]; then
                    echo "❌ Milestone '$choice' not found"
                    return 1
                fi
                
                subtask_id=$(generate_subtask_id "$choice")
                add_subtask "$choice" "$message" "in-progress"
                
                local commit_message="[$subtask_id] $message"
                git add . && git commit -m "$commit_message"
                
                echo "✅ Created commit: $commit_message"
                echo "✅ Added subtask: $subtask_id"
                ;;
        esac
    fi
}

# Function to generate the next available milestone ID
generate_next_milestone_id() {
    local active_file=$(get_active_file)
    
    # Get all existing milestone IDs and find the highest number
    local highest_num=0
    local existing_ids=$(yq eval '.milestones[].id' "$active_file")
    
    while IFS= read -r id; do
        if [[ "$id" =~ ^S([0-9]+)\.([0-9]+)$ ]]; then
            local major_num=${BASH_REMATCH[1]}
            local minor_num=${BASH_REMATCH[2]}
            if [ "$major_num" -gt "$highest_num" ]; then
                highest_num=$major_num
            fi
        fi
    done <<< "$existing_ids"
    
    # Generate next ID
    local next_num=$((highest_num + 1))
    echo "S${next_num}.1"
}

# Function to check if ID already exists in git history
check_id_in_git_history() {
    local id="$1"
    
    # Get all commit messages and extract IDs in [ID] format
    local existing_ids=$(git log --oneline --all | grep -o '\[S[^]]*\]' | sed 's/\[//g; s/\]//g' | sort | uniq)
    
    # Check if the ID already exists
    if echo "$existing_ids" | grep -q "^$id$"; then
        return 0  # ID exists
    else
        return 1  # ID doesn't exist
    fi
}

# Function to set working context (project-scoped)
set_context() {
    local milestone_id="$1"
    local active_file=$(get_active_file)
    
    if [ -z "$milestone_id" ]; then
        echo "❌ Usage: spiral context <milestone-id>"
        return 1
    fi
    
    # Validate milestone exists
    local title=$(yq eval ".milestones[] | select(.id == \"$milestone_id\") | .title" "$active_file")
    if [ "$title" = "null" ] || [ -z "$title" ]; then
        echo "❌ Milestone '$milestone_id' not found"
        return 1
    fi
    
    # Use project-scoped context file
    local project_name=$(basename "$active_file" .yml)
    echo "$milestone_id" > "$CONFIG_DIR/current_context_${project_name}"
    echo "✅ Set working context to: $milestone_id - $title"
}

# Function to show hierarchical view
show_hierarchical() {
    local active_file=$(get_active_file)
    
    echo "Project Roadmap (Hierarchical View)"
    echo "=================================="
    echo ""
    
    # Get milestone count
    local milestone_count=$(yq eval '.milestones | length' "$active_file")
    
    # Process each milestone by index
    for ((i=0; i<milestone_count; i++)); do
        local id=$(yq eval ".milestones[$i].id" "$active_file")
        local title=$(yq eval ".milestones[$i].title" "$active_file")
        local status=$(yq eval ".milestones[$i].release_status" "$active_file")
        
        # Skip null entries
        if [ "$id" = "null" ]; then
            continue
        fi
        
        # Colorize status
        case "$status" in
            "done") colored_status="\033[32m$status\033[0m" ;;
            "in-progress") colored_status="\033[33m$status\033[0m" ;;
            "planned") colored_status="\033[36m$status\033[0m" ;;
            "parked") colored_status="\033[91m$status\033[0m" ;;
            "cancelled") colored_status="\033[31m$status\033[0m" ;;
            *) colored_status="$status" ;;
        esac
        
        printf "📋 %-12s %-15s %s\n" "$id" "$(echo -e "$colored_status")" "$title"
        
        # Show subtasks for this milestone  
        yq eval ".subtasks[]? | select(.parent_id == \"$id\") | \"\(.id)|\(.status)|\(.title)\"" "$active_file" | \
        while IFS='|' read -r sub_id sub_status sub_title; do
            if [ -n "$sub_id" ]; then
                case "$sub_status" in
                    "done") colored_sub_status="\033[32m$sub_status\033[0m" ;;
                    "in-progress") colored_sub_status="\033[33m$sub_status\033[0m" ;;
                    "planned") colored_sub_status="\033[36m$sub_status\033[0m" ;;
                    "cancelled") colored_sub_status="\033[31m$sub_status\033[0m" ;;
                    *) colored_sub_status="$sub_status" ;;
                esac
                
                printf "   └─ %-10s %-15s %s\n" "$sub_id" "$(echo -e "$colored_sub_status")" "$sub_title"
            fi
        done
        echo ""
    done
}

# Function to show usage
show_usage() {
    echo "Usage:"
    echo "  spiral                          # List all YAML files in current directory"
    echo "  spiral init <project> [yaml] [schema]  # Create new project"
    echo "  spiral use <yaml-file>          # Set active YAML file and project"
    echo "  spiral current                  # Show current active file and schema"
    echo "  spiral projects                 # Show all configured projects"
    echo "  spiral context [milestone-id]  # Show/set working context"
    echo "  spiral list                     # Show available sections in active file"
    echo "  spiral schema <section>         # Show schema fields for section"
    echo "  spiral add <section> <key=value> ...  # Add new entry (auto-fills missing fields)"
    echo "  spiral subtask <parent-id> <title>  # Add subtask to milestone"
    echo "  spiral subtasks <parent-id>     # Show subtasks for milestone"
    echo "  spiral commit <ID|message> [--auto]  # Smart commit or commit existing"
    echo "  spiral m|modify <section> <id> <field=value>  # Modify a value"
    echo "  spiral show <section> [fields]  # Show entries (milestones|all for hierarchy)"
    echo "  spiral tui                      # Launch interactive TUI"
    echo ""
    echo "Examples:"
    echo "  spiral init myproject roadmap.yml config/schema.yml  # Create new project"
    echo "  spiral use myproject            # Set project as active by name"
    echo "  spiral context S3.4             # Set working context to milestone S3.4"
    echo "  spiral subtask S3.4 'Fix validation bug'  # Add subtask to S3.4"
    echo "  spiral commit 'implement auto-detect' --auto  # Smart commit"
    echo "  spiral subtasks S3.4            # Show all subtasks for S3.4"
    echo "  spiral show all                 # Hierarchical view with subtasks"
    echo "  spiral add milestones week=W8 version=0.8.0 id=R8.8  # Auto-fills other fields"
    echo "  spiral show milestones id title # Clean milestone list"
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

# Function to show specific fields for a section in clean column format
show_fields() {
    local file="$1"
    local section="$2"
    shift 2
    local fields=("$@")
    
    # Get the count of items in the section
    local count=$(yq eval ".$section | length" "$file")
    
    if [ $count -eq 0 ]; then
        echo "No entries found in $section"
        return
    fi
    
    # Collect all data first to calculate column widths
    declare -a all_rows
    declare -a col_widths
    
    # Initialize column widths with header lengths  
    for i in "${!fields[@]}"; do
        col_widths[$i]=${#fields[$i]}
    done
    
    # Collect data and calculate max widths (without color codes)
    for ((row=0; row<count; row++)); do
        local row_data=()
        for col in "${!fields[@]}"; do
            local field="${fields[$col]}"
            local value=$(yq eval ".$section[$row].$field" "$file")
            if [ "$value" = "null" ]; then
                value=""
            fi
            row_data+=("$value")
            
            # Update column width if this value is longer
            if [ ${#value} -gt ${col_widths[$col]} ]; then
                col_widths[$col]=${#value}
            fi
        done
        all_rows+=("$(IFS='|'; echo "${row_data[*]}")")
    done
    
    # Function to colorize status values
    colorize_status() {
        local value="$1"
        local field="$2"
        
        if [[ "$field" == "release_status" || "$field" == "cycle_status" ]]; then
            case "$value" in
                "done") echo -e "\033[32m$value\033[0m" ;;        # Green
                "in-progress"|"starting") echo -e "\033[33m$value\033[0m" ;;   # Yellow  
                "planned") echo -e "\033[36m$value\033[0m" ;;      # Cyan
                "cancelled"|"skipped") echo -e "\033[31m$value\033[0m" ;;      # Red
                "in-cycle") echo -e "\033[35m$value\033[0m" ;;     # Magenta
                *) echo "$value" ;;
            esac
        else
            echo "$value"
        fi
    }
    
    # Print header with simple underline
    for i in "${!fields[@]}"; do
        printf "%-${col_widths[$i]}s" "${fields[$i]^^}"  # Uppercase headers
        if [ $i -lt $((${#fields[@]} - 1)) ]; then
            printf "  "
        fi
    done
    printf "\n"
    
    # Print separator line
    for i in "${!fields[@]}"; do
        printf "%-${col_widths[$i]}s" "$(printf '─%.0s' $(seq 1 ${col_widths[$i]}))"
        if [ $i -lt $((${#fields[@]} - 1)) ]; then
            printf "  "
        fi
    done
    printf "\n"
    
    # Print data rows
    for row_line in "${all_rows[@]}"; do
        IFS='|' read -ra row_data <<< "$row_line"
        for i in "${!row_data[@]}"; do
            local value="${row_data[$i]}"
            local field="${fields[$i]}"
            local colored_value=$(colorize_status "$value" "$field")
            
            # Calculate padding (accounting for color codes not taking visual space)
            local visual_length=${#value}
            local total_length=${#colored_value}
            local padding=$((${col_widths[$i]} - visual_length))
            
            printf "%s%*s" "$colored_value" $padding ""
            if [ $i -lt $((${#row_data[@]} - 1)) ]; then
                printf "  "
            fi
        done
        printf "\n"
    done
}

# Function to load schema for a given section
load_schema_field() {
    local section="$1"
    local field="$2"
    local key="$3"
    local schema_path=$(get_schema_path)
    if [ -z "$schema_path" ]; then
        echo "⛔︎ No active project set. Use 'spiral use <yaml-file>' first."
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
    init)
        if [ $# -lt 2 ] || [ $# -gt 4 ]; then
            echo "⛔︎ Usage: spiral init <project-name> [yaml-file] [schema-file]"
            exit 1
        fi
        create_project "$2" "$3" "$4"
        ;;

    use)
        if [ $# -ne 2 ]; then
            echo "❌ Usage: spiral use <project-name|yaml-file>"
            exit 1
        fi
        use_project "$2"
        ;;

    current)
        active_file=$(get_active_file)
        schema_path=$(get_schema_path)
        if [ -n "$active_file" ]; then
            current_project=""
            if [ -f "$CONFIG_FILE" ]; then
                source "$CONFIG_FILE"
                current_project="$current_project"
            fi
            
            echo "Current active file: $active_file"
            if [ -n "$current_project" ]; then
                echo "Project: $current_project"
            fi
            if [ -n "$schema_path" ]; then
                echo "Using schema: $schema_path"
            else
                echo "⚠️  No schema found for this file"
            fi
        else
            echo "No active file set. Use 'spiral use <project-name|yaml-file>' to set one."
        fi
        ;;

    projects)
        list_projects
        ;;

    context)
        if [ $# -eq 1 ]; then
            # Show context
            active_file=$(get_active_file)
            if [ -z "$active_file" ]; then
                echo "Error: No active file set. Use 'spiral use <yaml-file>' first."
                exit 1
            fi
            show_context
        else
            # Set context
            active_file=$(get_active_file)
            if [ -z "$active_file" ]; then
                echo "Error: No active file set. Use 'spiral use <yaml-file>' first."
                exit 1
            fi
            set_context "$2"
        fi
        ;;

    subtask)
        active_file=$(get_active_file)
        if [ -z "$active_file" ]; then
            echo "Error: No active file set. Use 'spiral use <yaml-file>' first."
            exit 1
        fi
        
        if [ $# -ne 3 ]; then
            echo "❌ Usage: spiral subtask <parent-id> <title>"
            exit 1
        fi
        add_subtask "$2" "$3"
        ;;

    subtasks)
        active_file=$(get_active_file)
        if [ -z "$active_file" ]; then
            echo "Error: No active file set. Use 'spiral use <yaml-file>' first."
            exit 1
        fi
        
        if [ $# -ne 2 ]; then
            echo "❌ Usage: spiral subtasks <parent-id>"
            exit 1
        fi
        show_subtasks "$2"
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
                
                # Special case for hierarchical view
                if [ "$section" = "all" ]; then
                    show_hierarchical
                    exit 0
                fi
                
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
                    echo "❌ Usage: spiral commit <ID|message> [--auto]"
                    exit 1
                fi
                
                input="$2"
                auto_mode="$3"
                
                # Check if input looks like an ID (contains dots or short alphanumeric)
                if [[ "$input" =~ ^[A-Za-z0-9]+(\.[0-9]+)*$ ]] && [ ${#input} -le 15 ]; then
                    # This looks like an ID - check if it exists
                    milestone_title=$(yq eval ".milestones[] | select(.id == \"$input\") | .title" "$active_file")
                    subtask_title=$(yq eval ".subtasks[]? | select(.id == \"$input\") | .title" "$active_file")
                    
                    if [ "$milestone_title" != "null" ] && [ -n "$milestone_title" ]; then
                        # Check if milestone ID already exists in git history
                        if check_id_in_git_history "$input"; then
                            echo "❌ Milestone $input has already been committed to git. Cannot commit again."
                            echo "   Found in git history: $(git log --oneline --grep="\[$input\]" | head -1)"
                            exit 1
                        fi
                        
                        # Existing milestone
                        commit_msg="[$input] $milestone_title"
                        echo "Commit message: $commit_msg"
                        
                        if [ "$auto_mode" = "--auto" ]; then
                            if git add . && git commit -m "$commit_msg"; then
                                yq eval "(.milestones[] | select(.id == \"$input\")).release_status = \"done\"" -i "$active_file"
                                echo "✅ Auto-committed and marked milestone $input as done"
                            else
                                echo "❌ Git commit failed"
                                exit 1
                            fi
                        else
                            read -p "Commit and mark as done? [Y/n]: " confirm
                            if [[ ! "$confirm" =~ ^[Nn] ]]; then
                                if git add . && git commit -m "$commit_msg"; then
                                    yq eval "(.milestones[] | select(.id == \"$input\")).release_status = \"done\"" -i "$active_file"
                                    echo "✅ Committed and marked milestone $input as done"
                                else
                                    echo "❌ Git commit failed"
                                    exit 1
                                fi
                            else
                                echo "ℹ️  Skipped commit"
                            fi
                        fi
                        
                    elif [ "$subtask_title" != "null" ] && [ -n "$subtask_title" ]; then
                        # Check if subtask ID already exists in git history
                        if check_id_in_git_history "$input"; then
                            echo "❌ Subtask $input has already been committed to git. Cannot commit again."
                            echo "   Found in git history: $(git log --oneline --grep="\[$input\]" | head -1)"
                            exit 1
                        fi
                        
                        # Existing subtask
                        commit_msg="[$input] $subtask_title"
                        echo "Commit message: $commit_msg"
                        
                        if [ "$auto_mode" = "--auto" ]; then
                            if git add . && git commit -m "$commit_msg"; then
                                yq eval "(.subtasks[] | select(.id == \"$input\")).status = \"done\"" -i "$active_file"
                                echo "✅ Auto-committed and marked subtask $input as done"
                            else
                                echo "❌ Git commit failed"
                                exit 1
                            fi
                        else
                            read -p "Commit and mark as done? [Y/n]: " confirm
                            if [[ ! "$confirm" =~ ^[Nn] ]]; then
                                if git add . && git commit -m "$commit_msg"; then
                                    yq eval "(.subtasks[] | select(.id == \"$input\")).status = \"done\"" -i "$active_file"
                                    echo "✅ Committed and marked subtask $input as done"
                                else
                                    echo "❌ Git commit failed"
                                    exit 1
                                fi
                            else
                                echo "ℹ️  Skipped commit"
                            fi
                        fi
                        
                    else
                        echo "❌ ID $input not found in milestones or subtasks"
                        exit 1
                    fi
                    
                else
                    # This is a message - use smart commit functionality
                    smart_commit "$input" "$auto_mode"
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