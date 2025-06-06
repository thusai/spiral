# Spiral 🌀 - AI-Native Roadmaps

**Finally.** A roadmap tool that adapts to how you actually develop, not the other way around.

- 🚀 **Organic workflow**: Commit first, roadmap follows automatically
- 🎯 **Smart context**: Auto-creates milestones from your commit messages  
- 🔗 **Git-native**: Uses actual commit history as source of truth
- ⚡ **Zero friction**: One command commits and tracks everything
- 🏗️ **Hierarchical structure**: Family.Milestone.Task.Subtask organization

## Quick Install (macOS)

```bash
# For Apple Silicon (M1/M2/M3)
curl -L https://github.com/thusai/spiral/releases/latest/download/spiral-darwin-arm64 -o spiral

# For Intel Macs
curl -L https://github.com/thusai/spiral/releases/latest/download/spiral-darwin-amd64 -o spiral

# Make executable and install
chmod +x spiral
sudo mv spiral /usr/local/bin/
```

Works from anywhere. Forever. It's yours.

## The Magic ✨

**Start developing immediately** - no setup required:
```bash
spiral add milestone --title="Fix login bug" --family=D --priority=high
# ✅ Added milestone D1: Fix login bug
# 🎯 Auto-generating ID: D1
```

**Keep developing** - add tasks to your milestone:
```bash
spiral add task --parent=D1 --title="Add password strength meter"  
# ✅ Added task D1.1: Add password strength meter
# 🔍 Organized under: D1 (Fix login bug)
```

**See your roadmap** - hierarchical and beautiful:
```bash
spiral show all
# 📋 D3      in-progress   🔒 Authentication System
#    ├─ D3.1     done     ✅ Core Login Flow  
#    │  ├─ D3.1.1  done   ✅ OAuth integration
#    │  └─ D3.1.2  done   ✅ Session management
#    └─ D3.2  in-progress 🔄 Password Reset
#       └─ D3.2.1  todo   📝 Email templates
```

**Smart context switching**:
```bash
spiral context D1            # Focus on login milestone
spiral add subtask --parent=D1.1 --title="Email validation"  # Creates D1.1.1
spiral context               # See current focus
```

## Core Commands

| What You Want | Command |
|---------------|---------|
| Add milestone | `spiral add milestone --title="Fix auth bug" --family=D` |
| Add task | `spiral add task --parent=D1 --title="Add validation"` |
| See roadmap | `spiral show all` |
| Set focus | `spiral context D1` |
| Filter view | `spiral show --family D --status in-progress` |

## Why Spiral?

### Traditional Tools 😞
- Heavy project management overhead
- Rigid structures that don't match development reality  
- Roadmaps become outdated the moment you create them
- Context switching between code and planning tools

### Spiral 😊  
- Lightweight CLI that lives in your terminal
- Hierarchical structure that grows with your project
- Family.Milestone.Task.Subtask organization (D3.1.2.1)
- Single source of truth that stays current

---

**Want the full garage tour?** This is just the surface. Spiral handles priority filtering, cycle planning, family organization, smart ID generation, and scales from solo projects to enterprise roadmaps.

But you probably just want to start building. So do that. 🚀

## Advanced Features (The Garage Tour)

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

### 🎨 Smart Filtering

Find exactly what you need:
```bash
spiral show --family D --priority critical    # Critical items in family D
spiral show --status in-progress              # Active work
spiral show --cycle in-cycle                  # Current cycle items
```

### Family Organization
Organize work across teams or product areas:
- `D` - Development/Backend
- `E` - Engineering/Frontend  
- `F` - Features/Product
- `O` - Operations/DevOps
- `S` - Security/Infrastructure

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

## Configuration

Spiral creates `spiral.yml` automatically when you first use it. For advanced customization:

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
```

## Development

### Building
```bash
go build -o spiral main.go
```

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Roadmap

- [X] Git commit integration with automatic tagging
- [ ] Multi-project management
- [ ] Context-creation and Chunking 
- [ ] IDE integrations

---

**Ready to spiral? 🌀** 

Start with `spiral show all` and watch your roadmap come alive.
