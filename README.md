# Spiral - Linear CLI but for Agent-Native Dev

Manage project milestones and roadmaps from the command line. Works from any directory, supports multiple projects. 

## Quick Install

```bash
git clone <this-repo> && cd spiral
chmod +x install.sh && ./install.sh
```

That's it. Now `spiral` works from anywhere.

## Start Using It

Create your first project (auto-detects files):
```bash
spiral init myproject                    # finds YAML + schema automatically
spiral add milestones id=M1.0 title="Launch MVP" release_status=planned
spiral show milestones id title release_status
```

If multiple YAML files exist, you choose interactively:
```bash
spiral init myproject
# 🔍 Multiple YAML files found:
# 1. roadmap.yml
# 2. project.yml
# Choose YAML file (1-2): 1
```

Launch the interactive interface:
```bash
spiral tui
```

Switch between projects:
```bash
spiral use myproject    # by name
spiral projects         # see all projects
```

## Commands Reference

| Command | Description |
|---------|-------------|
| `spiral` | List YAML files in current directory |
| `spiral init <project> [yaml] [schema]` | Create project (auto-detects files) |
| `spiral use <project\|file>` | Set active roadmap by name or file |
| `spiral current` | Show active file and schema |
| `spiral projects` | Show project configuration |
| `spiral tui` | Launch interactive interface |
| `spiral add milestones` | Add new entry |
| `spiral modify milestones` | Modify entry |
| `spiral show milestones id title` | Display entries |
| `spiral commit <id> [--apply]` | Generate/apply commit message |

## More Details

- **Auto-detection:** `spiral init myproject` finds YAML/schema files automatically
- **Multiple files:** Interactive selection when multiple YAML files exist  
- **Schema format:** Edit the generated `config/schema.yml` after `spiral init`
- **Troubleshooting:** `spiral current` shows your active project and files
