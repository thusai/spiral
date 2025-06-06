# Contributing to Spiral

Thank you for your interest in contributing to Spiral! This document provides guidelines and information for contributors.

## Getting Started

### Prerequisites
- Go 1.21 or later
- Git

### Development Setup

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/yourusername/spiral.git
   cd spiral
   ```
3. Install dependencies:
   ```bash
   go mod download
   ```
4. Build the project:
   ```bash
   go build -o spiral main.go
   ```
5. Run tests:
   ```bash
   go test ./...
   ```

## Development Guidelines

### Code Style

- Follow standard Go conventions (`gofmt`, `go vet`)
- Use meaningful variable and function names
- Add comments for exported functions and complex logic
- Keep functions small and focused

### Commit Messages

Use clear, descriptive commit messages:
```
[component] Brief description

Longer description if needed, explaining what and why.
```

Examples:
- `[core] Add support for nested subtask creation`
- `[cli] Improve error handling for invalid IDs`
- `[docs] Update installation instructions`

### Testing

- Write tests for new functionality
- Ensure all tests pass before submitting PR
- Include both unit tests and integration tests where applicable
- Test edge cases and error conditions

## Project Structure

```
spiral/
├── cmd/           # CLI command implementations
├── core/          # Core business logic
├── types/         # Data structures and models
├── config/        # Configuration management
├── internal/      # Internal utilities
├── main.go        # Application entry point
└── README.md      # Project documentation
```

## Feature Development

### Adding New Commands

1. Create command implementation in `cmd/`
2. Add command to main CLI setup in `main.go`
3. Update help text and documentation
4. Add tests for the new command
5. Update README.md if needed

### Extending Core Functionality

1. Add new functions to appropriate package in `core/`
2. Update relevant types in `types/`
3. Ensure backward compatibility with existing YAML files
4. Add comprehensive tests
5. Update documentation

## Submitting Changes

### Pull Request Process

1. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```
2. Make your changes
3. Add/update tests
4. Ensure all tests pass:
   ```bash
   go test ./...
   go vet ./...
   ```
5. Commit your changes
6. Push to your fork
7. Create a pull request

### Pull Request Guidelines

- Provide clear description of changes
- Reference any related issues
- Include tests for new functionality
- Update documentation if needed
- Ensure CI passes

## Reporting Issues

### Bug Reports

When reporting bugs, please include:

- Clear description of the issue
- Steps to reproduce
- Expected vs actual behavior
- Operating system and Go version
- Relevant configuration (spiral.yml snippet)

### Feature Requests

For feature requests, please:

- Describe the use case
- Explain why the feature would be valuable
- Provide examples of how it would work
- Consider implementation complexity

## Areas for Contribution

We welcome contributions in these areas:

### High Priority
- Git integration for automatic commit tagging
- Interactive TUI mode
- Performance optimizations
- Better error handling and user feedback

### Medium Priority
- Multi-project management
- Configuration validation
- Export/import functionality
- Shell completions

### Documentation
- Usage examples
- Video tutorials
- Blog posts about workflows
- API documentation

## Code Review

All submissions require code review. We may ask for changes before merging:

- Code must follow project conventions
- Tests must pass
- Documentation must be updated
- Changes should be backward compatible when possible

## Community

- Be respectful and inclusive
- Help newcomers get started
- Share knowledge and best practices
- Follow the project's code of conduct

## Questions?

If you have questions about contributing:

- Open an issue with the `question` label
- Check existing issues and documentation
- Join community discussions

Thank you for helping make Spiral better! 🌀 