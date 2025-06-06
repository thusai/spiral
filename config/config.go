package config

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"

	"github.com/thusai/spiral/types"
)

const (
	DefaultConfigDir = ".spiral"
	ContextFile     = "context.json"
	ConfigFile      = "config.json"
)

// LoadContext loads the current working context
func LoadContext() (types.Context, error) {
	contextPath := filepath.Join(DefaultConfigDir, ContextFile)
	
	// Return empty context if file doesn't exist
	if _, err := os.Stat(contextPath); os.IsNotExist(err) {
		return types.Context{}, nil
	}
	
	data, err := os.ReadFile(contextPath)
	if err != nil {
		return types.Context{}, fmt.Errorf("failed to read context file: %w", err)
	}
	
	var context types.Context
	if err := json.Unmarshal(data, &context); err != nil {
		return types.Context{}, fmt.Errorf("failed to parse context file: %w", err)
	}
	
	return context, nil
}

// SaveContext saves the current working context
func SaveContext(context types.Context) error {
	// Ensure config directory exists
	if err := os.MkdirAll(DefaultConfigDir, 0755); err != nil {
		return fmt.Errorf("failed to create config directory: %w", err)
	}
	
	data, err := json.MarshalIndent(context, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal context: %w", err)
	}
	
	contextPath := filepath.Join(DefaultConfigDir, ContextFile)
	return atomicWriteFile(contextPath, data)
}



// ClearContext clears the current working context
func ClearContext() error {
	contextPath := filepath.Join(DefaultConfigDir, ContextFile)
	
	// Remove file if it exists
	if _, err := os.Stat(contextPath); err == nil {
		return os.Remove(contextPath)
	}
	
	return nil
}



// EnsureConfigDirectory ensures the spiral config directory exists
func EnsureConfigDirectory() error {
	return os.MkdirAll(DefaultConfigDir, 0755)
}

// GetDefaultRoadmapPath returns the default roadmap file path
func GetDefaultRoadmapPath() string {
	return "spiral.yml"
}

// FindRoadmapFile looks for roadmap files in the current directory
func FindRoadmapFile() (string, error) {
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
	
	// Return default if none found
	return "spiral.yml", nil
}

// atomicWriteFile writes data to a file atomically using temp file + rename
func atomicWriteFile(filePath string, data []byte) error {
	// Create directory if it doesn't exist
	dir := filepath.Dir(filePath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("failed to create directory: %w", err)
	}

	// Create temporary file in the same directory
	tempFile, err := os.CreateTemp(dir, ".spiral-temp-*")
	if err != nil {
		return fmt.Errorf("failed to create temp file: %w", err)
	}
	tempPath := tempFile.Name()

	// Clean up temp file on error
	defer func() {
		if tempFile != nil {
			tempFile.Close()
			os.Remove(tempPath)
		}
	}()

	// Write data to temp file
	if _, err := tempFile.Write(data); err != nil {
		return fmt.Errorf("failed to write temp file: %w", err)
	}

	// Close temp file
	if err := tempFile.Close(); err != nil {
		return fmt.Errorf("failed to close temp file: %w", err)
	}
	tempFile = nil // Prevent cleanup

	// Atomically rename temp file to target
	if err := os.Rename(tempPath, filePath); err != nil {
		os.Remove(tempPath) // Clean up on rename failure
		return fmt.Errorf("failed to rename temp file: %w", err)
	}

	return nil
} 