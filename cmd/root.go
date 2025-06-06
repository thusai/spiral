package cmd

import (
	"fmt"
	"path/filepath"

	"github.com/urfave/cli/v2"
)

// DefaultAction handles the case when spiral is called without subcommands
func DefaultAction(c *cli.Context) error {
	// Show current config info
	fmt.Println("🎯 Welcome to Spiral!")
	fmt.Printf("📋 Active Roadmap: %s\n", "spiral.yml")
	fmt.Println("")
	fmt.Println("Quick actions:")
	fmt.Println("  spiral show all                  # View roadmap")
	fmt.Println("  spiral add milestone --title='My Feature' --family=D")
	fmt.Println("  spiral context --id=D1           # Set working context")
	fmt.Println("")
	fmt.Println("📁 Available YAML files:")
	return listYAMLFiles()
}

// listYAMLFiles lists YAML files in the current directory
func listYAMLFiles() error {
	files, err := filepath.Glob("*.yml")
	if err != nil {
		return err
	}
	
	yamlFiles, err := filepath.Glob("*.yaml")
	if err != nil {
		return err
	}
	
	files = append(files, yamlFiles...)
	
	if len(files) == 0 {
		fmt.Println("  No YAML files found in current directory")
		fmt.Println("  Use 'spiral init <project-name>' to create a new project")
		return nil
	}
	
	for _, file := range files {
		fmt.Printf("  %s\n", file)
	}
	fmt.Println("")
	fmt.Println("Use 'spiral init <project-name> <yaml-file>' to get started")
	
	return nil
} 