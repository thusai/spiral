# Spiral Go Implementation Plan

## Phase 1: Core Foundation (Week 1-2)
**Goal**: Establish Go foundation with essential commands

### Directory Structure
```
spiral/
├── cmd/                    # CLI commands 
│   ├── root.go            # Main spiral command
│   ├── show.go            # show commands
│   ├── add.go             # add commands
│   ├── context.go         # context management
│   └── commit.go          # commit integration
├── internal/
│   ├── core/              # Core business logic
│   │   ├── reader.go      # YAML reading & parsing
│   │   ├── writer.go      # YAML writing & validation
│   │   ├── context.go     # Context management
│   │   └── git.go         # Git integration
│   ├── types/             # Data models
│   │   └── models.go      # Milestone, Task structs
│   ├── config/            # Configuration management
│   │   └── config.go      # Project config, schema loading
│   └── display/           # Output formatting
│       └── formatter.go   # Colored output, tables
├── go.mod
├── go.sum
├── main.go
└── README.md
```

### Essential Commands for Phase 1
```bash
spiral show milestones         # Basic milestone listing
spiral show all                # Hierarchical view
spiral add milestone <fields>  # Add new milestone
spiral context [id]            # Show/set context
spiral commit <message> --auto # Smart commit (core feature)
```

### Key Implementation Details

#### 1. Data Models (`internal/types/models.go`)
```go
type Milestone struct {
    ID            string `yaml:"id" json:"id"`
    Title         string `yaml:"title" json:"title"`
    Week          string `yaml:"week,omitempty" json:"week,omitempty"`
    Version       string `yaml:"version,omitempty" json:"version,omitempty"`
    ReleaseStatus string `yaml:"release_status" json:"release_status"`
    CycleStatus   string `yaml:"cycle_status,omitempty" json:"cycle_status,omitempty"`
    SuccessGate   string `yaml:"success_gate,omitempty" json:"success_gate,omitempty"`
    Notes         string `yaml:"notes,omitempty" json:"notes,omitempty"`
}

type Task struct {
    ID       string `yaml:"id" json:"id"`
    ParentID string `yaml:"parent_id" json:"parent_id"`
    Title    string `yaml:"title" json:"title"`
    Status   string `yaml:"status" json:"status"`
    Notes    string `yaml:"notes,omitempty" json:"notes,omitempty"`
}

type Roadmap struct {
    Milestones []Milestone `yaml:"milestones" json:"milestones"`
    Tasks      []Task      `yaml:"tasks" json:"tasks"`
}
```

#### 2. Configuration Management (`internal/config/config.go`)
```go
type Config struct {
    ActiveFile    string `json:"active_file"`
    SchemaPath    string `json:"schema_path"`
    CurrentProject string `json:"current_project,omitempty"`
}

type ProjectConfig struct {
    Name       string
    YAMLPath   string
    SchemaPath string
}

// Load config from ~/.config/spiral/
func LoadConfig() (*Config, error)
func SaveConfig(cfg *Config) error
func FindProjects() ([]ProjectConfig, error)
```

#### 3. Core Reader/Writer (`internal/core/`)
```go
// reader.go
func LoadRoadmap(yamlPath string) (*types.Roadmap, error)
func ValidateAgainstSchema(roadmap *types.Roadmap, schemaPath string) error

// writer.go  
func SaveRoadmap(roadmap *types.Roadmap, yamlPath string) error
func AddMilestone(roadmap *types.Roadmap, milestone types.Milestone) error
func AddTask(roadmap *types.Roadmap, task types.Task) error

// git.go
func SmartCommit(message string, autoMode bool) error
func CheckIDInGitHistory(id string) (bool, error)
func GetGitContext() (string, error)
```

#### 4. Essential CLI Commands (`cmd/`)
Focus on the most critical user workflows:
- `spiral show all` - Get roadmap overview
- `spiral commit "message" --auto` - The core workflow
- `spiral context S4.1` - Set working context
- `spiral add milestone` - Create milestones

### Backward Compatibility Strategy
1. **Config migration**: Auto-detect existing `~/.config/spiral/` and migrate
2. **YAML compatibility**: Support existing YAML structure exactly
3. **Parallel execution**: Keep bash script available as `spiral-legacy`
4. **Migration command**: `spiral migrate` to convert projects

## Phase 2: Smart Commit & Context (Week 3)
**Goal**: Implement the killer feature - smart commit workflow

### Priority Features
1. **Context management**: Project-scoped working context
2. **Auto-milestone creation**: Parse commit messages intelligently  
3. **Subtask generation**: Auto-create subtasks under current context
4. **Git integration**: Validate against git history, prevent duplicate commits

### Smart Commit Algorithm
```go
func SmartCommit(message string, autoMode bool) error {
    // 1. Detect if message looks like milestone ID
    if isValidMilestoneID(message) {
        return commitExistingMilestone(message, autoMode)
    }
    
    // 2. Check for current working context
    context := getCurrentContext()
    if context != "" {
        return createSubtaskCommit(context, message, autoMode)
    }
    
    // 3. Auto-create milestone from message
    if autoMode {
        return createMilestoneFromMessage(message)
    }
    
    // 4. Interactive mode
    return interactiveCommitFlow(message)
}
```

### Key Enhancements Over Bash
- **Better parsing**: Use regex/NLP to extract milestone titles from messages
- **Atomic operations**: Ensure YAML + git operations are consistent
- **Error recovery**: Better error messages and rollback capabilities

## Phase 3: Multi-Project & Advanced Features (Week 4)
**Goal**: Support enterprise workflows and advanced features

### Multi-Project Support
```go
type ProjectManager struct {
    projects    map[string]*ProjectConfig
    activeProject string
}

func (pm *ProjectManager) SwitchProject(name string) error
func (pm *ProjectManager) CreateProject(name, yamlPath, schemaPath string) error
func (pm *ProjectManager) ListProjects() []ProjectConfig
```

### Advanced Features
1. **Cycle management**: `spiral cycle pick S4.1 S4.2`
2. **Filtering & views**: Advanced filtering options
3. **Schema validation**: Robust validation with helpful errors
4. **Hierarchical display**: Improved formatting and colors

## Phase 4: Polish & Migration (Week 5)
**Goal**: Production-ready release with migration tools

### Migration Tools
```bash
spiral migrate                  # Auto-migrate from bash version
spiral migrate --check          # Validate migration readiness  
spiral migrate --backup         # Create backup before migration
```

### Production Features
1. **Comprehensive testing**: Unit tests for all core functions
2. **Documentation**: Updated README and examples
3. **Cross-platform builds**: CI/CD for multiple platforms
4. **Performance optimization**: Benchmarking and optimization

### User Migration Path
1. **Parallel installation**: Both versions available during transition
2. **Migration validation**: Ensure all data transfers correctly
3. **Feature parity**: All bash features available in Go version
4. **Gradual rollout**: Opt-in migration for existing users

## Technical Decisions

### Dependencies
```go
// Minimal dependencies for reliability
github.com/urfave/cli/v2        // CLI framework
gopkg.in/yaml.v3                // YAML parsing
github.com/fatih/color          // Colored output
github.com/go-git/go-git/v5     // Git operations
```

### Architecture Principles
1. **Single binary**: Zero runtime dependencies
2. **Atomic operations**: File operations use temp files + rename
3. **Backward compatibility**: Existing YAML files work unchanged
4. **Error handling**: Comprehensive error messages and recovery
5. **Testing**: High test coverage for reliability

### File Structure Strategy
- **Preserve existing**: All current YAML files work unchanged
- **Configuration**: JSON config files for better parsing
- **Schema**: Continue using YAML schemas for validation
- **Context**: JSON files for better structured context data

## Success Metrics

### Phase 1 Success
- [ ] All essential commands implemented
- [ ] Existing YAML files load correctly
- [ ] Basic smart commit works
- [ ] Context management functional

### Phase 2 Success  
- [ ] Smart commit feature parity with bash
- [ ] Auto-milestone creation works
- [ ] Git integration robust
- [ ] Context switching smooth

### Phase 3 Success
- [ ] Multi-project support complete
- [ ] All advanced features ported
- [ ] Performance better than bash
- [ ] Feature parity achieved

### Phase 4 Success
- [ ] Migration tools work flawlessly
- [ ] All users can migrate safely
- [ ] Documentation complete
- [ ] Go version becomes default

## Risk Mitigation

### Major Risks
1. **Feature regression**: Missing functionality in Go version
2. **Migration issues**: Data loss during migration
3. **Performance problems**: Go version slower than expected
4. **User adoption**: Resistance to changing from working bash

### Mitigation Strategies
1. **Parallel development**: Keep bash version available
2. **Extensive testing**: Automated testing of all features
3. **Gradual rollout**: Opt-in migration process
4. **Backup strategies**: Automatic backups during migration

## Timeline Summary

| Phase | Duration | Key Deliverables |
|-------|----------|------------------|
| 1 | 2 weeks | Core Go foundation, essential commands |
| 2 | 1 week | Smart commit workflow, context management |
| 3 | 1 week | Multi-project support, advanced features |  
| 4 | 1 week | Migration tools, production release |

**Total: 5 weeks to production-ready Go version**

This plan maintains the powerful features that make spiral unique while building a more maintainable and extensible foundation for future growth. 