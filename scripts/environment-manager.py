#!/usr/bin/env python3
"""
QGEN_IMPFRAG Environment Detection and Configuration
===================================================

Automatically detects the operating system and configures paths,
ports, and environment variables for optimal cross-platform operation.

Supports:
- Linux (current server environment)
- Windows (client laptop/PC deployment)
- macOS (developer workstations)
"""

import os
import sys
import platform
import json
from pathlib import Path
from typing import Dict, Any, Optional

class EnvironmentManager:
    """Cross-platform environment configuration manager"""
    
    def __init__(self):
        self.platform = self.detect_platform()
        self.base_config = self.load_base_config()
        self.environment_config = self.get_environment_config()
    
    def detect_platform(self) -> str:
        """Detect the current operating system"""
        system = platform.system().lower()
        
        if system == "linux":
            return "linux"
        elif system == "windows":
            return "windows"
        elif system == "darwin":
            return "macos"
        else:
            return "unknown"
    
    def get_project_root(self) -> Path:
        """Get project root directory with cross-platform compatibility"""
        if self.platform == "windows":
            # Windows: Use current working directory or detect from script location
            if "QGEN_IMPFRAG_ROOT" in os.environ:
                return Path(os.environ["QGEN_IMPFRAG_ROOT"])
            return Path.cwd()
        else:
            # Linux/macOS: Use the established path or auto-detect
            linux_path = Path("/data/XVUE/XQG4_AXIS/QGEN_IMPFRAG")
            if linux_path.exists():
                return linux_path
            return Path.cwd()
    
    def get_data_directories(self) -> Dict[str, str]:
        """Get data directory paths for current platform"""
        project_root = self.get_project_root()
        
        return {
            "ifc_input": str(project_root / "data" / "ifc"),
            "fragments_output": str(project_root / "data" / "fragments"),
            "reports": str(project_root / "data" / "reports"),
            "logs": str(project_root / "backend" / "logs"),
            "temp": str(project_root / "tmp") if self.platform != "windows" else str(project_root / "temp")
        }
    
    def get_port_configuration(self) -> Dict[str, int]:
        """Get port configuration for current environment"""
        # Standard ports that work across platforms
        ports = {
            "backend": 8111,
            "frontend": 3111,
            "frontend_dev": 3111
        }
        
        # Check for environment variable overrides
        if "QGEN_BACKEND_PORT" in os.environ:
            ports["backend"] = int(os.environ["QGEN_BACKEND_PORT"])
        
        if "QGEN_FRONTEND_PORT" in os.environ:
            ports["frontend"] = int(os.environ["QGEN_FRONTEND_PORT"])
            ports["frontend_dev"] = int(os.environ["QGEN_FRONTEND_PORT"])
        
        return ports
    
    def get_docker_configuration(self) -> Dict[str, Any]:
        """Get Docker configuration for current platform"""
        config = {
            "enabled": self.is_docker_available(),
            "compose_file": "docker-compose.yml",
            "platform_specific": {}
        }
        
        if self.platform == "windows":
            config["platform_specific"] = {
                "volume_mount_style": "windows",
                "line_endings": "crlf",
                "shell": "powershell"
            }
        else:
            config["platform_specific"] = {
                "volume_mount_style": "unix",
                "line_endings": "lf", 
                "shell": "bash"
            }
        
        return config
    
    def is_docker_available(self) -> bool:
        """Check if Docker is available on the system"""
        try:
            import subprocess
            result = subprocess.run(
                ["docker", "--version"],
                capture_output=True,
                text=True,
                timeout=5
            )
            return result.returncode == 0
        except:
            return False
    
    def get_python_configuration(self) -> Dict[str, Any]:
        """Get Python configuration for current platform"""
        return {
            "version": f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}",
            "executable": sys.executable,
            "platform": self.platform,
            "virtual_env": self.get_virtual_env_path(),
            "pip_command": self.get_pip_command()
        }
    
    def get_virtual_env_path(self) -> Optional[str]:
        """Get virtual environment path if available"""
        if "VIRTUAL_ENV" in os.environ:
            return os.environ["VIRTUAL_ENV"]
        
        # Check for common virtual env locations
        project_root = self.get_project_root()
        
        potential_paths = [
            project_root / "backend" / "venv",
            project_root / "venv",
            project_root / ".venv"
        ]
        
        for path in potential_paths:
            if path.exists():
                return str(path)
        
        return None
    
    def get_pip_command(self) -> str:
        """Get appropriate pip command for current platform"""
        venv_path = self.get_virtual_env_path()
        
        if venv_path:
            if self.platform == "windows":
                return f"{venv_path}\\Scripts\\pip.exe"
            else:
                return f"{venv_path}/bin/pip"
        else:
            return "pip3" if self.platform != "windows" else "pip"
    
    def get_node_configuration(self) -> Dict[str, Any]:
        """Get Node.js configuration for current platform"""
        return {
            "npm_command": "npm.cmd" if self.platform == "windows" else "npm",
            "node_command": "node.exe" if self.platform == "windows" else "node",
            "package_manager": "npm"  # Could be extended to support yarn, pnpm
        }
    
    def load_base_config(self) -> Dict[str, Any]:
        """Load base configuration"""
        return {
            "app_name": "QGEN_IMPFRAG",
            "version": "1.0.0",
            "description": "IFC Processing and Fragment Viewer Application",
            "maintainer": "XQG4_AXIS Team"
        }
    
    def get_environment_config(self) -> Dict[str, Any]:
        """Get complete environment configuration"""
        return {
            "platform": self.platform,
            "project_root": str(self.get_project_root()),
            "directories": self.get_data_directories(),
            "ports": self.get_port_configuration(),
            "docker": self.get_docker_configuration(),
            "python": self.get_python_configuration(),
            "node": self.get_node_configuration(),
            "base": self.base_config
        }
    
    def create_environment_file(self, output_path: Optional[str] = None) -> str:
        """Create .env file for current environment"""
        if output_path is None:
            output_path = self.get_project_root() / ".env.auto"
        
        config = self.environment_config
        
        env_content = f"""# QGEN_IMPFRAG Auto-Generated Environment Configuration
# Generated for: {config['platform']} platform
# Timestamp: {__import__('datetime').datetime.now().isoformat()}

# Platform Detection
QGEN_PLATFORM={config['platform']}
QGEN_PROJECT_ROOT={config['project_root']}

# Port Configuration
QGEN_BACKEND_PORT={config['ports']['backend']}
QGEN_FRONTEND_PORT={config['ports']['frontend']}

# Directory Paths
QGEN_IFC_INPUT_DIR={config['directories']['ifc_input']}
QGEN_FRAGMENTS_OUTPUT_DIR={config['directories']['fragments_output']}
QGEN_REPORTS_DIR={config['directories']['reports']}
QGEN_LOGS_DIR={config['directories']['logs']}

# Python Configuration
QGEN_PYTHON_EXECUTABLE={config['python']['executable']}
QGEN_PIP_COMMAND={config['python']['pip_command']}

# Node.js Configuration
QGEN_NPM_COMMAND={config['node']['npm_command']}
QGEN_NODE_COMMAND={config['node']['node_command']}

# Docker Configuration
QGEN_DOCKER_ENABLED={str(config['docker']['enabled']).lower()}
QGEN_DOCKER_COMPOSE_FILE={config['docker']['compose_file']}

# API URLs (auto-configured based on ports)
VITE_BACKEND_URL=http://localhost:{config['ports']['backend']}
VITE_FRONTEND_URL=http://localhost:{config['ports']['frontend']}

# Security Configuration
QGEN_CORS_ORIGINS=http://localhost:{config['ports']['frontend']},http://localhost:{config['ports']['frontend_dev']}
"""
        
        with open(output_path, 'w') as f:
            f.write(env_content)
        
        return str(output_path)
    
    def print_configuration_summary(self):
        """Print a summary of the detected configuration"""
        config = self.environment_config
        
        print("🔍 QGEN_IMPFRAG Environment Configuration")
        print("=" * 50)
        print(f"Platform: {config['platform'].title()}")
        print(f"Project Root: {config['project_root']}")
        print(f"Backend Port: {config['ports']['backend']}")
        print(f"Frontend Port: {config['ports']['frontend']}")
        print(f"Docker Available: {'✅ Yes' if config['docker']['enabled'] else '❌ No'}")
        print(f"Python: {config['python']['version']} ({config['python']['executable']})")
        print(f"Virtual Env: {'✅ Active' if config['python']['virtual_env'] else '❌ Not found'}")
        print("")
        print("📁 Data Directories:")
        for name, path in config['directories'].items():
            exists = "✅" if Path(path).exists() else "❌"
            print(f"  {name}: {exists} {path}")
        print("")

def main():
    """Main function for command-line usage"""
    env_manager = EnvironmentManager()
    
    if len(sys.argv) > 1:
        if sys.argv[1] == "--config":
            env_manager.print_configuration_summary()
        elif sys.argv[1] == "--env":
            env_file = env_manager.create_environment_file()
            print(f"✅ Environment file created: {env_file}")
        elif sys.argv[1] == "--json":
            print(json.dumps(env_manager.environment_config, indent=2))
    else:
        env_manager.print_configuration_summary()
        env_file = env_manager.create_environment_file()
        print(f"✅ Environment file created: {env_file}")

if __name__ == "__main__":
    main()
