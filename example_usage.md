# Spiral v2.0 - Phase 1 Usage Examples

## Build and Test

```bash
# Build the Go binary
go build -o spiral

# Make executable
chmod +x spiral

# Test basic functionality
./spiral --help
```

## Basic Workflow

### 1. Create Your First Milestone
```bash
# Create a milestone with all fields
./spiral add milestone \
  --id=3.4 \
  --title="Micro-Cache Layer" \
  --family=D \
  --priority=critical \
  --cycle-status=in-cycle

# ✅ Added milestone 3.4: Micro-Cache Layer
# 🎯 Set 3.4 as current working context
```

### 2. View Your Roadmap
```bash
# Show hierarchical view
./spiral show all

# 🎯 Spiral Roadmap - Hierarchical View
# =====================================
# 🎯 Current Context: 3.4 - Micro-Cache Layer
# 
# 🔄 3.4 [D] Micro-Cache Layer critical in-cycle
# 
# 📊 Summary: 1 milestones, 0 tasks total
```

### 3. Add Tasks to Your Milestone
```bash
# Add tasks (IDs auto-generated)
./spiral add task --parent=3.4 --title="Add cursor rule" --status=in-progress
./spiral add task --parent=3.4 --title="Fix validation bug" --status=planned

# ✅ Added task 3.4.1: Add cursor rule
#    Parent: 3.4
# ✅ Added task 3.4.2: Fix validation bug
#    Parent: 3.4
```

### 4. Add Subtasks
```bash
# Add subtasks to tasks
./spiral add subtask --parent=3.4.1 --title="Research cursor API" --status=done
./spiral add subtask --parent=3.4.1 --title="Write implementation" --status=in-progress

# ✅ Added subtask 3.4.1.1: Research cursor API
#    Parent: 3.4.1
# ✅ Added subtask 3.4.1.2: Write implementation  
#    Parent: 3.4.1
```

### 5. View Your Work
```bash
# Show everything
./spiral show all

# Show just in-cycle items
./spiral show cycle

# Show tasks for a specific milestone
./spiral show tasks --milestone-id=3.4

# View current context
./spiral context
```

### 6. Filter and Search
```bash
# Show milestones by family
./spiral show milestones --family=D

# Show only critical priority
./spiral show milestones --priority=critical

# Show in-cycle milestones
./spiral show milestones --in-cycle

# Show tasks by status
./spiral show tasks --status=in-progress
```

### 7. Context Management
```bash
# Set working context to a milestone
./spiral context --id=3.4

# View current context details
./spiral context

# Clear context
./spiral context --clear
```

## Expected Output Examples

### `spiral show all` - Full Hierarchy
```
🎯 Spiral Roadmap - Hierarchical View
=====================================
🎯 Current Context: 3.4 - Micro-Cache Layer

🔄 3.4 [D] Micro-Cache Layer critical in-cycle
   └─ 🔄 3.4.1 - Add cursor rule [in-progress]
   └─ 📝 3.4.2 - Fix validation bug [planned]

📊 Summary: 1 milestones, 2 tasks total
```

### `spiral show cycle` - Current Cycle
```
🔄 Current Cycle Status:
=======================

📋 3.4 - Micro-Cache Layer [in-cycle]
   └─ 3.4.1 - Add cursor rule [in-progress]
   └─ 3.4.2 - Fix validation bug [planned]

📊 Summary: 1 milestones, 2 tasks in cycle
```

### `spiral context` - Working Context
```
🎯 Current Working Context:
===========================
Milestone: 3.4 - Micro-Cache Layer
Cycle Status: in-cycle
Family: D
Priority: critical
Last Updated: 2024-01-15 14:30:25

📝 Active tasks:
   🔄 3.4.1 - Add cursor rule [in-progress]
   📝 3.4.2 - Fix validation bug [planned]

⚡ Quick actions:
   spiral add task --parent=3.4 --title='New Task'
   spiral commit 'Work description' --auto
   spiral show cycle
```

## File Structure Created

After running these commands, you'll have:

```
.spiral/
├── context.json    # Current working context
└── config.json     # Configuration

spiral.yml          # Main roadmap file
```

### `spiral.yml` content:
```yaml
milestones:
  - id: "3.4"
    title: "Micro-Cache Layer"
    family: "D"
    priority: "critical"
    cycle_status: "in-cycle"

tasks:
  - id: "3.4.1"
    parent_id: "3.4"
    title: "Add cursor rule"
    status: "in-progress"
  - id: "3.4.2"
    parent_id: "3.4"
    title: "Fix validation bug"
    status: "planned"
  - id: "3.4.1.1"
    parent_id: "3.4.1"
    title: "Research cursor API"
    status: "done"
  - id: "3.4.1.2"
    parent_id: "3.4.1"
    title: "Write implementation"
    status: "in-progress"
```

## Phase 1 Success Criteria ✓

- [x] Essential commands implemented (show, add, context)
- [x] YAML roadmap loading and saving
- [x] Hierarchical display with colors and icons
- [x] Context management working
- [x] Atomic file operations
- [x] Auto-ID generation for tasks
- [x] Filtering and search functionality
- [x] Clean, user-friendly CLI interface

## Coming in Phase 2

- Smart commit with git integration
- Auto-milestone creation from commit messages
- Context-aware task creation
- Git history validation

The foundation is solid and ready for the killer smart commit feature! 