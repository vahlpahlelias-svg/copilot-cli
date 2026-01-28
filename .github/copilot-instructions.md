# GitHub Copilot CLI Repository Instructions

## Project Overview

This repository contains documentation, installation scripts, and distribution assets for **GitHub Copilot CLI** - a terminal-native AI coding assistant that brings GitHub Copilot's agentic capabilities directly to the command line.

This is primarily a **documentation and distribution repository**, not a source code repository. The actual Copilot CLI implementation is closed-source and distributed as pre-compiled binaries.

## Repository Structure

- **README.md**: Main documentation for users (installation, getting started, features)
- **changelog.md**: Version history and release notes
- **install.sh**: Installation script for Linux and macOS (Windows uses WinGet or npm)
- **LICENSE.md**: Proprietary license terms for GitHub Copilot CLI
- **.github/workflows/**: Automated workflows for issue management and distribution
- **.github/ISSUE_TEMPLATE/**: Templates for bug reports and feature requests

## Tech Stack

- **Shell scripting (Bash)**: Installation scripts
- **Markdown**: Documentation
- **GitHub Actions**: CI/CD and issue automation

## Content Guidelines

### Documentation Standards

- **Clarity first**: Write for users who may be unfamiliar with Copilot CLI
- **Keep README current**: Always update README.md when features change
- **Version alignment**: Ensure changelog.md reflects all releases accurately
- **Link to official docs**: Reference https://docs.github.com/copilot/concepts/agents/about-copilot-cli for detailed information

### Writing Style

- Use clear, concise language
- Include code examples for installation commands
- Maintain consistent formatting with existing documentation
- Use emoji sparingly and only where they add clarity (e.g., 🚀 for Getting Started)

### Installation Script Maintenance

- **Test on all platforms**: Verify install.sh works on Linux, macOS, and properly handles Windows
- **Error handling**: Always provide clear error messages and fallback instructions
- **Platform detection**: Use robust platform and architecture detection
- **Idempotency**: Script should be safe to run multiple times

## Issue and PR Management

### Issue Triage

- Bug reports require reproduction steps and environment details
- Feature requests should describe the user problem, not just the solution
- Invalid/spam issues should be closed with appropriate workflow automation

### Automated Workflows

This repository uses several GitHub Actions workflows for issue management:
- **triage-issues.yml**: Auto-labels new issues
- **close-invalid.yml**: Closes improperly formatted issues
- **stale-issues.yml**: Manages inactive issues
- **no-response.yml**: Closes issues awaiting user response

## Boundaries and Restrictions

### What NOT to do:

- **Never modify LICENSE.md** without explicit approval from legal/product teams
- **Never add source code**: This is a docs/distribution repo only
- **Never commit credentials or tokens**: Even in examples or documentation
- **Never change installation URLs** without verifying they point to official GitHub infrastructure
- **Never remove platform support** (Linux/macOS/Windows) without product team approval
- **Do not make breaking changes** to install.sh that could affect existing users

### What TO do:

- Keep documentation accurate and up-to-date
- Improve clarity in installation instructions
- Fix typos and formatting issues
- Update changelog.md for new releases
- Enhance GitHub Actions workflows for better issue management
- Add helpful examples and troubleshooting guidance

## Release Process

When updating changelog.md for new versions:
1. Follow the existing version format: `## [version] - YYYY-MM-DD`
2. Categorize changes: Added, Changed, Fixed, Removed
3. Use clear, user-facing language (not internal jargon)
4. Link to relevant documentation or issues where applicable

## Support and Feedback

- Users should be directed to official documentation at https://docs.github.com/copilot/concepts/agents/about-copilot-cli
- Bug reports go through GitHub Issues using the provided templates
- Feature requests should describe user pain points and use cases
- The `/feedback` command in the CLI allows confidential feedback submission

## Quality Standards

- All Markdown files should be properly formatted
- Links should be tested and valid
- Shell scripts should follow ShellCheck recommendations
- Documentation should be accessible and inclusive
