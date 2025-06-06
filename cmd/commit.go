package cmd

import (
	"fmt"

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

			// Phase 1: Basic implementation
			fmt.Printf("🚧 Smart commit coming in Phase 2!\n")
			fmt.Printf("Message: %s\n", message)
			
			if c.Bool("auto") {
				fmt.Printf("Auto mode: enabled\n")
			}

			fmt.Printf("\nFor now, use regular git commit:\n")
			fmt.Printf("  git add . && git commit -m \"%s\"\n", message)

			return nil
		},
	}
} 