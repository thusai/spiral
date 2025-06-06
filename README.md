# Spiral 🌀 - Roadmaps That Follow Your Code

**Finally.** A roadmap tool that adapts to how you actually develop, not the other way around.

- 🚀 **Organic workflow**: Commit first, roadmap follows automatically
- 🎯 **Smart context**: Auto-creates milestones from your commit messages  
- 🔗 **Git-native**: Uses actual commit history as source of truth
- ⚡ **Zero friction**: One command commits and tracks everything
- 🏗️ **Hierarchical structure**: Family.Milestone.Task.Subtask organization

## Quick Start

### Installation

**Option 1: Download Binary (Recommended)**
```bash
# Download latest release for your platform
# macOS/Linux
curl -L https://github.com/username/spiral/releases/latest/download/spiral-$(uname -s)-$(uname -m) -o spiral
chmod +x spiral
sudo mv spiral /usr/local/bin/

# Windows
# Download spiral.exe from releases page
```

**Option 2: Build from Source**
```bash
git clone https://github.com/username/spiral.git
cd spiral
go build -o spiral main.go
sudo mv spiral /usr/local/bin/  # or add to PATH
```

### Initialize Your First Project

```bash
# Create example configuration
cp example.yml spiral.yml

# Start using spiral immediately
spiral show all
```

## Core Features

### 🎯 Hierarchical ID System

Spiral uses a powerful Family.Milestone.Task.Subtask structure:
```
D3.1.2.1  →  Family D, Milestone 3, Task 1, Subtask 2, Sub-subtask 1
```

### 🔄 Smart Context Management

Stay focused on what matters:
```bash
spiral context D3.1          # Set working context
spiral add "Fix bug in auth" # Auto-creates D3.1.3
spiral context               # See current context
```

### 📊 Beautiful Display

Get instant visual feedback:
```bash
spiral show all
# 📋 D3      in-progress   🔒 Authentication System
#    ├─ D3.1     done     ✅ Core Login Flow  
#    │  ├─ D3.1.1  done   ✅ OAuth integration
#    │  └─ D3.1.2  done   ✅ Session management
#    └─ D3.2  in-progress 🔄 Password Reset
#       └─ D3.2.1  todo   📝 Email templates
```

### 🎨 Smart Filtering

Find exactly what you need:
```bash
spiral show --family D --priority critical    # Critical items in family D
spiral show --status in-progress              # Active work
spiral show --cycle in-cycle                  # Current cycle items
```

## Command Reference

| Command | Description | Example |
|---------|-------------|---------|
| `spiral show [all\|cycle]` | Display roadmap | `spiral show all` |
| `spiral add <title>` | Add new task/milestone | `spiral add "Fix login bug"` |
| `spiral context [id]` | Set/show working context | `spiral context D3.1` |
| `spiral edit <id>` | Modify existing item | `spiral edit D3.1.2` |
| `spiral complete <id>` | Mark as done | `spiral complete D3.1` |

## Configuration

Spiral uses a simple YAML structure. Copy `example.yml` to `spiral.yml` to get started:

```yaml
milestones:
  - id: D1
    family: D
    title: Setup Project Foundation
    priority: critical
    status: done

tasks:
  - id: D1.1
    parent_id: D1
    title: Initialize project structure
    status: done

subtasks:
  - id: D1.1.1
    parent_id: D1.1
    title: Setup directory structure
    status: done
```

### Priority Levels
- `critical` 🔴 - Must be done now
- `high` 🟠 - Important for next release  
- `medium` 🟡 - Nice to have
- `low` 🟢 - Future consideration

### Status Options
- `planned` 📝 - Not started
- `in-progress` 🔄 - Active work
- `done` ✅ - Completed
- `blocked` ⛔ - Cannot proceed

## Advanced Features

### Family Organization
Organize work across teams or product areas:
- `D` - Development/Backend
- `E` - Engineering/Frontend  
- `F` - Features/Product
- `O` - Operations/DevOps
- `S` - Security/Infrastructure

### Cycle Management
Track work in development cycles:
```bash
spiral show cycle           # Show current cycle work
spiral cycle start D3       # Start new cycle with milestone D3
spiral cycle complete       # Complete current cycle
```

### Git Integration (Coming Soon)
Spiral will integrate with git for automatic commit tagging:
```bash
git commit -m "[D3.1.2] Fix authentication timeout"
# Automatically updates spiral.yml
```

## Why Spiral?

### Traditional Tools 😞
- Heavy project management overhead
- Rigid structures that don't match development reality
- Roadmaps become outdated the moment you create them
- Context switching between code and planning tools

### Spiral 😊  
- Lightweight CLI that lives in your terminal
- Hierarchical structure that grows with your project
- Real-time updates as you work
- Single source of truth that stays current

## Development

### Building
```bash
go build -o spiral main.go
```

### Testing
```bash
go test ./...
```

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Roadmap

- [ ] Git commit integration with automatic tagging
- [ ] Interactive TUI mode
- [ ] Multi-project management
- [ ] Team collaboration features
- [ ] Advanced reporting and analytics
- [ ] IDE integrations

---

**Ready to spiral? 🌀** 

Start with `spiral show all` and watch your roadmap come alive.
