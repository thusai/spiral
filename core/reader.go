package core

import (
	"fmt"
	"os"

	"github.com/spiral/spiral/types"
	"gopkg.in/yaml.v3"
)



// ValidateRoadmap performs basic validation on the roadmap structure
func ValidateRoadmap(roadmap *types.Roadmap) error {
	// Validate milestones
	milestoneIDs := make(map[string]bool)
	for i, milestone := range roadmap.Milestones {
		if milestone.ID == "" {
			return fmt.Errorf("milestone at index %d has empty ID", i)
		}
		if milestone.Title == "" {
			return fmt.Errorf("milestone %s has empty title", milestone.ID)
		}
		if milestoneIDs[milestone.ID] {
			return fmt.Errorf("duplicate milestone ID: %s", milestone.ID)
		}
		milestoneIDs[milestone.ID] = true

		// Validate enum values
		if milestone.Priority != "" && !types.IsValidPriority(milestone.Priority) {
			return fmt.Errorf("milestone %s has invalid priority: %s", milestone.ID, milestone.Priority)
		}

		if milestone.CycleStatus != "" && !types.IsValidCycleStatus(milestone.CycleStatus) {
			return fmt.Errorf("milestone %s has invalid cycle_status: %s", milestone.ID, milestone.CycleStatus)
		}
	}

	// Validate tasks
	taskIDs := make(map[string]bool)
	for i, task := range roadmap.Tasks {
		if task.ID == "" {
			return fmt.Errorf("task at index %d has empty ID", i)
		}
		if task.Title == "" {
			return fmt.Errorf("task %s has empty title", task.ID)
		}
		if task.ParentID == "" {
			return fmt.Errorf("task %s has empty parent_id", task.ID)
		}
		if taskIDs[task.ID] {
			return fmt.Errorf("duplicate task ID: %s", task.ID)
		}
		taskIDs[task.ID] = true

		// Validate parent exists
		if !milestoneIDs[task.ParentID] && !taskIDs[task.ParentID] {
			return fmt.Errorf("task %s references non-existent parent: %s", task.ID, task.ParentID)
		}

		// Validate enum values
		if task.Status != "" && !types.IsValidTaskStatus(task.Status) {
			return fmt.Errorf("task %s has invalid status: %s", task.ID, task.Status)
		}
	}

	return nil
}

// FindDefaultRoadmapFile looks for a roadmap file in the current directory
func FindDefaultRoadmapFile() (string, error) {
	candidates := []string{
		"spiral.yml",
		"roadmap.yml", 
		"milestones.yml",
		"spiral.yaml",
		"roadmap.yaml",
		"milestones.yaml",
	}

	for _, candidate := range candidates {
		if _, err := os.Stat(candidate); err == nil {
			return candidate, nil
		}
	}

	// Default to spiral.yml if none found
	return "spiral.yml", nil
}

// GetRoadmapStats returns basic statistics about the roadmap
func GetRoadmapStats(roadmap *types.Roadmap) map[string]interface{} {
	stats := make(map[string]interface{})
	
	// Milestone counts by status
	milestonesByStatus := make(map[string]int)
	for _, milestone := range roadmap.Milestones {
		status := milestone.CycleStatus
		if status == "" {
			status = "planned"
		}
		milestonesByStatus[status]++
	}
	
	// Task counts by status
	tasksByStatus := make(map[string]int)
	for _, task := range roadmap.Tasks {
		status := task.Status
		if status == "" {
			status = "planned"
		}
		tasksByStatus[status]++
	}
	
	stats["total_milestones"] = len(roadmap.Milestones)
	stats["total_tasks"] = len(roadmap.Tasks)
	stats["milestones_by_status"] = milestonesByStatus
	stats["tasks_by_status"] = tasksByStatus
	stats["in_cycle_tasks"] = len(roadmap.GetInCycleTasks())
	
	return stats
}

// LoadRoadmap (no params) - convenience function using default file
func LoadRoadmap() (*types.Roadmap, error) {
	filePath, err := FindDefaultRoadmapFile()
	if err != nil {
		return nil, err
	}
	return LoadRoadmapFromFile(filePath)
}

// LoadRoadmapFromFile loads from a specific file path (rename existing function)
func LoadRoadmapFromFile(filePath string) (*types.Roadmap, error) {
	// Check if file exists
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		// Create default roadmap if file doesn't exist
		roadmap := &types.Roadmap{
			Milestones: []types.Milestone{},
			Tasks:      []types.Task{},
		}
		if err := SaveRoadmapToFile(roadmap, filePath); err != nil {
			return nil, fmt.Errorf("failed to create default roadmap: %w", err)
		}
		return roadmap, nil
	}

	// Read file
	data, err := os.ReadFile(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to read roadmap file: %w", err)
	}

	// Parse YAML
	var roadmap types.Roadmap
	if err := yaml.Unmarshal(data, &roadmap); err != nil {
		return nil, fmt.Errorf("failed to parse roadmap YAML: %w", err)
	}

	// Initialize empty slices if nil
	if roadmap.Milestones == nil {
		roadmap.Milestones = []types.Milestone{}
	}
	if roadmap.Tasks == nil {
		roadmap.Tasks = []types.Task{}
	}

	return &roadmap, nil
} 