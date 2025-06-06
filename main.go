package main

import (
	"fmt"
	"os"

	"github.com/thusai/spiral/cmd"
	"github.com/urfave/cli/v2"
)

func main() {
	app := &cli.App{
		Name:     "spiral",
		Usage:    "Git-native roadmap management",
		Version:  "2.0.0-beta",
		Authors: []*cli.Author{
			{
				Name:  "Spiral Team",
				Email: "hello@spiral.dev",
			},
		},
		Description: `Spiral is a git-native roadmap tool that adapts to how you actually develop.
		
🚀 Organic workflow: Commit first, roadmap follows automatically
🎯 Smart context: Auto-creates milestones from your commit messages  
🔗 Git-native: Uses actual commit history as source of truth
⚡ Zero friction: One command commits and tracks everything`,
		Commands: []*cli.Command{
			cmd.ShowCommand(),
			cmd.AddCommand(),
			cmd.ContextCommand(),
			cmd.CommitCommand(),
			cmd.ProjectsCommand(),
			cmd.InitCommand(),
			cmd.UseCommand(),
		},
		Action: func(c *cli.Context) error {
			// Default action when no subcommand is provided
			return cmd.DefaultAction(c)
		},
	}

	if err := app.Run(os.Args); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
} 