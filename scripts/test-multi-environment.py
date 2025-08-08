#!/usr/bin/env python3
"""
QGEN_IMPFRAG Multi-Environment Test Suite
=========================================

Comprehensive testing for Linux (server) and Windows (client) environments.
Tests all critical components including Docker functionality.
"""

import os
import sys
import platform
import subprocess
import json
import time
import requests
from pathlib import Path
from typing import Dict, List, Any, Optional, Tuple

# Import the environment manager
try:
    from environment_manager import EnvironmentManager
except ImportError:
    # Create a minimal EnvironmentManager for testing if import fails
    class EnvironmentManager:
        def __init__(self):
            self.platform = platform.system().lower()
            if self.platform == "darwin":
                self.platform = "macos"
            
        def detect_platform(self):
            return self.platform
            
        def get_project_root(self):
            return Path.cwd()
            
        def get_port_configuration(self):
            return {"backend": 8111, "frontend": 3111, "frontend_dev": 3111}
            
        def get_data_directories(self):
            root = self.get_project_root()
            return {
                "ifc_input": str(root / "data" / "ifc"),
                "fragments_output": str(root / "data" / "fragments"),
                "reports": str(root / "data" / "reports"),
                "logs": str(root / "backend" / "logs")
            }
            
        def get_python_configuration(self):
            return {
                "version": f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}",
                "executable": sys.executable,
                "virtual_env": os.environ.get("VIRTUAL_ENV"),
                "pip_command": "pip3" if self.platform != "windows" else "pip"
            }
            
        def get_node_configuration(self):
            return {
                "npm_command": "npm.cmd" if self.platform == "windows" else "npm",
                "node_command": "node.exe" if self.platform == "windows" else "node"
            }
            
        def create_environment_file(self):
            return ".env.auto"
            
        @property
        def environment_config(self):
            return {
                "platform": self.platform,
                "project_root": str(self.get_project_root()),
                "directories": self.get_data_directories(),
                "ports": self.get_port_configuration(),
                "python": self.get_python_configuration(),
                "node": self.get_node_configuration()
            }

class MultiEnvironmentTester:
    """Comprehensive multi-environment testing suite"""
    
    def __init__(self):
        self.env_manager = EnvironmentManager()
        self.test_results = []
        self.platform = self.env_manager.platform
        self.config = self.env_manager.environment_config
        
    def run_command(self, command: str, timeout: int = 30) -> Tuple[bool, str]:
        """Run a command and return success status and output"""
        try:
            if self.platform == "windows":
                # Windows command execution
                result = subprocess.run(
                    command,
                    shell=True,
                    capture_output=True,
                    text=True,
                    timeout=timeout
                )
            else:
                # Linux/macOS command execution
                result = subprocess.run(
                    command,
                    shell=True,
                    capture_output=True,
                    text=True,
                    timeout=timeout
                )
            
            return result.returncode == 0, result.stdout + result.stderr
        except subprocess.TimeoutExpired:
            return False, f"Command timed out after {timeout}s"
        except Exception as e:
            return False, str(e)
    
    def test_environment_detection(self) -> Dict[str, Any]:
        """Test environment detection and configuration"""
        print("🔍 Testing Environment Detection...")
        
        test_result = {
            "name": "Environment Detection",
            "status": "passed",
            "details": [],
            "errors": []
        }
        
        try:
            # Test platform detection
            detected_platform = self.env_manager.detect_platform()
            test_result["details"].append(f"Platform detected: {detected_platform}")
            
            # Test project root detection
            project_root = self.env_manager.get_project_root()
            if project_root.exists():
                test_result["details"].append(f"Project root found: {project_root}")
            else:
                test_result["errors"].append(f"Project root not found: {project_root}")
                test_result["status"] = "failed"
            
            # Test port configuration
            ports = self.env_manager.get_port_configuration()
            test_result["details"].append(f"Port config: Backend={ports['backend']}, Frontend={ports['frontend']}")
            
            # Test directory structure
            directories = self.env_manager.get_data_directories()
            missing_dirs = []
            for name, path in directories.items():
                if not Path(path).exists():
                    missing_dirs.append(f"{name}: {path}")
            
            if missing_dirs:
                test_result["details"].append(f"Missing directories: {', '.join(missing_dirs)}")
            else:
                test_result["details"].append("All required directories found")
                
        except Exception as e:
            test_result["status"] = "failed"
            test_result["errors"].append(str(e))
        
        return test_result
    
    def test_python_environment(self) -> Dict[str, Any]:
        """Test Python environment and dependencies"""
        print("🐍 Testing Python Environment...")
        
        test_result = {
            "name": "Python Environment",
            "status": "passed",
            "details": [],
            "errors": []
        }
        
        try:
            python_config = self.env_manager.get_python_configuration()
            test_result["details"].append(f"Python version: {python_config['version']}")
            test_result["details"].append(f"Python executable: {python_config['executable']}")
            
            # Test virtual environment
            if python_config["virtual_env"]:
                test_result["details"].append(f"Virtual env active: {python_config['virtual_env']}")
            else:
                test_result["details"].append("No virtual environment detected")
            
            # Test pip installation
            pip_cmd = python_config["pip_command"]
            success, output = self.run_command(f"{pip_cmd} --version")
            if success:
                test_result["details"].append(f"Pip available: {pip_cmd}")
            else:
                test_result["errors"].append(f"Pip not available: {output}")
                test_result["status"] = "failed"
            
            # Test backend dependencies
            backend_requirements = Path(self.config["project_root"]) / "backend" / "requirements.txt"
            if backend_requirements.exists():
                # Test key dependencies
                success, output = self.run_command(f"{python_config['executable']} -c \"import flask, requests\"")
                if success:
                    test_result["details"].append("Backend dependencies available")
                else:
                    test_result["errors"].append(f"Backend dependencies missing: {output}")
                    test_result["status"] = "warning"
            
        except Exception as e:
            test_result["status"] = "failed"
            test_result["errors"].append(str(e))
        
        return test_result
    
    def test_node_environment(self) -> Dict[str, Any]:
        """Test Node.js environment and dependencies"""
        print("📦 Testing Node.js Environment...")
        
        test_result = {
            "name": "Node.js Environment",
            "status": "passed",
            "details": [],
            "errors": []
        }
        
        try:
            node_config = self.env_manager.get_node_configuration()
            
            # Test Node.js availability
            success, output = self.run_command(f"{node_config['node_command']} --version")
            if success:
                test_result["details"].append(f"Node.js available: {output.strip()}")
            else:
                test_result["errors"].append(f"Node.js not available: {output}")
                test_result["status"] = "failed"
                return test_result
            
            # Test NPM availability
            success, output = self.run_command(f"{node_config['npm_command']} --version")
            if success:
                test_result["details"].append(f"NPM available: {output.strip()}")
            else:
                test_result["errors"].append(f"NPM not available: {output}")
                test_result["status"] = "failed"
                return test_result
            
            # Test frontend dependencies
            frontend_dir = Path(self.config["project_root"]) / "frontend"
            if (frontend_dir / "package.json").exists():
                if (frontend_dir / "node_modules").exists():
                    test_result["details"].append("Frontend dependencies installed")
                else:
                    test_result["details"].append("Frontend dependencies not installed")
                    test_result["status"] = "warning"
            
        except Exception as e:
            test_result["status"] = "failed"
            test_result["errors"].append(str(e))
        
        return test_result
    
    def test_docker_environment(self) -> Dict[str, Any]:
        """Test Docker environment and functionality"""
        print("🐳 Testing Docker Environment...")
        
        test_result = {
            "name": "Docker Environment", 
            "status": "passed",
            "details": [],
            "errors": []
        }
        
        try:
            # Test Docker availability
            success, output = self.run_command("docker --version")
            if success:
                test_result["details"].append(f"Docker available: {output.strip()}")
            else:
                test_result["errors"].append(f"Docker not available: {output}")
                test_result["status"] = "failed"
                return test_result
            
            # Test Docker Compose availability
            success, output = self.run_command("docker-compose --version")
            if success:
                test_result["details"].append(f"Docker Compose available: {output.strip()}")
            else:
                test_result["errors"].append(f"Docker Compose not available: {output}")
                test_result["status"] = "failed"
                return test_result
            
            # Test Docker daemon
            success, output = self.run_command("docker info", timeout=10)
            if success:
                test_result["details"].append("Docker daemon running")
            else:
                test_result["errors"].append(f"Docker daemon not running: {output}")
                test_result["status"] = "failed"
                return test_result
            
            # Test Docker Compose configuration
            project_root = Path(self.config["project_root"])
            compose_file = project_root / "docker-compose.yml"
            
            if compose_file.exists():
                os.chdir(project_root)
                success, output = self.run_command("docker-compose config", timeout=15)
                if success:
                    test_result["details"].append("Docker Compose configuration valid")
                else:
                    test_result["errors"].append(f"Docker Compose config error: {output}")
                    test_result["status"] = "failed"
            else:
                test_result["errors"].append("docker-compose.yml not found")
                test_result["status"] = "failed"
                
        except Exception as e:
            test_result["status"] = "failed"
            test_result["errors"].append(str(e))
        
        return test_result
    
    def test_application_files(self) -> Dict[str, Any]:
        """Test application file structure and integrity"""
        print("📁 Testing Application Files...")
        
        test_result = {
            "name": "Application Files",
            "status": "passed",
            "details": [],
            "errors": []
        }
        
        try:
            project_root = Path(self.config["project_root"])
            
            # Critical files to check
            critical_files = [
                "backend/app.py",
                "frontend/index.html",
                "frontend/package.json",
                "backend/requirements.txt",
                "Dockerfile",
                "docker-compose.yml"
            ]
            
            missing_files = []
            for file_path in critical_files:
                full_path = project_root / file_path
                if full_path.exists():
                    test_result["details"].append(f"✅ {file_path}")
                else:
                    missing_files.append(file_path)
                    test_result["details"].append(f"❌ {file_path}")
            
            if missing_files:
                test_result["errors"].append(f"Missing critical files: {', '.join(missing_files)}")
                test_result["status"] = "failed"
            
            # Check data directories
            data_dirs = ["data/ifc", "data/fragments", "data/reports"]
            for dir_path in data_dirs:
                full_path = project_root / dir_path
                if full_path.exists():
                    file_count = len(list(full_path.glob("*")))
                    test_result["details"].append(f"📁 {dir_path} ({file_count} files)")
                else:
                    test_result["details"].append(f"📁 {dir_path} (missing)")
                    
        except Exception as e:
            test_result["status"] = "failed"
            test_result["errors"].append(str(e))
        
        return test_result
    
    def test_backend_startup(self) -> Dict[str, Any]:
        """Test backend can start and respond"""
        print("🔧 Testing Backend Startup...")
        
        test_result = {
            "name": "Backend Startup",
            "status": "passed", 
            "details": [],
            "errors": []
        }
        
        try:
            project_root = Path(self.config["project_root"])
            backend_dir = project_root / "backend"
            
            if not (backend_dir / "app.py").exists():
                test_result["status"] = "failed"
                test_result["errors"].append("Backend app.py not found")
                return test_result
            
            # Test backend syntax
            python_cmd = self.config["python"]["executable"]
            os.chdir(backend_dir)
            
            success, output = self.run_command(f"{python_cmd} -m py_compile app.py")
            if success:
                test_result["details"].append("Backend syntax valid")
            else:
                test_result["errors"].append(f"Backend syntax error: {output}")
                test_result["status"] = "failed"
                return test_result
            
            # Try quick import test
            success, output = self.run_command(f"{python_cmd} -c \"import sys; sys.path.append('.'); from app import app; print('Import successful')\"")
            if success:
                test_result["details"].append("Backend imports successful")
            else:
                test_result["details"].append(f"Backend import issues: {output}")
                test_result["status"] = "warning"
                
        except Exception as e:
            test_result["status"] = "failed"
            test_result["errors"].append(str(e))
        
        return test_result
    
    def test_frontend_build(self) -> Dict[str, Any]:
        """Test frontend can build"""
        print("⚛️ Testing Frontend Build...")
        
        test_result = {
            "name": "Frontend Build",
            "status": "passed",
            "details": [],
            "errors": []
        }
        
        try:
            project_root = Path(self.config["project_root"])
            frontend_dir = project_root / "frontend"
            
            if not (frontend_dir / "package.json").exists():
                test_result["status"] = "failed"
                test_result["errors"].append("Frontend package.json not found")
                return test_result
            
            os.chdir(frontend_dir)
            
            # Check if dependencies are installed
            if not (frontend_dir / "node_modules").exists():
                test_result["details"].append("Installing frontend dependencies...")
                npm_cmd = self.config["node"]["npm_command"]
                success, output = self.run_command(f"{npm_cmd} install", timeout=120)
                if not success:
                    test_result["errors"].append(f"NPM install failed: {output}")
                    test_result["status"] = "failed"
                    return test_result
            
            # Test TypeScript compilation
            npm_cmd = self.config["node"]["npm_command"]
            success, output = self.run_command(f"{npm_cmd} run build", timeout=60)
            if success:
                test_result["details"].append("Frontend build successful")
                if (frontend_dir / "dist").exists():
                    test_result["details"].append("Build artifacts created")
            else:
                test_result["errors"].append(f"Frontend build failed: {output}")
                test_result["status"] = "failed"
                
        except Exception as e:
            test_result["status"] = "failed"
            test_result["errors"].append(str(e))
        
        return test_result
    
    def test_cross_platform_paths(self) -> Dict[str, Any]:
        """Test cross-platform path handling"""
        print("🛤️ Testing Cross-Platform Paths...")
        
        test_result = {
            "name": "Cross-Platform Paths",
            "status": "passed",
            "details": [],
            "errors": []
        }
        
        try:
            # Test path handling
            directories = self.env_manager.get_data_directories()
            
            for name, path_str in directories.items():
                path_obj = Path(path_str)
                
                # Test path creation and resolution
                resolved_path = path_obj.resolve()
                test_result["details"].append(f"{name}: {resolved_path}")
                
                # Test path existence or creation possibility
                try:
                    if not path_obj.exists():
                        # Try to create directory to test permissions
                        path_obj.mkdir(parents=True, exist_ok=True)
                        test_result["details"].append(f"Created directory: {name}")
                    else:
                        test_result["details"].append(f"Directory exists: {name}")
                except PermissionError:
                    test_result["errors"].append(f"Permission denied for: {name}")
                    test_result["status"] = "warning"
                except Exception as e:
                    test_result["errors"].append(f"Path error for {name}: {str(e)}")
                    test_result["status"] = "warning"
            
            # Test environment file creation
            env_file = self.env_manager.create_environment_file()
            if Path(env_file).exists():
                test_result["details"].append(f"Environment file created: {env_file}")
            else:
                test_result["errors"].append("Failed to create environment file")
                test_result["status"] = "failed"
                
        except Exception as e:
            test_result["status"] = "failed"
            test_result["errors"].append(str(e))
        
        return test_result
    
    def run_all_tests(self) -> Dict[str, Any]:
        """Run all multi-environment tests"""
        print(f"🚀 QGEN_IMPFRAG Multi-Environment Test Suite")
        print(f"Platform: {self.platform.title()}")
        print("=" * 50)
        
        # Run all tests
        tests = [
            self.test_environment_detection,
            self.test_cross_platform_paths,
            self.test_python_environment,
            self.test_node_environment,
            self.test_application_files,
            self.test_backend_startup,
            self.test_frontend_build,
            self.test_docker_environment
        ]
        
        results = []
        passed = 0
        failed = 0
        warnings = 0
        
        for test_func in tests:
            try:
                result = test_func()
                results.append(result)
                
                if result["status"] == "passed":
                    print(f"✅ {result['name']}")
                    passed += 1
                elif result["status"] == "warning":
                    print(f"⚠️ {result['name']}")
                    warnings += 1
                else:
                    print(f"❌ {result['name']}")
                    failed += 1
                    
            except Exception as e:
                result = {
                    "name": test_func.__name__,
                    "status": "failed",
                    "details": [],
                    "errors": [str(e)]
                }
                results.append(result)
                print(f"❌ {test_func.__name__} (Exception)")
                failed += 1
        
        # Summary
        total = len(tests)
        print("\n" + "=" * 50)
        print(f"Test Summary: {passed} passed, {warnings} warnings, {failed} failed out of {total}")
        
        success_rate = (passed / total) * 100
        print(f"Success Rate: {success_rate:.1f}%")
        
        # Platform-specific recommendations
        recommendations = self.generate_recommendations(results)
        
        return {
            "platform": self.platform,
            "results": results,
            "summary": {
                "total": total,
                "passed": passed,
                "warnings": warnings,
                "failed": failed,
                "success_rate": success_rate
            },
            "recommendations": recommendations,
            "config": self.config
        }
    
    def generate_recommendations(self, results: List[Dict]) -> List[str]:
        """Generate platform-specific recommendations"""
        recommendations = []
        
        # Check for common issues
        failed_tests = [r for r in results if r["status"] == "failed"]
        warning_tests = [r for r in results if r["status"] == "warning"]
        
        if self.platform == "windows":
            recommendations.append("For Windows deployment:")
            recommendations.append("- Ensure Python and Node.js are in PATH")
            recommendations.append("- Run PowerShell as Administrator if needed")
            recommendations.append("- Use setup-cross-platform.bat for automated setup")
            
            if any("Docker" in r["name"] for r in failed_tests):
                recommendations.append("- Install Docker Desktop for Windows")
                recommendations.append("- Enable WSL2 backend in Docker Desktop")
        
        elif self.platform == "linux":
            recommendations.append("For Linux deployment:")
            recommendations.append("- Use setup-cross-platform.sh for automated setup")
            recommendations.append("- Ensure user has docker group permissions")
            
            if any("Node" in r["name"] for r in failed_tests):
                recommendations.append("- Install Node.js via package manager or nvm")
        
        # General recommendations
        if failed_tests or warning_tests:
            recommendations.append("General recommendations:")
            recommendations.append("- Review the generated .env.auto file")
            recommendations.append("- Ensure all dependencies are installed")
            recommendations.append("- Check file permissions and paths")
        
        return recommendations
    
    def save_results(self, results: Dict[str, Any], filepath: Optional[str] = None) -> str:
        """Save test results to JSON file"""
        if filepath is None:
            timestamp = time.strftime("%Y%m%d_%H%M%S")
            filepath = f"multi_env_test_results_{self.platform}_{timestamp}.json"
        
        with open(filepath, 'w') as f:
            json.dump(results, f, indent=2, default=str)
        
        return filepath

def main():
    """Main function for running multi-environment tests"""
    tester = MultiEnvironmentTester()
    
    # Run all tests
    results = tester.run_all_tests()
    
    # Save results
    results_file = tester.save_results(results)
    print(f"\n📄 Results saved to: {results_file}")
    
    # Print recommendations
    if results["recommendations"]:
        print("\n💡 Recommendations:")
        for rec in results["recommendations"]:
            print(f"  {rec}")
    
    print(f"\n🎯 Multi-environment testing complete for {results['platform'].title()}")

if __name__ == "__main__":
    main()
