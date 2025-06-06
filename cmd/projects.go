package cmd

import (
	"fmt"

	"github.com/urfave/cli/v2"
)

// ProjectsCommand returns the projects subcommand
func ProjectsCommand() *cli.Command {
	return &cli.Command{
		Name:  "projects",
		Usage: "List configured projects",
		Action: func(c *cli.Context) error {
			fmt.Println("🚧 Multi-project support coming in Phase 3!")
			fmt.Println("")
			fmt.Println("For Phase 1, spiral works with a single roadmap file:")
			fmt.Println("  spiral.yml in the current directory")
			fmt.Println("")
			fmt.Println("Use these commands to get started:")
			fmt.Println("  spiral add milestone --id=3.4 --title='My Milestone'")
			fmt.Println("  spiral show all")
			return nil
		},
	}
}

// InitCommand returns the init subcommand  
func InitCommand() *cli.Command {
	return &cli.Command{
		Name:  "init",
		Usage: "Initialize a new spiral project",
		Action: func(c *cli.Context) error {
			fmt.Println("🚧 Project initialization coming in Phase 3!")
			fmt.Println("")
			fmt.Println("For Phase 1, spiral auto-creates spiral.yml when you add your first milestone:")
			fmt.Println("  spiral add milestone --id=1.0 --title='My First Milestone'")
			return nil
		},
	}
}

// UseCommand returns the use subcommand
func UseCommand() *cli.Command {
	return &cli.Command{
		Name:  "use",
		Usage: "Switch to a different project",
		Action: func(c *cli.Context) error {
			fmt.Println("🚧 Project switching coming in Phase 3!")
			fmt.Println("")
			fmt.Println("For Phase 1, spiral works with spiral.yml in the current directory")
			return nil
		},
	}
} 