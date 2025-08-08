# XSBH - Cross-platform BIM Fragment Viewer

A lightweight, containerized BIM fragment viewer for Windows, Linux, and macOS. Load and visualize .frag files with an intuitive 3D interface powered by ThatOpen Components.

## 🚀 Quick Start

### Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running
- Git (to clone this repository)

### Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/KrazB/XSBH.git
   cd XSBH
   ```

2. **Start the application:**
   ```bash
   docker-compose up -d
   ```

3. **Access the viewer:**
   Open your browser and navigate to: `http://localhost:8080`

### Usage

1. **Load Fragment Files:**
   - Click "Browse Files" to select .frag files from your computer
   - Or drag and drop .frag files directly onto the viewer
   - Use "Load Test Fragment" to try the sample building model

2. **Navigate the 3D Model:**
   - **Mouse Controls:**
     - Left click + drag: Rotate camera
     - Right click + drag: Pan view  
     - Scroll wheel: Zoom in/out
   - **Touch Controls (tablets/phones):**
     - Single finger: Rotate
     - Two fingers: Pan and zoom

3. **Model Information:**
   - View loaded fragments in the sidebar
   - Explore model properties and metadata
   - Toggle component visibility by category

### Adding Your Own Fragment Files

Place your .frag files in the `user-fragments/` directory, then restart the container:

```bash
docker-compose restart
```

## 🛠️ Advanced Configuration

### Custom Port
To run on a different port, edit `docker-compose.yml`:
```yaml
ports:
  - "3000:80"  # Change 3000 to your preferred port
```

### Data Persistence
Your uploaded fragments are automatically saved in:
- `./data/` - Application data
- `./user-fragments/` - Your fragment files

### Development Mode
For development with live reload:
```bash
docker-compose -f docker-compose.dev.yml up
```

## 📋 System Requirements

- **Minimum:** 4GB RAM, 2GB free disk space
- **Recommended:** 8GB RAM, 5GB free disk space
- **Browser:** Chrome 90+, Firefox 88+, Edge 90+, Safari 14+

## 🔧 Troubleshooting

### Application won't start
```bash
# Check Docker is running
docker --version

# View application logs
docker-compose logs xsbh-viewer

# Restart the application
docker-compose restart
```

### Can't access on localhost:8080
- Ensure port 8080 is not used by another application
- Check Windows Firewall/antivirus settings
- Try `http://127.0.0.1:8080` instead

### Fragment files won't load
- Ensure files have `.frag` extension
- Check file permissions in `user-fragments/` directory
- Maximum file size: 500MB per fragment

## 📁 Project Structure

```
XSBH/
├── frontend/          # 3D viewer interface
├── backend/           # IFC processing service  
├── data/             # Sample fragment files
├── docker/           # Configuration files
├── scripts/          # Deployment scripts
└── docker-compose.yml # Main deployment config
```

## 🔗 Related Projects

- [ThatOpen Components](https://github.com/ThatOpen/engine_components) - 3D BIM toolkit
- [Web-IFC](https://github.com/ThatOpen/engine_web-ifc) - IFC file processing

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 💬 Support

For issues and questions:
- Create an issue on GitHub
- Check the troubleshooting section above
- Review Docker Desktop documentation
