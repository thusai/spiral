package types

import (
	"fmt"
	"strconv"
	"strings"
)

// Enhanced ID structure for family-prefixed hierarchical IDs
type ID struct {
	Family    string // D, E, F (product families)
	Milestone int    // 3, 4, 5 (major features)
	Task      *int   // 1, 2, 3 (nil for milestone-only IDs)
	Subtask   *int   // 1, 2, 3 (nil for task-only IDs)
}

// String returns the ID in family-prefixed format (D3, D3.1, D3.1.1)
func (id ID) String() string {
	if id.Subtask != nil {
		return fmt.Sprintf("%s%d.%d.%d", id.Family, id.Milestone, *id.Task, *id.Subtask)
	}
	if id.Task != nil {
		return fmt.Sprintf("%s%d.%d", id.Family, id.Milestone, *id.Task)
	}
	return fmt.Sprintf("%s%d", id.Family, id.Milestone)
}

// CommitTag returns the ID formatted for git commit tags
func (id ID) CommitTag() string {
	return fmt.Sprintf("[%s]", id.String())
}

// ParentID returns the parent ID (D3.1.1 → D3.1, D3.1 → D3, D3 → "")
func (id ID) ParentID() string {
	if id.Subtask != nil {
		return fmt.Sprintf("%s%d.%d", id.Family, id.Milestone, *id.Task)
	}
	if id.Task != nil {
		return fmt.Sprintf("%s%d", id.Family, id.Milestone)
	}
	return "" // Milestone has no parent
}

// Level returns the hierarchy level (0=milestone, 1=task, 2=subtask)
func (id ID) Level() int {
	if id.Subtask != nil {
		return 2
	}
	if id.Task != nil {
		return 1
	}
	return 0
}

// ParseID parses a string into an ID structure
func ParseID(idStr string) (*ID, error) {
	if idStr == "" {
		return nil, fmt.Errorf("empty ID")
	}

	// Extract family (first character must be alphabetic)
	if len(idStr) < 2 {
		return nil, fmt.Errorf("invalid ID format: %s", idStr)
	}

	family := string(idStr[0])
	if !isAlpha(family) {
		return nil, fmt.Errorf("family must be alphabetic: %s", family)
	}

	// Parse numeric parts
	parts := strings.Split(idStr[1:], ".")
	if len(parts) == 0 || len(parts) > 3 {
		return nil, fmt.Errorf("invalid ID format: %s", idStr)
	}

	id := &ID{Family: family}

	// Parse milestone
	milestone, err := strconv.Atoi(parts[0])
	if err != nil {
		return nil, fmt.Errorf("invalid milestone number: %s", parts[0])
	}
	id.Milestone = milestone

	// Parse task if present
	if len(parts) > 1 {
		task, err := strconv.Atoi(parts[1])
		if err != nil {
			return nil, fmt.Errorf("invalid task number: %s", parts[1])
		}
		id.Task = &task
	}

	// Parse subtask if present
	if len(parts) > 2 {
		subtask, err := strconv.Atoi(parts[2])
		if err != nil {
			return nil, fmt.Errorf("invalid subtask number: %s", parts[2])
		}
		id.Subtask = &subtask
	}

	return id, nil
}

// isAlpha checks if string contains only alphabetic characters
func isAlpha(s string) bool {
	for _, r := range s {
		if !((r >= 'A' && r <= 'Z') || (r >= 'a' && r <= 'z')) {
			return false
		}
	}
	return true
}

// Milestone represents a high-level feature or goal
type Milestone struct {
	ID           string            `yaml:"id"`
	Family       string            `yaml:"family"`
	Title        string            `yaml:"title"`
	Priority     string            `yaml:"priority,omitempty"`
	CycleStatus  string            `yaml:"cycle_status,omitempty"`
	Status       string            `yaml:"status,omitempty"`
	Notes        string            `yaml:"notes,omitempty"`
	Metadata     map[string]string `yaml:"metadata,omitempty"`
}

// Task represents a specific work item under a milestone
type Task struct {
	ID       string            `yaml:"id"`
	ParentID string            `yaml:"parent_id"`
	Title    string            `yaml:"title"`
	Status   string            `yaml:"status"`
	Priority string            `yaml:"priority,omitempty"`
	Notes    string            `yaml:"notes,omitempty"`
	Metadata map[string]string `yaml:"metadata,omitempty"`
}

// Roadmap represents the entire roadmap structure
type Roadmap struct {
	Milestones []Milestone `yaml:"milestones"`
	Tasks      []Task      `yaml:"tasks"`
}

// Context represents the current working context
type Context struct {
	MilestoneID string `json:"milestone_id,omitempty"`
	TaskID      string `json:"task_id,omitempty"`
	Family      string `json:"family,omitempty"`
}

// Config represents the user configuration
type Config struct {
	Context Context `json:"context"`
}

// Valid values for enum fields
var (
	ValidPriorities = []string{"low", "medium", "high", "critical"}
	ValidSizes      = []string{"xs", "s", "m", "l", "xl"}
	ValidCycleStatuses = []string{"planned", "in-cycle", "done"}
	ValidTaskStatuses  = []string{"planned", "in-progress", "done", "blocked"}
)

// IsValidPriority checks if a priority value is valid
func IsValidPriority(priority string) bool {
	for _, valid := range ValidPriorities {
		if priority == valid {
			return true
		}
	}
	return false
}

// IsValidSize checks if a size value is valid
func IsValidSize(size string) bool {
	for _, valid := range ValidSizes {
		if size == valid {
			return true
		}
	}
	return false
}

// IsValidCycleStatus checks if a cycle status is valid
func IsValidCycleStatus(status string) bool {
	for _, valid := range ValidCycleStatuses {
		if status == valid {
			return true
		}
	}
	return false
}

// IsValidTaskStatus checks if a task status is valid
func IsValidTaskStatus(status string) bool {
	for _, valid := range ValidTaskStatuses {
		if status == valid {
			return true
		}
	}
	return false
}

// GetMilestoneByID finds a milestone by ID
func (r *Roadmap) GetMilestoneByID(id string) *Milestone {
	for i := range r.Milestones {
		if r.Milestones[i].ID == id {
			return &r.Milestones[i]
		}
	}
	return nil
}

// GetTasksByParentID finds all tasks with the given parent ID
func (r *Roadmap) GetTasksByParentID(parentID string) []Task {
	var tasks []Task
	for _, task := range r.Tasks {
		if task.ParentID == parentID {
			tasks = append(tasks, task)
		}
	}
	return tasks
}

// GetInCycleTasks returns all tasks that are in the current cycle
func (r *Roadmap) GetInCycleTasks() []Task {
	var tasks []Task
	
	// First find milestones that are in-cycle
	inCycleMilestones := make(map[string]bool)
	for _, milestone := range r.Milestones {
		if milestone.CycleStatus == "in-cycle" {
			inCycleMilestones[milestone.ID] = true
		}
	}
	
	// Then find tasks under those milestones
	for _, task := range r.Tasks {
		if inCycleMilestones[task.ParentID] {
			tasks = append(tasks, task)
		}
	}
	
	return tasks
} 