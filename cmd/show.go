package cmd

import (
	"fmt"
	"sort"

	"github.com/fatih/color"
	"github.com/thusai/spiral/core"
	"github.com/thusai/spiral/types"
	"github.com/urfave/cli/v2"
)

// ShowCommand returns the show subcommand
func ShowCommand() *cli.Command {
	return &cli.Command{
		Name:  "show",
		Usage: "Display milestones, tasks, or cycle information",
		Flags: []cli.Flag{
			&cli.StringFlag{Name: "id", Usage: "Filter by specific ID"},
			&cli.StringFlag{Name: "family", Usage: "Filter by family"},
			&cli.StringFlag{Name: "priority", Usage: "Filter by priority"},
			&cli.StringFlag{Name: "status", Usage: "Filter by status"},
			&cli.StringFlag{Name: "cycle-status", Usage: "Filter by cycle status"},
		},
		Subcommands: []*cli.Command{
			{
				Name:   "all",
				Usage:  "Show complete roadmap with hierarchy",
				Action: showAll,
			},
			{
				Name:   "milestones",
				Usage:  "Show milestones",
				Action: showMilestones,
			},
			{
				Name:   "tasks",
				Usage:  "Show tasks",
				Action: showTasks,
			},
			{
				Name:   "cycle",
				Usage:  "Show current cycle status",
				Action: showCycle,
			},
		},
		Action: showAll, // Default action
	}
}

func showMilestones(c *cli.Context) error {
	// Load roadmap
	roadmap, err := core.LoadRoadmapFromFile("spiral.yml")
	if err != nil {
		return err
	}

	// Apply filters
	var filtered []types.Milestone
	for _, milestone := range roadmap.Milestones {
		if matchesMilestoneFilters(milestone, c) {
			filtered = append(filtered, milestone)
		}
	}

	// Sort by ID for logical flow
	sort.Slice(filtered, func(i, j int) bool {
		return filtered[i].ID < filtered[j].ID
	})

	// Display
	if len(filtered) == 0 {
		fmt.Println("No milestones found matching filters")
		return nil
	}

	fmt.Printf("📋 Found %d milestone(s):\n\n", len(filtered))
	displayMilestonesTable(filtered)

	return nil
}

func showTasks(c *cli.Context) error {
	// Load roadmap
	roadmap, err := core.LoadRoadmapFromFile("spiral.yml")
	if err != nil {
		return err
	}

	// Apply filters
	var filtered []types.Task
	for _, task := range roadmap.Tasks {
		if matchesTaskFilters(task, c) {
			filtered = append(filtered, task)
		}
	}

	// Sort by ID
	sort.Slice(filtered, func(i, j int) bool {
		return filtered[i].ID < filtered[j].ID
	})

	// Display
	if len(filtered) == 0 {
		fmt.Println("No tasks found matching filters")
		return nil
	}

	fmt.Printf("📝 Found %d task(s):\n\n", len(filtered))
	displayTasksTable(filtered)

	return nil
}

func showCycle(c *cli.Context) error {
	// Load roadmap
	roadmap, err := core.LoadRoadmapFromFile("spiral.yml")
	if err != nil {
		return err
	}

	// Get in-cycle milestones
	var inCycleMilestones []types.Milestone
	for _, milestone := range roadmap.Milestones {
		if milestone.CycleStatus == "in-cycle" {
			inCycleMilestones = append(inCycleMilestones, milestone)
		}
	}

	// Get in-cycle tasks
	inCycleTasks := roadmap.GetInCycleTasks()

	fmt.Println("🔄 Current Cycle Status:")
	fmt.Println("=======================")

	if len(inCycleMilestones) == 0 {
		fmt.Println("No milestones currently in cycle")
		return nil
	}

	// Show in-cycle milestones with their tasks
	for _, milestone := range inCycleMilestones {
		coloredStatus := colorizeStatus(milestone.CycleStatus)
		fmt.Printf("\n📋 %s - %s [%s]\n", 
			color.CyanString(milestone.ID), 
			milestone.Title, 
			coloredStatus)

		// Show tasks for this milestone
		milestoneTasks := roadmap.GetTasksByParentID(milestone.ID)
		if len(milestoneTasks) > 0 {
			for _, task := range milestoneTasks {
				coloredTaskStatus := colorizeStatus(task.Status)
				fmt.Printf("   └─ %s - %s [%s]\n", 
					color.YellowString(task.ID), 
					task.Title, 
					coloredTaskStatus)
			}
		} else {
			fmt.Println("   └─ No tasks yet")
		}
	}

	// Show summary
	fmt.Printf("\n📊 Summary: %d milestones, %d tasks in cycle\n", 
		len(inCycleMilestones), len(inCycleTasks))

	return nil
}

func showAll(c *cli.Context) error {
	// Load roadmap
	roadmap, err := core.LoadRoadmapFromFile("spiral.yml")
	if err != nil {
		return err
	}

	fmt.Println("🎯 Spiral Roadmap - Hierarchical View")
	fmt.Println("=====================================")

	// Sort milestones by ID for logical flow
	sort.Slice(roadmap.Milestones, func(i, j int) bool {
		return roadmap.Milestones[i].ID < roadmap.Milestones[j].ID
	})

	if len(roadmap.Milestones) == 0 {
		fmt.Println("No milestones found. Create one with:")
		fmt.Println("  spiral add milestone --title='My Milestone' --family=D")
		return nil
	}

	// Display each milestone with its tasks
	for _, milestone := range roadmap.Milestones {
		// Format milestone
		statusIcon := "📋"
		if milestone.CycleStatus == "in-cycle" {
			statusIcon = "🔄"
		} else if milestone.Status == "done" {
			statusIcon = "✅"
		}

		// Build milestone line
		var parts []string
		parts = append(parts, color.CyanString(milestone.ID))
		
		if milestone.Family != "" {
			parts = append(parts, color.MagentaString("["+milestone.Family+"]"))
		}
		
		parts = append(parts, milestone.Title)
		
		if milestone.Priority != "" {
			parts = append(parts, colorizeStatus(milestone.Priority))
		}
		
		if milestone.CycleStatus != "" {
			parts = append(parts, colorizeStatus(milestone.CycleStatus))
		}

		// Print milestone
		fmt.Printf("%s %s\n", statusIcon, joinParts(parts))

		// Show tasks for this milestone
		tasks := roadmap.GetTasksByParentID(milestone.ID)
		sort.Slice(tasks, func(i, j int) bool {
			return tasks[i].ID < tasks[j].ID
		})

		for _, task := range tasks {
			taskIcon := "📝"
			if task.Status == "done" {
				taskIcon = "✅"
			} else if task.Status == "in-progress" {
				taskIcon = "🔄"
			} else if task.Status == "blocked" {
				taskIcon = "🚫"
			}

			fmt.Printf("   └─ %s %s - %s [%s]\n", 
				taskIcon,
				color.YellowString(task.ID), 
				task.Title, 
				colorizeStatus(task.Status))
		}

		fmt.Println() // Empty line between milestones
	}

	return nil
}

// Helper functions
func matchesMilestoneFilters(milestone types.Milestone, c *cli.Context) bool {
	if id := c.String("id"); id != "" && milestone.ID != id {
		return false
	}
	if family := c.String("family"); family != "" && milestone.Family != family {
		return false
	}
	if priority := c.String("priority"); priority != "" && milestone.Priority != priority {
		return false
	}
	if cycleStatus := c.String("cycle-status"); cycleStatus != "" && milestone.CycleStatus != cycleStatus {
		return false
	}
	return true
}

func matchesTaskFilters(task types.Task, c *cli.Context) bool {
	if id := c.String("id"); id != "" && task.ID != id {
		return false
	}
	if status := c.String("status"); status != "" && task.Status != status {
		return false
	}
	return true
}

func displayMilestonesTable(milestones []types.Milestone) {
	for _, m := range milestones {
		parts := []string{
			color.CyanString(m.ID),
			m.Title,
		}
		if m.Family != "" {
			parts = append(parts, color.MagentaString("["+m.Family+"]"))
		}
		if m.Priority != "" {
			parts = append(parts, colorizeStatus(m.Priority))
		}
		if m.CycleStatus != "" {
			parts = append(parts, colorizeStatus(m.CycleStatus))
		}
		fmt.Printf("📋 %s\n", joinParts(parts))
	}
}

func displayTasksTable(tasks []types.Task) {
	for _, task := range tasks {
		fmt.Printf("📝 %s - %s [%s] (parent: %s)\n", 
			color.YellowString(task.ID), 
			task.Title, 
			colorizeStatus(task.Status),
			color.CyanString(task.ParentID))
	}
}

func joinParts(parts []string) string {
	result := ""
	for i, part := range parts {
		if i > 0 {
			result += " "
		}
		result += part
	}
	return result
}

func truncate(s string, length int) string {
	if len(s) <= length {
		return s
	}
	return s[:length-3] + "..."
} 