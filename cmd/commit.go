package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/thusai/spiral/config"
	"github.com/thusai/spiral/core"
	"github.com/thusai/spiral/types"
	"github.com/urfave/cli/v2"
)

// CommitCommand returns the commit subcommand
func CommitCommand() *cli.Command {
	return &cli.Command{
		Name:  "commit",
		Usage: "Smart commit with automatic task creation",
		Flags: []cli.Flag{
			&cli.BoolFlag{Name: "auto", Usage: "Enable automatic milestone/task creation"},
		},
		Action: func(c *cli.Context) error {
			message := c.Args().First()
			if message == "" {
				return fmt.Errorf("commit message required")
			}

			return handleSmartCommit(message, c.Bool("auto"))
		},
	}
}

func handleSmartCommit(message string, autoMode bool) error {
	// Check if we're in a git repository
	if !isGitRepo() {
		return fmt.Errorf("not in a git repository")
	}

	// Load current roadmap and context
	roadmap, err := core.LoadRoadmap()
	if err != nil {
		return fmt.Errorf("failed to load roadmap: %w", err)
	}

	context, err := config.LoadContext()
	if err != nil {
		// No context is okay, we'll handle it
		context = types.Context{}
	}

	// Determine commit strategy
	if context.MilestoneID != "" {
		return commitWithContext(roadmap, context, message, autoMode)
	} else {
		return commitWithoutContext(roadmap, message, autoMode)
	}
}

func commitWithContext(roadmap *types.Roadmap, context types.Context, message string, autoMode bool) error {
	// Find the current milestone
	var currentMilestone *types.Milestone
	for i := range roadmap.Milestones {
		if roadmap.Milestones[i].ID == context.MilestoneID {
			currentMilestone = &roadmap.Milestones[i]
			break
		}
	}

	if currentMilestone == nil {
		fmt.Printf("⚠️  Context milestone %s not found, switching to no-context mode\n", context.MilestoneID)
		return commitWithoutContext(roadmap, message, autoMode)
	}

	fmt.Printf("🎯 Current context: %s (%s)\n", currentMilestone.ID, currentMilestone.Title)

	if autoMode {
		return autoCommitWithContext(roadmap, currentMilestone, message)
	} else {
		return interactiveCommitWithContext(roadmap, currentMilestone, message)
	}
}

func commitWithoutContext(roadmap *types.Roadmap, message string, autoMode bool) error {
	if autoMode {
		return autoCommitWithoutContext(roadmap, message)
	} else {
		return interactiveCommitWithoutContext(roadmap, message)
	}
}

func autoCommitWithContext(roadmap *types.Roadmap, milestone *types.Milestone, message string) error {
	fmt.Printf("🔍 Auto-detected context: %s (%s)\n", milestone.ID, milestone.Title)
	fmt.Printf("Creating task automatically...\n")

	// Generate next task ID
	nextTaskID, err := core.GenerateNextID(milestone.ID, roadmap)
	if err != nil {
		return fmt.Errorf("failed to generate task ID: %w", err)
	}

	// Create new task
	newTask := types.Task{
		ID:       nextTaskID,
		ParentID: milestone.ID,
		Title:    message,
		Status:   "done", // Mark as done since we're committing completed work
	}

	// Add task to roadmap
	roadmap.Tasks = append(roadmap.Tasks, newTask)

	// Save roadmap
	if err := core.SaveRoadmap(roadmap); err != nil {
		return fmt.Errorf("failed to save roadmap: %w", err)
	}

	// Create git commit with tag
	commitMessage := fmt.Sprintf("[%s] %s", nextTaskID, message)
	if err := gitCommit(commitMessage); err != nil {
		return fmt.Errorf("git commit failed: %w", err)
	}

	fmt.Printf("✅ Created commit: %s\n", commitMessage)
	fmt.Printf("✅ Added task: %s\n", nextTaskID)

	return nil
}

func interactiveCommitWithContext(roadmap *types.Roadmap, milestone *types.Milestone, message string) error {
	fmt.Printf("🎯 Current context: %s (%s)\n", milestone.ID, milestone.Title)
	
	fmt.Print("Create task for this milestone? [Y/n]: ")
	var response string
	fmt.Scanln(&response)
	
	if strings.ToLower(response) == "n" {
		return handleContextSwitch(roadmap, message)
	}

	// Generate next task ID
	nextTaskID, err := core.GenerateNextID(milestone.ID, roadmap)
	if err != nil {
		return fmt.Errorf("failed to generate task ID: %w", err)
	}

	// Create new task
	newTask := types.Task{
		ID:       nextTaskID,
		ParentID: milestone.ID,
		Title:    message,
		Status:   "done",
	}

	// Add task to roadmap
	roadmap.Tasks = append(roadmap.Tasks, newTask)

	// Save roadmap
	if err := core.SaveRoadmap(roadmap); err != nil {
		return fmt.Errorf("failed to save roadmap: %w", err)
	}

	// Create git commit with tag
	commitMessage := fmt.Sprintf("[%s] %s", nextTaskID, message)
	if err := gitCommit(commitMessage); err != nil {
		return fmt.Errorf("git commit failed: %w", err)
	}

	fmt.Printf("✅ Created commit: %s\n", commitMessage)
	fmt.Printf("✅ Added task: %s\n", nextTaskID)

	return nil
}

func autoCommitWithoutContext(roadmap *types.Roadmap, message string) error {
	fmt.Printf("🎯 No working context - auto-creating milestone from message\n")

	// Extract title from message (first part before dash if present)
	title := extractMilestoneTitle(message)
	
	// Generate next milestone ID using default family 'S' for now
	nextMilestoneID, err := core.GenerateNextFamilyID("S", roadmap)
	if err != nil {
		return fmt.Errorf("failed to generate milestone ID: %w", err)
	}

	fmt.Printf("🎯 Auto-creating milestone: %s - %s\n", nextMilestoneID, title)

	// Create new milestone
	newMilestone := types.Milestone{
		ID:          nextMilestoneID,
		Family:      "S",
		Title:       title,
		Priority:    "medium",
		CycleStatus: "in-cycle",
		Status:      "in-progress",
	}

	// Add milestone to roadmap
	roadmap.Milestones = append(roadmap.Milestones, newMilestone)

	// Set as current context
	context := types.Context{
		MilestoneID: nextMilestoneID,
		Family:      "S",
	}
	if err := config.SaveContext(context); err != nil {
		return fmt.Errorf("failed to save context: %w", err)
	}

	// Generate first task ID
	firstTaskID, err := core.GenerateNextID(nextMilestoneID, roadmap)
	if err != nil {
		return fmt.Errorf("failed to generate task ID: %w", err)
	}

	// Create new task
	newTask := types.Task{
		ID:       firstTaskID,
		ParentID: nextMilestoneID,
		Title:    message,
		Status:   "done",
	}

	// Add task to roadmap
	roadmap.Tasks = append(roadmap.Tasks, newTask)

	// Save roadmap
	if err := core.SaveRoadmap(roadmap); err != nil {
		return fmt.Errorf("failed to save roadmap: %w", err)
	}

	// Create git commit with tag
	commitMessage := fmt.Sprintf("[%s] %s", firstTaskID, message)
	if err := gitCommit(commitMessage); err != nil {
		return fmt.Errorf("git commit failed: %w", err)
	}

	fmt.Printf("✅ Created milestone: %s - %s\n", nextMilestoneID, title)
	fmt.Printf("✅ Created commit: %s\n", commitMessage)
	fmt.Printf("✅ Added task: %s\n", firstTaskID)
	fmt.Printf("✅ Set working context to: %s\n", nextMilestoneID)

	return nil
}

func interactiveCommitWithoutContext(roadmap *types.Roadmap, message string) error {
	fmt.Printf("Recent milestones:\n")
	showRecentMilestones(roadmap)
	fmt.Printf("\n")
	
	fmt.Print("Associate with milestone? [ID/auto/new/skip]: ")
	var choice string
	fmt.Scanln(&choice)

	switch choice {
	case "skip":
		return regularGitCommit(message)
	case "auto":
		return autoCommitWithoutContext(roadmap, message)
	case "new":
		fmt.Printf("Create new milestone first with: spiral add milestone\n")
		return nil
	default:
		// Try to find the milestone
		var targetMilestone *types.Milestone
		for i := range roadmap.Milestones {
			if roadmap.Milestones[i].ID == choice {
				targetMilestone = &roadmap.Milestones[i]
				break
			}
		}

		if targetMilestone == nil {
			return fmt.Errorf("milestone %s not found", choice)
		}

		// Set context and commit
		context := types.Context{
			MilestoneID: targetMilestone.ID,
			Family:      targetMilestone.Family,
		}
		if err := config.SaveContext(context); err != nil {
			return fmt.Errorf("failed to save context: %w", err)
		}

		return autoCommitWithContext(roadmap, targetMilestone, message)
	}
}

func handleContextSwitch(roadmap *types.Roadmap, message string) error {
	fmt.Printf("Available milestones:\n")
	showRecentMilestones(roadmap)
	
	fmt.Print("Enter milestone ID (or 'skip' for no association): ")
	var milestoneID string
	fmt.Scanln(&milestoneID)

	if milestoneID == "skip" {
		return regularGitCommit(message)
	}

	// Find milestone and set context
	for i := range roadmap.Milestones {
		if roadmap.Milestones[i].ID == milestoneID {
			context := types.Context{
				MilestoneID: milestoneID,
				Family:      roadmap.Milestones[i].Family,
			}
			if err := config.SaveContext(context); err != nil {
				return fmt.Errorf("failed to save context: %w", err)
			}

			return autoCommitWithContext(roadmap, &roadmap.Milestones[i], message)
		}
	}

	return fmt.Errorf("milestone %s not found", milestoneID)
}

// Helper functions

func isGitRepo() bool {
	cmd := exec.Command("git", "status")
	return cmd.Run() == nil
}

func gitCommit(message string) error {
	// Stage all changes
	cmd := exec.Command("git", "add", ".")
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("git add failed: %w", err)
	}

	// Create commit
	cmd = exec.Command("git", "commit", "-m", message)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func regularGitCommit(message string) error {
	return gitCommit(message)
}

func extractMilestoneTitle(message string) string {
	// Extract meaningful title from commit message
	parts := strings.Split(message, " - ")
	title := parts[0]
	
	// Capitalize first letter and limit length
	if len(title) > 0 {
		title = strings.ToUpper(title[:1]) + strings.ToLower(title[1:])
	}
	
	if len(title) > 50 {
		title = title[:47] + "..."
	}
	
	return title
}

func showRecentMilestones(roadmap *types.Roadmap) {
	count := 0
	for _, milestone := range roadmap.Milestones {
		if count >= 5 {
			break
		}
		fmt.Printf("  %s  %s\n", milestone.ID, milestone.Title)
		count++
	}
} 