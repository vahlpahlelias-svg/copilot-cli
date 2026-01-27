# GitHub Copilot CLI (Public Preview)

The power of GitHub Copilot, now in your terminal.

GitHub Copilot CLI brings AI-powered coding assistance directly to your command line, enabling you to build, debug, and understand code through natural language conversations. Powered by the same agentic harness as GitHub's Copilot coding agent, it provides intelligent assistance while staying deeply integrated with your GitHub workflow.

See [our official documentation](https://docs.github.com/copilot/concepts/agents/about-copilot-cli) for more information.

![Image of the splash screen for the Copilot CLI](https://github.com/user-attachments/assets/f40aa23d-09dd-499e-9457-1d57d3368887)


## 🚀 Introduction and Overview

We're bringing the power of GitHub Copilot coding agent directly to your terminal. With GitHub Copilot CLI, you can work locally and synchronously with an AI agent that understands your code and GitHub context.

- **Terminal-native development:** Work with Copilot coding agent directly in your command line — no context switching required.
- **GitHub integration out of the box:** Access your repositories, issues, and pull requests using natural language, all authenticated with your existing GitHub account.
- **Agentic capabilities:** Build, edit, debug, and refactor code with an AI collaborator that can plan and execute complex tasks.
- **MCP-powered extensibility:** Take advantage of the fact that the coding agent ships with GitHub's MCP server by default and supports custom MCP servers to extend capabilities.
- **Full control:** Preview every action before execution — nothing happens without your explicit approval.

We're still early in our journey, but with your feedback, we're rapidly iterating to make the GitHub Copilot CLI the best possible companion in your terminal.

## 📦 Getting Started

### Supported Platforms

- **Linux**
- **macOS**
- **Windows**

### Prerequisites

- (On Windows) **PowerShell** v6 or higher
- An **active Copilot subscription**. See [Copilot plans](https://github.com/features/copilot/plans?ref_cta=Copilot+plans+signup&ref_loc=install-copilot-cli&ref_page=docs).

If you have access to GitHub Copilot via your organization or enterprise, you cannot use GitHub Copilot CLI if your organization owner or enterprise administrator has disabled it in the organization or enterprise settings. See [Managing policies and features for GitHub Copilot in your organization](http://docs.github.com/copilot/managing-copilot/managing-github-copilot-in-your-organization/managing-github-copilot-features-in-your-organization/managing-policies-for-copilot-in-your-organization) for more information.

### Installation

Install with [WinGet](https://github.com/microsoft/winget-cli) (Windows):

```bash
winget install GitHub.Copilot
```

```bash
winget install GitHub.Copilot.Prerelease
```

Install with [Homebrew](https://formulae.brew.sh/cask/copilot-cli) (macOS and Linux):

```bash
brew install copilot-cli
```

```bash
brew install copilot-cli@prerelease
```

Install with [npm](https://www.npmjs.com/package/@github/copilot) (macOS, Linux, and Windows):

```bash
npm install -g @github/copilot
```

```bash
npm install -g @github/copilot@prerelease
```

Install with the install script (macOS and Linux):

```bash
curl -fsSL https://gh.io/copilot-install | bash
```

Or

```bash
wget -qO- https://gh.io/copilot-install | bash
```

Use `| sudo bash` to run as root and install to `/usr/local/bin`.

Set `PREFIX` to install to `$PREFIX/bin/` directory. Defaults to `/usr/local`
when run as root or `$HOME/.local` when run as a non-root user.

Set `VERSION` to install a specific version. Defaults to the latest version.

For example, to install version `v0.0.369` to a custom directory:

```bash
curl -fsSL https://gh.io/copilot-install | VERSION="v0.0.369" PREFIX="$HOME/custom" bash
```

### Launching the CLI

```bash
copilot
```

On first launch, you'll be greeted with our adorable animated banner! If you'd like to see this banner again, launch `copilot` with the `--banner` flag.

If you're not currently logged in to GitHub, you'll be prompted to use the `/login` slash command. Enter this command and follow the on-screen instructions to authenticate.

#### Authenticate with a Personal Access Token (PAT)

You can also authenticate using a fine-grained PAT with the "Copilot Requests" permission enabled.

1. Visit https://github.com/settings/personal-access-tokens/new
2. Under "Permissions," click "add permissions" and select "Copilot Requests"
3. Generate your token
4. Add the token to your environment via the environment variable `GH_TOKEN` or `GITHUB_TOKEN` (in order of precedence)

### Using the CLI

Launch `copilot` in a folder that contains code you want to work with.

By default, `copilot` utilizes Claude Sonnet 4.5. Run the `/model` slash command to choose from other available models, including Claude Sonnet 4 and GPT-5.

Each time you submit a prompt to GitHub Copilot CLI, your monthly quota of premium requests is reduced by one. For information about premium requests, see [About premium requests](https://docs.github.com/copilot/managing-copilot/monitoring-usage-and-entitlements/about-premium-requests).

For more information about how to use the GitHub Copilot CLI, see [our official documentation](https://docs.github.com/copilot/concepts/agents/about-copilot-cli).

## 🔌 API Reference and Advanced Features

### Slash Commands

GitHub Copilot CLI provides powerful slash commands to control your coding session:

#### `/model` - Model Management

List and select from available AI models directly from your terminal:

```bash
/model
```

Available models include:
- Claude Sonnet 4.5 (default)
- Claude Sonnet 4
- GPT-5
- GPT-4.1

If a selected model is disabled by your organization's policy, Copilot will prompt you to request access.

#### `/compact` - Context Management

Manage your session's context window to maintain long-running conversations:

```bash
/compact
```

Copilot CLI automatically compacts your session history when you reach 95% of the token limit. You can also manually trigger compaction to optimize context usage and preserve important conversation history.

Press `Escape` to cancel a manual compact operation.

#### `/plugin` - Plugin Management

Manage plugins and MCP (Model Context Protocol) server integration:

```bash
/plugin                 # View installed plugins
/plugin install <name>  # Install a plugin
/plugin update          # Update installed plugins
/plugin uninstall <name> # Uninstall a plugin
```

Plugins can bundle MCP servers that load automatically when installed, extending Copilot's capabilities with custom tools and integrations.

#### `/mcp show` - MCP Server Discovery

List all configured MCP servers, including those provided by plugins:

```bash
/mcp show
```

This command displays all available MCP servers and their current status.

#### Session Management Commands

- `/session` - Manage and switch between sessions
- `/session rename` or `/rename` - Rename the current session
- `/resume` - Switch to a different session
- `/diff` - Review changes made during the current session
- `/review` - Analyze code changes with AI-powered review

### Command-Line Flags

Control Copilot's behavior with these command-line flags:

#### Tool Access Control

Restrict or allow specific tools during your session:

```bash
copilot --available-tools <tool1,tool2>   # Allowlist specific tools
copilot --excluded-tools <tool1,tool2>    # Denylist specific tools
```

These flags are useful for restricting agent capabilities during audits or enforcing security policies.

#### GitHub MCP Tools

Enable read-write GitHub operations:

```bash
copilot --enable-all-github-mcp-tools
```

This flag enables full read-write access to GitHub repositories, issues, and pull requests through MCP tools.

#### Session Persistence

Enable infinite sessions with automatic context management:

```bash
copilot --infinite-session
```

This preserves conversation context across CLI invocations through automatic compaction checkpoints.

#### Automation and Scripting

For CI/CD and automation workflows:

```bash
copilot --silent                        # Minimal output for scripts
copilot --share                         # Generate shareable session link
copilot --additional-mcp-config <path>  # Load additional MCP configuration
```

#### CI/CD Authentication

Configure authentication for automated environments:

```bash
export GITHUB_ASKPASS=/path/to/token-script
```

This environment variable specifies where authentication tokens are retrieved for Copilot integrations in pipelines.

### Built-in Specialized Agents

Copilot CLI includes specialized agents for common development tasks. These agents can work autonomously or be explicitly invoked:

#### `explore` Agent

Fast codebase analysis and navigation:

```bash
# Copilot automatically delegates exploration tasks
# Or explicitly delegate: "explore the authentication logic"
```

The explore agent quickly searches files, understands code patterns, and answers questions about your codebase.

#### `task` Agent

Execute builds, tests, and other commands with intelligent output summarization:

```bash
# Copilot automatically runs tests and builds
# Example: "run the test suite"
```

The task agent runs commands, shows brief summaries on success, and full output (including stack traces) on failure.

#### `plan` Agent

Generate implementation plans based on your codebase structure:

```bash
# Enable plan mode
# Example: "create a plan for adding user authentication"
```

View detailed implementation plans in a dedicated panel before executing changes.

#### `code-review` Agent

AI-powered code review that surfaces high-signal issues:

```bash
/review
```

The code-review agent analyzes staged/unstaged changes and branch diffs, focusing only on bugs, security vulnerabilities, and logic errors—never style or formatting.

Copilot can automatically delegate tasks among these agents and run them in parallel for efficiency.

### Shortcuts and Productivity Features

- **Delegation shortcut:** Use `&` prefix to run prompts in background (equivalent to `/delegate`)
  ```bash
  & run all tests and report back
  ```

- **Shell commands:** Execute shell commands with `!` prefix
  ```bash
  ! git status
  ```

- **Undo changes:** Press `Esc-Esc` to undo file changes to any previous snapshot

- **Skill invocation:** Invoke custom skills using slash commands
  ```bash
  /skill-name
  ```

### GitHub Copilot SDK

The GitHub Copilot SDK (technical preview) exposes the CLI's agent engine as a programmable API for Node.js, Python, Go, and .NET applications.

#### Key SDK Features

- **Session Management:** Create, manage, and compact sessions programmatically
- **Model Selection:** Choose and configure AI models via JSON-RPC endpoints
- **Tool Invocation:** Execute tools and handle responses
- **Context-Aware Workflows:** Build multi-turn conversations with persistent context
- **Subagent Capabilities:** Assign specific tool access to different agents
- **Infinite Sessions:** Preserve memory and context across application lifecycle

#### SDK Resources

- [GitHub Copilot SDK Repository](https://github.com/github/copilot-sdk)
- [SDK Documentation](https://github.blog/news-insights/company-news/build-an-agent-into-any-app-with-the-github-copilot-sdk/)
- SDK packages available for: Node.js, Python, Go, .NET

For detailed SDK integration examples and API reference, visit the official repository.

## 📢 Feedback and Participation

We're excited to have you join us early in the Copilot CLI journey.

This is an early-stage preview, and we're building quickly. Expect frequent updates--please keep your client up to date for the latest features and fixes!

Your insights are invaluable! Open issue in this repo, join Discussions, and run `/feedback` from the CLI to submit a confidential feedback survey!
