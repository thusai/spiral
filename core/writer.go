package core

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/thusai/spiral/types"
	"gopkg.in/yaml.v3"
)

// SaveRoadmap (no file path) - convenience function using default file
func SaveRoadmap(roadmap *types.Roadmap) error {
	filePath, err := FindDefaultRoadmapFile()
	if err != nil {
		return err
	}
	return SaveRoadmapToFile(roadmap, filePath)
}

// SaveRoadmapToFile atomically writes a roadmap to a YAML file
func SaveRoadmapToFile(roadmap *types.Roadmap, filePath string) error {
	// Validate before saving
	if err := ValidateRoadmap(roadmap); err != nil {
		return fmt.Errorf("roadmap validation failed: %w", err)
	}

	// Marshal to YAML
	data, err := yaml.Marshal(roadmap)
	if err != nil {
		return fmt.Errorf("failed to marshal roadmap to YAML: %w", err)
	}

	// Use atomic write (temp file + rename)
	return atomicWriteFile(filePath, data)
}

// AddMilestone adds a new milestone to the roadmap
func AddMilestone(roadmap *types.Roadmap, milestone types.Milestone) error {
	// Check for duplicate ID
	for _, existing := range roadmap.Milestones {
		if existing.ID == milestone.ID {
			return fmt.Errorf("milestone with ID %s already exists", milestone.ID)
		}
	}

	// Validate fields
	if milestone.ID == "" {
		return fmt.Errorf("milestone ID cannot be empty")
	}
	if milestone.Title == "" {
		return fmt.Errorf("milestone title cannot be empty")
	}

	// Validate enum fields
	if milestone.Priority != "" && !types.IsValidPriority(milestone.Priority) {
		return fmt.Errorf("invalid priority: %s", milestone.Priority)
	}

	if milestone.CycleStatus != "" && !types.IsValidCycleStatus(milestone.CycleStatus) {
		return fmt.Errorf("invalid cycle_status: %s", milestone.CycleStatus)
	}

	// Add milestone
	roadmap.Milestones = append(roadmap.Milestones, milestone)
	return nil
}

// AddTask adds a new task to the roadmap
func AddTask(roadmap *types.Roadmap, task types.Task) error {
	// Check for duplicate ID
	for _, existing := range roadmap.Tasks {
		if existing.ID == task.ID {
			return fmt.Errorf("task with ID %s already exists", task.ID)
		}
	}

	// Validate fields
	if task.ID == "" {
		return fmt.Errorf("task ID cannot be empty")
	}
	if task.Title == "" {
		return fmt.Errorf("task title cannot be empty")
	}
	if task.ParentID == "" {
		return fmt.Errorf("task parent_id cannot be empty")
	}

	// Validate parent exists
	parentExists := false
	for _, milestone := range roadmap.Milestones {
		if milestone.ID == task.ParentID {
			parentExists = true
			break
		}
	}
	if !parentExists {
		for _, existingTask := range roadmap.Tasks {
			if existingTask.ID == task.ParentID {
				parentExists = true
				break
			}
		}
	}
	if !parentExists {
		return fmt.Errorf("parent %s does not exist", task.ParentID)
	}

	// Validate enum fields
	if task.Status != "" && !types.IsValidTaskStatus(task.Status) {
		return fmt.Errorf("invalid status: %s", task.Status)
	}

	// Add task
	roadmap.Tasks = append(roadmap.Tasks, task)
	return nil
}

// UpdateMilestone updates an existing milestone
func UpdateMilestone(roadmap *types.Roadmap, id string, updates map[string]interface{}) error {
	// Find milestone
	var milestone *types.Milestone
	for i := range roadmap.Milestones {
		if roadmap.Milestones[i].ID == id {
			milestone = &roadmap.Milestones[i]
			break
		}
	}
	if milestone == nil {
		return fmt.Errorf("milestone %s not found", id)
	}

	// Apply updates
	for field, value := range updates {
		switch field {
		case "title":
			if str, ok := value.(string); ok {
				milestone.Title = str
			}
		case "family":
			if str, ok := value.(string); ok {
				milestone.Family = str
			}

		case "priority":
			if str, ok := value.(string); ok {
				if str != "" && !types.IsValidPriority(str) {
					return fmt.Errorf("invalid priority: %s", str)
				}
				milestone.Priority = str
			}
		case "cycle_status":
			if str, ok := value.(string); ok {
				if str != "" && !types.IsValidCycleStatus(str) {
					return fmt.Errorf("invalid cycle_status: %s", str)
				}
				milestone.CycleStatus = str
			}

		default:
			return fmt.Errorf("unknown field: %s", field)
		}
	}

	return nil
}

// UpdateTask updates an existing task
func UpdateTask(roadmap *types.Roadmap, id string, updates map[string]interface{}) error {
	// Find task
	var task *types.Task
	for i := range roadmap.Tasks {
		if roadmap.Tasks[i].ID == id {
			task = &roadmap.Tasks[i]
			break
		}
	}
	if task == nil {
		return fmt.Errorf("task %s not found", id)
	}

	// Apply updates
	for field, value := range updates {
		switch field {
		case "title":
			if str, ok := value.(string); ok {
				task.Title = str
			}
		case "status":
			if str, ok := value.(string); ok {
				if str != "" && !types.IsValidTaskStatus(str) {
					return fmt.Errorf("invalid status: %s", str)
				}
				task.Status = str
			}
		case "notes":
			if str, ok := value.(string); ok {
				task.Notes = str
			}
		default:
			return fmt.Errorf("unknown field: %s", field)
		}
	}

	return nil
}

// GenerateNextTaskID generates the next task ID for a given parent
func GenerateNextTaskID(roadmap *types.Roadmap, parentID string) string {
	// Find highest existing task number for this parent
	maxNum := 0
	prefix := parentID + "."
	
	for _, task := range roadmap.Tasks {
		if strings.HasPrefix(task.ID, prefix) {
			// Extract number after the last dot
			parts := strings.Split(task.ID, ".")
			if len(parts) > 0 {
				lastPart := parts[len(parts)-1]
				var num int
				fmt.Sscanf(lastPart, "%d", &num)
				if num > maxNum {
					maxNum = num
				}
			}
		}
	}
	
	return fmt.Sprintf("%s.%d", parentID, maxNum+1)
}

// atomicWriteFile writes data to a file atomically using temp file + rename
func atomicWriteFile(filePath string, data []byte) error {
	// Create directory if it doesn't exist
	dir := filepath.Dir(filePath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("failed to create directory: %w", err)
	}

	// Create temporary file in the same directory
	tempFile, err := os.CreateTemp(dir, ".spiral-temp-*")
	if err != nil {
		return fmt.Errorf("failed to create temp file: %w", err)
	}
	tempPath := tempFile.Name()

	// Clean up temp file on error
	defer func() {
		if tempFile != nil {
			tempFile.Close()
			os.Remove(tempPath)
		}
	}()

	// Write data to temp file
	if _, err := tempFile.Write(data); err != nil {
		return fmt.Errorf("failed to write temp file: %w", err)
	}

	// Sync to disk
	if err := tempFile.Sync(); err != nil {
		return fmt.Errorf("failed to sync temp file: %w", err)
	}

	// Close temp file
	if err := tempFile.Close(); err != nil {
		return fmt.Errorf("failed to close temp file: %w", err)
	}
	tempFile = nil // Mark as closed

	// Atomic rename
	if err := os.Rename(tempPath, filePath); err != nil {
		return fmt.Errorf("failed to rename temp file: %w", err)
	}

	return nil
} 