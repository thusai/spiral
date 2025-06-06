package cmd

import (
	"fmt"

	"github.com/fatih/color"
	"github.com/spiral/spiral/config"
	"github.com/spiral/spiral/core"
	"github.com/spiral/spiral/types"
	"github.com/urfave/cli/v2"
)

// ContextCommand returns the context subcommand
func ContextCommand() *cli.Command {
	return &cli.Command{
		Name:  "context",
		Usage: "Show or set current working context",
		Flags: []cli.Flag{
			&cli.StringFlag{Name: "id", Usage: "Set milestone ID as context"},
			&cli.BoolFlag{Name: "clear", Usage: "Clear current context"},
		},
		Action: handleContext,
	}
}

func handleContext(c *cli.Context) error {
	// Handle clear flag
	if c.Bool("clear") {
		if err := config.ClearContext(); err != nil {
			return fmt.Errorf("failed to clear context: %w", err)
		}
		fmt.Println("🗑️  Context cleared")
		return nil
	}

	// Handle setting context
	if milestoneID := c.String("id"); milestoneID != "" {
		return setContext(c, milestoneID)
	}

	// Show current context
	return showContext(c)
}

func setContext(c *cli.Context, milestoneID string) error {
	// Load roadmap to validate milestone exists
	roadmap, err := core.LoadRoadmapFromFile("spiral.yml")
	if err != nil {
		return err
	}

	// Validate milestone exists
	milestone := roadmap.GetMilestoneByID(milestoneID)
	if milestone == nil {
		return fmt.Errorf("milestone %s not found", milestoneID)
	}

	// Create context
	ctx := types.Context{
		MilestoneID: milestoneID,
		Family:      milestone.Family,
	}

	// Set context
	if err := config.SaveContext(ctx); err != nil {
		return fmt.Errorf("failed to set context: %w", err)
	}

	fmt.Printf("🎯 Set working context to: %s - %s\n", 
		color.CyanString(milestoneID), 
		milestone.Title)
	
	if milestone.Family != "" {
		fmt.Printf("   Family: %s\n", color.MagentaString(milestone.Family))
	}

	// Show tasks for this milestone
	tasks := roadmap.GetTasksByParentID(milestoneID)
	if len(tasks) > 0 {
		fmt.Printf("\n📝 Active tasks for %s:\n", milestoneID)
		for _, task := range tasks {
			statusIcon := "📝"
			if task.Status == "done" {
				statusIcon = "✅"
			} else if task.Status == "in-progress" {
				statusIcon = "🔄"
			}
			
			fmt.Printf("   %s %s - %s [%s]\n", 
				statusIcon,
				color.YellowString(task.ID), 
				task.Title, 
				colorizeStatus(task.Status))
		}
	} else {
		fmt.Printf("\n💡 No tasks yet for %s. Add one with:\n", milestoneID)
		fmt.Printf("   spiral add task --parent=%s --title='My Task'\n", milestoneID)
	}

	return nil
}

func showContext(c *cli.Context) error {
	// Load context
	context, err := config.LoadContext()
	if err != nil {
		return fmt.Errorf("failed to load context: %w", err)
	}

	// Show current context
	fmt.Println("🎯 Current Working Context:")
	fmt.Println("===========================")

	if context.MilestoneID == "" {
		fmt.Println("No context set")
		fmt.Println("")
		fmt.Println("Set context with:")
		fmt.Println("  spiral context --id=D3")
		fmt.Println("  spiral add milestone --id=D3 --title='My Milestone' --cycle-status=in-cycle")
		return nil
	}

	// Load roadmap to get milestone details
	roadmap, err := core.LoadRoadmapFromFile("spiral.yml")
	if err != nil {
		return err
	}

	milestone := roadmap.GetMilestoneByID(context.MilestoneID)
	if milestone == nil {
		fmt.Printf("⚠️  Context points to non-existent milestone: %s\n", context.MilestoneID)
		fmt.Println("   Clear context with: spiral context --clear")
		return nil
	}

	// Display context info
	fmt.Printf("Milestone: %s - %s\n", 
		color.CyanString(context.MilestoneID), 
		milestone.Title)
	
	if milestone.CycleStatus != "" {
		fmt.Printf("Cycle Status: %s\n", colorizeStatus(milestone.CycleStatus))
	}
	
	if milestone.Family != "" {
		fmt.Printf("Family: %s\n", color.MagentaString(milestone.Family))
	}
	
	if milestone.Priority != "" {
		fmt.Printf("Priority: %s\n", colorizeStatus(milestone.Priority))
	}

	// Show active tasks for this milestone
	tasks := roadmap.GetTasksByParentID(context.MilestoneID)
	if len(tasks) > 0 {
		fmt.Printf("\n📝 Active tasks:\n")
		for _, task := range tasks {
			statusIcon := "📝"
			if task.Status == "done" {
				statusIcon = "✅"
			} else if task.Status == "in-progress" {
				statusIcon = "🔄"
			} else if task.Status == "blocked" {
				statusIcon = "🚫"
			}
			
			fmt.Printf("   %s %s - %s [%s]\n", 
				statusIcon,
				color.YellowString(task.ID), 
				task.Title, 
				colorizeStatus(task.Status))
		}
	} else {
		fmt.Printf("\n💡 No tasks yet. Add one with:\n")
		fmt.Printf("   spiral add task --parent=%s --title='My Task'\n", context.MilestoneID)
	}

	// Show quick actions
	fmt.Printf("\n⚡ Quick actions:\n")
	fmt.Printf("   spiral add task --parent=%s --title='New Task'\n", context.MilestoneID)
	fmt.Printf("   spiral commit 'Work description' --auto\n")
	fmt.Printf("   spiral show cycle\n")

	return nil
}

// colorizeStatus returns a colorized version of status strings
func colorizeStatus(status string) string {
	switch status {
	case "done":
		return color.GreenString(status)
	case "in-progress", "starting":
		return color.YellowString(status)
	case "planned":
		return color.CyanString(status)
	case "blocked":
		return color.RedString(status)
	case "in-cycle":
		return color.MagentaString(status)
	case "critical":
		return color.RedString(status)
	case "high":
		return color.YellowString(status)
	case "medium":
		return color.BlueString(status)
	case "low":
		return color.WhiteString(status)
	default:
		return status
	}
}

 