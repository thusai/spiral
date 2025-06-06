package core

import (
	"fmt"

	"github.com/spiral/spiral/types"
)

// IDGenerator provides smart ID generation with family context
type IDGenerator struct {
	roadmap *types.Roadmap
}

// NewIDGenerator creates a new ID generator
func NewIDGenerator(roadmap *types.Roadmap) *IDGenerator {
	return &IDGenerator{roadmap: roadmap}
}

// GenerateNextMilestoneID generates the next milestone ID for a family
func (g *IDGenerator) GenerateNextMilestoneID(family string) string {
	maxMilestone := 0

	// Find the highest milestone number for this family
	for _, milestone := range g.roadmap.Milestones {
		if milestone.Family == family {
			// Parse the milestone ID to extract the number
			if parsedID, err := types.ParseID(milestone.ID); err == nil {
				if parsedID.Family == family && parsedID.Milestone > maxMilestone {
					maxMilestone = parsedID.Milestone
				}
			}
		}
	}

	// Return the next milestone ID
	return fmt.Sprintf("%s%d", family, maxMilestone+1)
}

// GenerateNextTaskID generates the next task ID for a milestone
func (g *IDGenerator) GenerateNextTaskID(milestoneID string) (string, error) {
	// Parse the milestone ID to extract family and milestone number
	parsedMilestone, err := types.ParseID(milestoneID)
	if err != nil {
		return "", fmt.Errorf("invalid milestone ID: %w", err)
	}

	if parsedMilestone.Task != nil || parsedMilestone.Subtask != nil {
		return "", fmt.Errorf("expected milestone ID, got: %s", milestoneID)
	}

	maxTask := 0

	// Find the highest task number for this milestone
	for _, task := range g.roadmap.Tasks {
		if task.ParentID == milestoneID {
			// Parse the task ID to extract the task number
			if parsedID, err := types.ParseID(task.ID); err == nil {
				if parsedID.Family == parsedMilestone.Family &&
					parsedID.Milestone == parsedMilestone.Milestone &&
					parsedID.Task != nil && *parsedID.Task > maxTask {
					maxTask = *parsedID.Task
				}
			}
		}
	}

	// Generate next task ID
	taskNum := maxTask + 1
	id := types.ID{
		Family:    parsedMilestone.Family,
		Milestone: parsedMilestone.Milestone,
		Task:      &taskNum,
	}

	return id.String(), nil
}

// GenerateNextSubtaskID generates the next subtask ID for a task
func (g *IDGenerator) GenerateNextSubtaskID(taskID string) (string, error) {
	// Parse the task ID to extract family, milestone, and task number
	parsedTask, err := types.ParseID(taskID)
	if err != nil {
		return "", fmt.Errorf("invalid task ID: %w", err)
	}

	if parsedTask.Task == nil || parsedTask.Subtask != nil {
		return "", fmt.Errorf("expected task ID, got: %s", taskID)
	}

	maxSubtask := 0

	// Find the highest subtask number for this task
	for _, task := range g.roadmap.Tasks {
		if task.ParentID == taskID {
			// Parse the subtask ID to extract the subtask number
			if parsedID, err := types.ParseID(task.ID); err == nil {
				if parsedID.Family == parsedTask.Family &&
					parsedID.Milestone == parsedTask.Milestone &&
					parsedID.Task != nil && *parsedID.Task == *parsedTask.Task &&
					parsedID.Subtask != nil && *parsedID.Subtask > maxSubtask {
					maxSubtask = *parsedID.Subtask
				}
			}
		}
	}

	// Generate next subtask ID
	subtaskNum := maxSubtask + 1
	id := types.ID{
		Family:    parsedTask.Family,
		Milestone: parsedTask.Milestone,
		Task:      parsedTask.Task,
		Subtask:   &subtaskNum,
	}

	return id.String(), nil
}

// ValidateID checks if an ID is properly formatted and doesn't conflict
func (g *IDGenerator) ValidateID(idStr string) error {
	// Parse the ID first
	parsedID, err := types.ParseID(idStr)
	if err != nil {
		return err
	}

	// Check for conflicts based on the ID type
	switch parsedID.Level() {
	case 0: // Milestone
		for _, milestone := range g.roadmap.Milestones {
			if milestone.ID == idStr {
				return fmt.Errorf("milestone ID %s already exists", idStr)
			}
		}
	case 1, 2: // Task or Subtask
		for _, task := range g.roadmap.Tasks {
			if task.ID == idStr {
				return fmt.Errorf("task ID %s already exists", idStr)
			}
		}
	}

	return nil
}

// SuggestID suggests an appropriate ID for the given context
func (g *IDGenerator) SuggestID(family string, parentID string) (string, error) {
	if parentID == "" {
		// Generate milestone ID
		return g.GenerateNextMilestoneID(family), nil
	}

	// Parse parent to determine what type of ID to generate
	parsedParent, err := types.ParseID(parentID)
	if err != nil {
		return "", fmt.Errorf("invalid parent ID: %w", err)
	}

	switch parsedParent.Level() {
	case 0: // Parent is milestone, generate task
		return g.GenerateNextTaskID(parentID)
	case 1: // Parent is task, generate subtask
		return g.GenerateNextSubtaskID(parentID)
	default:
		return "", fmt.Errorf("cannot create child of subtask %s", parentID)
	}
}

// GetFamilyFromContext extracts family from current context or suggests based on patterns
func (g *IDGenerator) GetFamilyFromContext(context *types.Context) string {
	// If context has a family set, use it
	if context.Family != "" {
		return context.Family
	}

	// If context has a milestone, extract family from it
	if context.MilestoneID != "" {
		if parsedID, err := types.ParseID(context.MilestoneID); err == nil {
			return parsedID.Family
		}
	}

	// If context has a task, extract family from it
	if context.TaskID != "" {
		if parsedID, err := types.ParseID(context.TaskID); err == nil {
			return parsedID.Family
		}
	}

	// Default to "D" if no context available
	return "D"
}

// ExtractFamilyFromID extracts the family from any ID string
func ExtractFamilyFromID(idStr string) (string, error) {
	parsedID, err := types.ParseID(idStr)
	if err != nil {
		return "", err
	}
	return parsedID.Family, nil
}

// FormatIDForCommit formats an ID for use in git commit messages
func FormatIDForCommit(idStr string) string {
	return fmt.Sprintf("[%s]", idStr)
}

// ParseCommitMessage extracts ID from commit message if present
func ParseCommitMessage(message string) (string, string, bool) {
	// Look for pattern [ID] at the start of the message
	if len(message) < 3 || message[0] != '[' {
		return "", message, false
	}

	// Find the closing bracket
	closeIdx := -1
	for i := 1; i < len(message); i++ {
		if message[i] == ']' {
			closeIdx = i
			break
		}
	}

	if closeIdx == -1 {
		return "", message, false
	}

	// Extract ID and remaining message
	id := message[1:closeIdx]
	remainingMessage := message[closeIdx+1:]
	
	// Trim leading space from remaining message
	if len(remainingMessage) > 0 && remainingMessage[0] == ' ' {
		remainingMessage = remainingMessage[1:]
	}

	// Validate the extracted ID
	if _, err := types.ParseID(id); err != nil {
		return "", message, false
	}

	return id, remainingMessage, true
} 