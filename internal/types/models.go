package types

import "time"

// Milestone represents a major goal or feature in the roadmap
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

// Task represents a subtask under a milestone
type Task struct {
	ID       string `yaml:"id" json:"id"`
	ParentID string `yaml:"parent_id" json:"parent_id"`
	Title    string `yaml:"title" json:"title"`
	Status   string `yaml:"status" json:"status"`
	Notes    string `yaml:"notes,omitempty" json:"notes,omitempty"`
}

// Roadmap represents the complete roadmap structure
type Roadmap struct {
	Milestones []Milestone `yaml:"milestones" json:"milestones"`
	Tasks      []Task      `yaml:"tasks,omitempty" json:"tasks,omitempty"`
}

// Context represents the current working context
type Context struct {
	ProjectName   string    `json:"project_name"`
	MilestoneID   string    `json:"milestone_id"`
	LastUpdated   time.Time `json:"last_updated"`
	CommitHistory []string  `json:"commit_history,omitempty"`
}

// ProjectConfig represents a configured project
type ProjectConfig struct {
	Name       string `json:"name"`
	YAMLPath   string `json:"yaml_path"`
	SchemaPath string `json:"schema_path"`
	Active     bool   `json:"active"`
	CreatedAt  time.Time `json:"created_at"`
}

// Config represents the global spiral configuration
type Config struct {
	ActiveProject string                   `json:"active_project"`
	Projects      map[string]ProjectConfig `json:"projects"`
	LastUpdated   time.Time               `json:"last_updated"`
}

// ValidReleaseStatuses defines allowed values for release_status
var ValidReleaseStatuses = []string{
	"parked",
	"planned",
	"in-progress",
	"done", 
	"cancelled",
}

// ValidCycleStatuses defines allowed values for cycle_status
var ValidCycleStatuses = []string{
	"planned",
	"in-cycle",
}

// ValidTaskStatuses defines allowed values for task status
var ValidTaskStatuses = []string{
	"planned",
	"in-progress", 
	"done",
	"cancelled",
}

// IsValidReleaseStatus checks if a release status is valid
func IsValidReleaseStatus(status string) bool {
	for _, valid := range ValidReleaseStatuses {
		if status == valid {
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