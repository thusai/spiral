# Spiral - Roadmaps That Follow Your Code

**Finally.** A roadmap tool that adapts to how you actually develop, not the other way around.

- 🚀 **Organic workflow**: Commit first, roadmap follows automatically
- 🎯 **Smart context**: Auto-creates milestones from your commit messages  
- 🔗 **Git-native**: Uses actual commit history as source of truth
- ⚡ **Zero friction**: One command commits and tracks everything

## Quick Install

```bash
git clone <this-repo> && cd spiral
chmod +x install.sh && ./install.sh
```

Works from anywhere. Forever. It's Yours.

## The Magic ✨

**Start developing immediately** - no setup required:
```bash
spiral commit "Fix login bug - Add better validation" --auto
# 🎯 Auto-creating milestone: S4.1 - Fix login bug  
# ✅ Created commit: [S4.1.1] Fix login bug - Add better validation
# ✅ Set working context to: S4.1
```

**Keep developing** - context is maintained:
```bash
spiral commit "Add password strength meter" --auto  
# 🔍 Auto-detected context: S4.1 (Fix login bug)
# ✅ Created commit: [S4.1.2] Add password strength meter
```

**See your roadmap** - hierarchical and beautiful:
```bash
spiral show all
# 📋 S4.1    in-progress   Fix login bug
#    └─ S4.1.1   done      Fix login bug - Add better validation  
#    └─ S4.1.2   done      Add password strength meter
```

**Complete milestones** - git validates everything:
```bash
spiral commit S4.1 --auto
# ✅ Committed and marked milestone S4.1 as done

spiral commit S4.1 --auto  
# ❌ Milestone S4.1 has already been committed to git. Cannot commit again.
```

## Core Commands

| What You Want | Command |
|---------------|---------|
| Start working | `spiral commit "message" --auto` |
| Set context | `spiral context S4.1` |
| See roadmap | `spiral show all` |
| Track subtasks | `spiral subtasks S4.1` |
| Interactive mode | `spiral tui` |

## Multiple Projects? Easy.

```bash
spiral init myproject              # auto-detects YAML + schema files
spiral use myproject              # switch between projects  
spiral projects                   # see all configured projects
```

---

**Want the full garage tour?** This is just the surface. Spiral handles schema validation, cycle planning, milestone dependencies, custom fields, and scales from solo projects to enterprise roadmaps.

But you probably just want to start committing. So do that. 🚀

---

**For AI Agents**: 
- **Cursor**: Use [`spiral_agent.mdc`](spiral_agent.mdc) - Add to cursor rules for automatic agent assistance
- **Other LLMs**: See [`spiral_agent.yml`](spiral_agent.yml) for comprehensive usage patterns and decision trees
