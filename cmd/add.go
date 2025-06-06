package cmd

import (
	"fmt"

	"github.com/spiral/spiral/config"
	"github.com/spiral/spiral/core"
	"github.com/spiral/spiral/types"
	"github.com/urfave/cli/v2"
)

// AddCommand returns the add subcommand
func AddCommand() *cli.Command {
	return &cli.Command{
		Name:  "add",
		Usage: "Add milestones, tasks, or subtasks",
		Subcommands: []*cli.Command{
			{
				Name:  "milestone",
				Usage: "Add a new milestone",
				Flags: []cli.Flag{
					&cli.StringFlag{
						Name:  "id", 
						Usage: "Milestone ID (family-prefixed, e.g., D3) - auto-generated if not provided",
					},
					&cli.StringFlag{
						Name:     "title", 
						Required: true, 
						Usage:    "Milestone title",
					},
					&cli.StringFlag{
						Name:  "family", 
						Usage: "Product family (e.g., D, E, F)",
						Value: "D",
					},
					&cli.StringFlag{
						Name:  "priority", 
						Usage: "Priority: low, medium, high, critical",
						Value: "medium",
					},
					&cli.StringFlag{
						Name:  "cycle-status", 
						Usage: "Cycle status: planned, in-cycle",
						Value: "planned",
					},
					&cli.StringFlag{
						Name:  "notes", 
						Usage: "Optional notes",
					},
				},
				Action: addMilestone,
			},
			{
				Name:  "task",
				Usage: "Add a new task to a milestone",
				Flags: []cli.Flag{
					&cli.StringFlag{
						Name:  "id", 
						Usage: "Task ID (auto-generated if not provided)",
					},
					&cli.StringFlag{
						Name:     "parent", 
						Required: true, 
						Usage:    "Parent milestone ID (e.g., D3)",
					},
					&cli.StringFlag{
						Name:     "title", 
						Required: true, 
						Usage:    "Task title",
					},
					&cli.StringFlag{
						Name:  "status", 
						Value: "planned", 
						Usage: "Task status: planned, in-progress, done, blocked",
					},
					&cli.StringFlag{
						Name:  "priority", 
						Usage: "Priority: low, medium, high, critical",
					},
					&cli.StringFlag{
						Name:  "notes", 
						Usage: "Optional notes",
					},
				},
				Action: addTask,
			},
			{
				Name:  "subtask",
				Usage: "Add a new subtask to a task",
				Flags: []cli.Flag{
					&cli.StringFlag{
						Name:  "id", 
						Usage: "Subtask ID (auto-generated if not provided)",
					},
					&cli.StringFlag{
						Name:     "parent", 
						Required: true, 
						Usage:    "Parent task ID (e.g., D3.1)",
					},
					&cli.StringFlag{
						Name:     "title", 
						Required: true, 
						Usage:    "Subtask title",
					},
					&cli.StringFlag{
						Name:  "status", 
						Value: "planned", 
						Usage: "Subtask status: planned, in-progress, done, blocked",
					},
					&cli.StringFlag{
						Name:  "priority", 
						Usage: "Priority: low, medium, high, critical",
					},
					&cli.StringFlag{
						Name:  "notes", 
						Usage: "Optional notes",
					},
				},
				Action: addTask, // Subtasks are just tasks with task parents
			},
		},
	}
}

func addMilestone(c *cli.Context) error {
	// Load roadmap
	roadmap, err := core.LoadRoadmap("spiral.yml")
	if err != nil {
		return err
	}

	// Get or generate milestone ID
	milestoneID := c.String("id")
	family := c.String("family")
	
	if milestoneID == "" {
		// Auto-generate ID using family
		generator := core.NewIDGenerator(roadmap)
		milestoneID = generator.GenerateNextMilestoneID(family)
	} else {
		// Validate provided ID format
		parsedID, err := types.ParseID(milestoneID)
		if err != nil {
			return fmt.Errorf("invalid ID format: %w", err)
		}
		if parsedID.Level() != 0 {
			return fmt.Errorf("expected milestone ID, got: %s", milestoneID)
		}
		// Extract family from provided ID
		family = parsedID.Family
	}

	// Validate input
	priority := c.String("priority")
	if priority != "" && !types.IsValidPriority(priority) {
		return fmt.Errorf("invalid priority: %s", priority)
	}

	cycleStatus := c.String("cycle-status")
	if cycleStatus != "" && !types.IsValidCycleStatus(cycleStatus) {
		return fmt.Errorf("invalid cycle status: %s", cycleStatus)
	}

	// Check for duplicate ID
	generator := core.NewIDGenerator(roadmap)
	if err := generator.ValidateID(milestoneID); err != nil {
		return err
	}

	// Create milestone
	milestone := types.Milestone{
		ID:          milestoneID,
		Family:      family,
		Title:       c.String("title"),
		Priority:    priority,
		CycleStatus: cycleStatus,
		Status:      "planned", // Default status
		Notes:       c.String("notes"),
	}

	// Add milestone to roadmap
	roadmap.Milestones = append(roadmap.Milestones, milestone)

	// Save roadmap
	if err := core.SaveRoadmap(roadmap, "spiral.yml"); err != nil {
		return fmt.Errorf("failed to save roadmap: %w", err)
	}

	fmt.Printf("✅ Added milestone %s: %s\n", milestone.ID, milestone.Title)
	fmt.Printf("   Family: %s, Priority: %s, Cycle: %s\n", 
		milestone.Family, milestone.Priority, milestone.CycleStatus)

	// Set as current context if in-cycle
	if milestone.CycleStatus == "in-cycle" {
		ctx := types.Context{
			MilestoneID: milestone.ID,
			Family:      milestone.Family,
		}
		if err := config.SaveContext(ctx); err == nil {
			fmt.Printf("🎯 Set %s as current working context\n", milestone.ID)
		}
	}

	return nil
}

func addTask(c *cli.Context) error {
	// Load roadmap
	roadmap, err := core.LoadRoadmap("spiral.yml")
	if err != nil {
		return err
	}

	parentID := c.String("parent")
	
	// Validate parent exists
	parentExists := false
	isParentTask := false
	
	// Check if parent is a milestone
	for _, milestone := range roadmap.Milestones {
		if milestone.ID == parentID {
			parentExists = true
			break
		}
	}
	
	// Check if parent is a task (for subtasks)
	if !parentExists {
		for _, task := range roadmap.Tasks {
			if task.ID == parentID {
				parentExists = true
				isParentTask = true
				break
			}
		}
	}
	
	if !parentExists {
		return fmt.Errorf("parent %s not found", parentID)
	}

	// Get or generate task ID
	taskID := c.String("id")
	generator := core.NewIDGenerator(roadmap)
	
	if taskID == "" {
		// Auto-generate ID based on parent
		if isParentTask {
			taskID, err = generator.GenerateNextSubtaskID(parentID)
		} else {
			taskID, err = generator.GenerateNextTaskID(parentID)
		}
		if err != nil {
			return fmt.Errorf("failed to generate ID: %w", err)
		}
	} else {
		// Validate provided ID
		if err := generator.ValidateID(taskID); err != nil {
			return err
		}
		
		// Verify ID matches parent structure
		parsedID, err := types.ParseID(taskID)
		if err != nil {
			return fmt.Errorf("invalid ID format: %w", err)
		}
		
		expectedParent := parsedID.ParentID()
		if expectedParent != parentID {
			return fmt.Errorf("ID %s does not match parent %s (expected parent: %s)", 
				taskID, parentID, expectedParent)
		}
	}

	// Validate input
	status := c.String("status")
	if status != "" && !types.IsValidTaskStatus(status) {
		return fmt.Errorf("invalid status: %s", status)
	}

	priority := c.String("priority")
	if priority != "" && !types.IsValidPriority(priority) {
		return fmt.Errorf("invalid priority: %s", priority)
	}

	// Create task
	task := types.Task{
		ID:       taskID,
		ParentID: parentID,
		Title:    c.String("title"),
		Status:   status,
		Priority: priority,
		Notes:    c.String("notes"),
	}

	// Add task to roadmap
	roadmap.Tasks = append(roadmap.Tasks, task)

	// Save roadmap
	if err := core.SaveRoadmap(roadmap, "spiral.yml"); err != nil {
		return fmt.Errorf("failed to save roadmap: %w", err)
	}

	// Determine display type
	taskType := "task"
	if isParentTask {
		taskType = "subtask"
	}

	fmt.Printf("✅ Added %s %s: %s\n", taskType, task.ID, task.Title)
	fmt.Printf("   Parent: %s, Status: %s\n", task.ParentID, task.Status)

	return nil
} 