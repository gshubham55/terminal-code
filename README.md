# Terminal Code

> Single binary distribution for CloudIDE Pro - like `claude-code` but for terminal IDEs

[![NPM Version](https://img.shields.io/npm/v/@terminal-code/cli)](https://www.npmjs.com/package/@terminal-code/cli)
[![Downloads](https://img.shields.io/github/downloads/terminal-code/terminal-code/total)](https://github.com/terminal-code/terminal-code/releases)
[![License](https://img.shields.io/npm/l/@terminal-code/cli)](https://www.npmjs.com/package/@terminal-code/cli)

## 🚀 Quick Install

```bash
npm install -g @terminal-code/cli
terminal-code
```

That's it! No complex setup, no dependencies to manage.

## ✨ What You Get

- 🖥️ **Full VS Code IDE** in your browser
- 👥 **Multi-workspace management** - isolated development environments  
- 🔐 **User authentication** - secure workspace isolation
- 📊 **Workspace analytics** - track usage and activity
- 🔄 **Git integration** - clone repos directly into workspaces
- 🌐 **Flexible access** - ngrok tunneling or direct domain
- 📦 **Truly standalone** - downloads runtime on first use, then works offline

## 🎯 Perfect For

- **Remote development** - code from anywhere with just a browser
- **Team environments** - shared development infrastructure
- **Client demos** - instant development environment setup
- **Education** - no-setup coding environment for students
- **Consulting** - portable development environment

## 📖 Usage

```bash
# Basic usage (auto-detects project)
terminal-code

# With custom config
terminal-code --config my-config.yaml

# Set specific project directory
terminal-code --project-root /path/to/project

# Show help
terminal-code --help
```

## 🔧 Configuration

Create a YAML config file:

### ngrok Mode (Tunneled Access)
```yaml
instance_name: "my-dev-env"
starting_port: 8080
ngrok_domain: "your-domain.ngrok-free.app"
```

### Machine Domain Mode (Direct Access)
```yaml
instance_name: "production"
starting_port: 8080  
machine_domain: "ide.yourdomain.com"
```

## ⚡ Architecture

Terminal Code orchestrates multiple services:

```
🖥️  VS Code Server (browser-based IDE)
    ↳ Multiple isolated workspaces
    ↳ Per-workspace VS Code instances
    ↳ Custom CloudIDE Pro extensions

🐍 Python Backend (FastAPI)
    ↳ Workspace management API
    ↳ User authentication
    ↳ Git repository integration
    ↳ Process orchestration

🔀 Caddy Proxy (reverse proxy)
    ↳ Routes /workspace/{id}/ to appropriate VS Code server
    ↳ Handles SSL termination
    ↳ Load balancing

🌐 ngrok Tunnel (optional)
    ↳ Public internet access
    ↳ HTTPS termination
    ↳ Webhook endpoints
```

## 🔍 How It Works

1. **Install**: `npm install -g @terminal-code/cli` (downloads ~10MB orchestrator)
2. **First Run**: Downloads runtime components (~100MB total, happens once)
3. **Subsequent Runs**: Instant startup, everything cached locally
4. **Workspace Creation**: Each workspace gets dedicated VS Code server
5. **Access**: Open browser to your configured URL

## 📊 System Requirements

- **OS**: Linux, macOS, or Windows
- **Memory**: 2GB+ recommended (scales with number of workspaces)
- **Disk**: 500MB for runtime + workspace storage
- **Network**: Internet connection for initial setup and ngrok mode

## 🛠️ Advanced Configuration

### Port Configuration
```yaml
starting_port: 8080          # Main VS Code port
workspace_start_port: 12001  # First workspace VS Code port  
workspace_port_range: 100    # Max concurrent workspaces
caddy_port: 8082            # Reverse proxy port (ngrok mode)
```

### Data Storage
```yaml
data_dir: "./terminal-code-data"  # Workspace storage location
database_url: "sqlite:///terminal-code-data/cloudide.db"  # SQLite database
```

### Access Modes
```yaml
# Option 1: ngrok tunneling (easiest)
ngrok_domain: "abc123.ngrok-free.app"

# Option 2: Direct domain (requires DNS + SSL setup)
machine_domain: "ide.yourdomain.com"  
```

## 🔧 Troubleshooting

### Common Issues

**VS Code not loading:**
- Check if port is already in use
- Verify workspace directory permissions
- Look at logs: `~/.terminal-code/logs/`

**Backend API errors:**
- Ensure data directory is writable  
- Check database connectivity
- Verify config file syntax

**Proxy issues:**
- Confirm Caddy is not blocked by firewall
- Check domain DNS settings (machine domain mode)
- Verify ngrok authentication (ngrok mode)

### Debug Mode
```bash
terminal-code --debug --config your-config.yaml
```

### Logs Location
```
~/.terminal-code/logs/
├── backend.log     # Python API logs
├── vscode.log      # VS Code server logs  
└── caddy.log       # Reverse proxy logs
```

## 🔄 Updates

Terminal Code automatically checks for updates on startup. To force update:

```bash
terminal-code --update
```

Runtime components are updated independently of the main CLI.

## 🤝 Support

- 📖 **Documentation**: [GitHub Wiki](https://github.com/terminal-code/terminal-code/wiki)
- 🐛 **Issues**: [GitHub Issues](https://github.com/terminal-code/terminal-code/issues)  
- 💬 **Discussions**: [GitHub Discussions](https://github.com/terminal-code/terminal-code/discussions)

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

**Built with ❤️ for developers who need powerful, accessible development environments**