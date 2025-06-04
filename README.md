# Spiral - Project Roadmap Management Tool

Spiral is a command-line tool for managing project roadmaps using YAML files. It provides both interactive TUI and command-line interfaces for adding, modifying, and tracking milestones across different projects.

## Features

- ✅ **Multi-project support** - Manage roadmaps for different projects
- ✅ **Work from anywhere** - Use spiral from any directory once installed
- ✅ **Interactive TUI** - User-friendly terminal interface
- ✅ **Schema validation** - Enforce field requirements and enum values
- ✅ **Flexible milestone tracking** - Track status, cycles, versions, and more
- ✅ **Git integration** - Generate standardized commit messages

## Installation

### Quick Install
```bash
# Clone or download the spiral repository
git clone <repository-url> spiral
cd spiral

# Make spiral available from anywhere
chmod +x install.sh
./install.sh
```

### Manual Install
```bash
# Make spiral.sh executable
chmod +x spiral.sh

# Create a symlink in a directory that's in your PATH
ln -sf "$(pwd)/spiral.sh" /usr/local/bin/spiral
# Or for user-only install:
ln -sf "$(pwd)/spiral.sh" "$HOME/.local/bin/spiral"
```

## Quick Start

1. **Set up your first project:**
   ```bash
   # Navigate to your project directory
   cd /path/to/your/project
   
   # Create your roadmap file
   spiral use roadmap.yml
   ```

2. **Create a schema file** (if you don't have one):
   Spiral will look for `schema.yml` in these locations:
   - Same directory as your roadmap YAML file
   - `config/schema.yml` relative to your roadmap file
   - `../config/schema.yml` relative to your roadmap file
   - `./config/schema.yml` in your current directory

3. **Start using spiral:**
   ```bash
   # Launch interactive TUI
   spiral tui
   
   # Or use command line
   spiral add milestones id=M1.0 title="Initial Release" release_status=planned
   ```

## Project Structure

For each project, you'll need:

1. **Roadmap YAML file** (e.g., `roadmap.yml`, `v1.yml`)
2. **Schema file** (`schema.yml`) that defines the structure

### Example Schema (`schema.yml`)
```yaml
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
```

### Example Roadmap YAML
```yaml
# Project Roadmap v1.0
meta:
  version: "1.0"
  owner: "@your-team"
  last_updated: "2024-01-15"

milestones:
  - id: M1.0
    title: "Initial Release"
    week: W1
    version: 1.0.0
    release_status: planned
    cycle_status: in-cycle
    success_gate: "MVP features complete"
    notes: "Core functionality only"
```

## Usage

### Setting Up Projects

```bash
# Set active roadmap (works from any directory)
spiral use /path/to/project/roadmap.yml

# Check current project
spiral current

# View all configured projects
spiral projects
```

### Managing Milestones

```bash
# Interactive TUI (recommended)
spiral tui

# Command line interface
spiral add milestones id=M1.1 title="Feature X" release_status=planned
spiral modify milestones M1.1 release_status=in-progress
spiral show milestones id title release_status
```

### Project Commands

```bash
# List sections in active roadmap
spiral list

# Show schema for a section
spiral schema milestones

# View specific milestone fields
spiral show milestones id title week

# Commit milestone and update status
spiral commit M1.1 --apply
```

## Multi-Project Workflow

1. **Set up multiple projects:**
   ```bash
   # Project A
   cd /path/to/project-a
   spiral use roadmap-v1.yml
   
   # Project B  
   cd /path/to/project-b
   spiral use roadmap-v2.yml
   ```

2. **Switch between projects:**
   ```bash
   # From anywhere, switch to project A
   spiral use /path/to/project-a/roadmap-v1.yml
   
   # Now work with project A
   spiral tui
   
   # Switch to project B
   spiral use /path/to/project-b/roadmap-v2.yml
   ```

3. **Check which project is active:**
   ```bash
   spiral current
   # Shows: Current active file: /path/to/project-a/roadmap-v1.yml
   #        Using schema: /path/to/project-a/schema.yml
   ```

## Schema Locations

Spiral automatically finds your schema file by looking in these locations (in order):

1. Same directory as your roadmap YAML file
2. `config/schema.yml` relative to your roadmap file  
3. `../config/schema.yml` relative to your roadmap file
4. `./config/schema.yml` in your current working directory

This allows for flexible project structures:

```
# Option 1: Schema next to roadmap
project/
├── roadmap.yml
└── schema.yml

# Option 2: Schema in config directory
project/
├── roadmaps/
│   └── v1.yml
└── config/
    └── schema.yml

# Option 3: Shared schema for multiple roadmaps
project/
├── roadmaps/
│   ├── v1.yml
│   └── v2.yml
├── config/
│   └── schema.yml
```

## Commands Reference

| Command | Description |
|---------|-------------|
| `spiral` | List YAML files in current directory |
| `spiral use <file>` | Set active roadmap file |
| `spiral current` | Show active file and schema |
| `spiral projects` | Show project configuration |
| `spiral tui` | Launch interactive interface |
| `spiral add <section> <key=value>...` | Add new entry |
| `spiral modify <section> <id> <field=value>` | Modify entry |
| `spiral show <section> [fields]` | Display entries |
| `spiral commit <id> [--apply]` | Generate/apply commit message |

## Troubleshooting

### Schema Not Found
```bash
❌ Schema file not found at ./config/schema.yml
```
**Solution:** Make sure you have a `schema.yml` file in one of the expected locations, or create one using the example above.

### No Active File
```bash
Error: No active file set. Use 'spiral use <yaml-file>' first.
```
**Solution:** Set an active roadmap file:
```bash
spiral use path/to/your/roadmap.yml
```

### Permission Issues
If installation fails with permission errors:
```bash
sudo ./install.sh
# Or manually install to user directory:
ln -sf "$(pwd)/spiral.sh" "$HOME/.local/bin/spiral"
```

## Development

Spiral is written in Bash and uses `yq` for YAML processing. To contribute:

1. Fork the repository
2. Make your changes
3. Test with different project structures
4. Submit a pull request

## License

[Add your license here]
