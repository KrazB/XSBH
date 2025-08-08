#!/usr/bin/env python3
"""
QGEN_IMPFRAG Backend API Server
=============================

Simple Flask API server to serve converted fragment files to the frontend.
"""

import os
import json
import subprocess
import tempfile
from pathlib import Path
from datetime import datetime
from flask import Flask, jsonify, send_file, request
from flask_cors import CORS
from werkzeug.utils import secure_filename

app = Flask(__name__)
CORS(app)

# Configuration
# Use absolute paths based on backend script location to avoid working directory issues
BACKEND_DIR = Path(__file__).parent
PROJECT_ROOT = BACKEND_DIR.parent
FRAGMENTS_DIR = PROJECT_ROOT / "data" / "fragments"
IFC_DIR = PROJECT_ROOT / "data" / "ifc"
CONVERTER_SCRIPT = BACKEND_DIR / "ifc_converter.js"

# Debug logging
print(f"🔍 Backend starting from: {Path.cwd()}")
print(f"📁 PROJECT_ROOT: {PROJECT_ROOT}")
print(f"📁 FRAGMENTS_DIR resolved to: {FRAGMENTS_DIR}")
print(f"📁 IFC_DIR resolved to: {IFC_DIR}")
print(f"🔧 CONVERTER_SCRIPT: {CONVERTER_SCRIPT}")
print(f"📄 Actual fragment files found: {list(FRAGMENTS_DIR.glob('*.frag'))}")
print(f"📄 Actual IFC files found: {list(IFC_DIR.glob('*.ifc'))}")

# Ensure directories exist
FRAGMENTS_DIR.mkdir(parents=True, exist_ok=True)
IFC_DIR.mkdir(parents=True, exist_ok=True)

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "service": "qgen-impfrag-backend"
    })

@app.route('/debug/paths', methods=['GET'])
def debug_paths():
    """Debug endpoint to show exactly where backend is looking"""
    fragments_files = list(FRAGMENTS_DIR.glob("*.frag"))
    return jsonify({
        "working_directory": str(Path.cwd()),
        "fragments_dir": str(FRAGMENTS_DIR),
        "fragments_dir_exists": FRAGMENTS_DIR.exists(),
        "ifc_dir": str(IFC_DIR),
        "ifc_dir_exists": IFC_DIR.exists(),
        "converter_script": str(CONVERTER_SCRIPT),
        "fragments_found": [str(f) for f in fragments_files],
        "fragments_count": len(fragments_files)
    })

@app.route('/api/fragments', methods=['GET'])
def list_fragments():
    """List available fragment files"""
    fragments = []
    
    for frag_file in FRAGMENTS_DIR.glob("*.frag"):
        stat = frag_file.stat()
        fragments.append({
            "filename": frag_file.name,
            "size_mb": round(stat.st_size / (1024 * 1024), 2),
            "created": datetime.fromtimestamp(stat.st_ctime).isoformat(),
            "modified": datetime.fromtimestamp(stat.st_mtime).isoformat(),
            "url": f"/api/fragments/{frag_file.name}"
        })
    
    return jsonify({
        "fragments": fragments,
        "count": len(fragments),
        "total_size_mb": round(sum(f["size_mb"] for f in fragments), 2)
    })

@app.route('/api/fragments/<filename>', methods=['GET'])
def serve_fragment(filename):
    """Serve a fragment file"""
    fragment_file = FRAGMENTS_DIR / filename
    
    if not fragment_file.exists():
        return jsonify({"error": f"Fragment file not found: {filename}"}), 404
    
    return send_file(fragment_file, as_attachment=False, mimetype='application/octet-stream')

@app.route('/api/ifc', methods=['GET'])
def list_ifc_files():
    """List available IFC files and their conversion status"""
    files = []
    
    for ifc_file in IFC_DIR.glob("*.ifc"):
        # Look for corresponding fragment file
        fragment_name = f"{ifc_file.stem.replace(' ', '_').replace('(', '').replace(')', '')}.frag"
        fragment_file = FRAGMENTS_DIR / fragment_name
        
        stat = ifc_file.stat()
        files.append({
            "filename": ifc_file.name,
            "size_mb": round(stat.st_size / (1024 * 1024), 2),
            "modified": datetime.fromtimestamp(stat.st_mtime).isoformat(),
            "has_fragments": fragment_file.exists(),
            "fragment_file": fragment_name if fragment_file.exists() else None,
            "fragment_size_mb": round(fragment_file.stat().st_size / (1024 * 1024), 2) if fragment_file.exists() else None
        })
    
    return jsonify({
        "ifc_files": files,
        "count": len(files),
        "total_size_mb": round(sum(f["size_mb"] for f in files), 2)
    })

@app.route('/api/status', methods=['GET'])
def get_status():
    """Get overall system status"""
    ifc_count = len(list(IFC_DIR.glob("*.ifc")))
    fragment_count = len(list(FRAGMENTS_DIR.glob("*.frag")))
    
    return jsonify({
        "status": "running",
        "ifc_files": ifc_count,
        "fragment_files": fragment_count,
        "conversion_complete": fragment_count > 0,
        "timestamp": datetime.now().isoformat()
    })

@app.route('/api/convert', methods=['POST'])
def convert_ifc():
    """Convert uploaded IFC file to fragments in memory"""
    if 'file' not in request.files:
        return jsonify({"error": "No file uploaded"}), 400
    
    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No file selected"}), 400
    
    if not file.filename.lower().endswith('.ifc'):
        return jsonify({"error": "File must be an IFC file"}), 400
    
    try:
        # Create temporary file for IFC data
        with tempfile.NamedTemporaryFile(suffix='.ifc', delete=False) as temp_ifc:
            file.save(temp_ifc.name)
            temp_ifc_path = temp_ifc.name
        
        # Generate output filename (sanitized)
        base_name = secure_filename(file.filename)
        base_name = base_name.replace('.ifc', '').replace(' ', '_')
        output_filename = f"{base_name}.frag"
        output_path = FRAGMENTS_DIR / output_filename
        
        # Run conversion using Node.js converter
        cmd = [
            'node', str(CONVERTER_SCRIPT),
            '--input', temp_ifc_path,
            '--output', str(output_path)
        ]
        
        print(f"🔄 Converting: {file.filename} -> {output_filename}")
        print(f"📄 Command: {' '.join(cmd)}")
        print(f"📁 Working directory: {Path(__file__).parent}")
        print(f"🔧 Converter script exists: {CONVERTER_SCRIPT.exists()}")
        print(f"📁 Temp IFC file: {temp_ifc_path}")
        print(f"📁 Output path: {output_path}")
        
        # Check if node is available
        try:
            node_check = subprocess.run(['node', '--version'], capture_output=True, text=True)
            print(f"🔧 Node.js version: {node_check.stdout.strip()}")
        except Exception as node_error:
            print(f"❌ Node.js not found: {node_error}")
        
        # Try with UTF-8 encoding and error handling
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, 
                                   cwd=Path(__file__).parent, encoding='utf-8', errors='replace')
        except Exception as encoding_error:
            print(f"🔄 Encoding error, trying without capture: {encoding_error}")
            # Fallback: run without capturing output to see errors directly
            result = subprocess.run(cmd, cwd=Path(__file__).parent)
            result.stdout = "No output captured"
            result.stderr = "No stderr captured"
        
        print(f"📤 Return code: {result.returncode}")
        print(f"📤 STDOUT: {result.stdout}")
        print(f"📤 STDERR: {result.stderr}")
        print(f"📁 Output file exists after conversion: {output_path.exists()}")
        
        # Clean up temporary file
        os.unlink(temp_ifc_path)
        
        if result.returncode == 0 and output_path.exists():
            # Get file stats
            stat = output_path.stat()
            return jsonify({
                "success": True,
                "message": f"Successfully converted {file.filename}",
                "output_file": output_filename,
                "size_mb": round(stat.st_size / (1024 * 1024), 2),
                "conversion_time": "< 1 minute"
            })
        else:
            error_msg = result.stderr if result.stderr else "Conversion failed"
            print(f"❌ Conversion error: {error_msg}")
            return jsonify({
                "success": False,
                "error": f"Conversion failed: {error_msg}"
            }), 500
            
    except Exception as e:
        # Clean up temp file if it exists
        if 'temp_ifc_path' in locals() and os.path.exists(temp_ifc_path):
            os.unlink(temp_ifc_path)
        return jsonify({
            "success": False,
            "error": f"Server error: {str(e)}"
        }), 500

if __name__ == '__main__':
    print("🚀 Starting QGEN_IMPFRAG Backend API Server...")
    print(f"📁 IFC Directory: {IFC_DIR}")
    print(f"📁 Fragments Directory: {FRAGMENTS_DIR}")
    print(f"🌐 Server will run on http://0.0.0.0:8111")
    
    app.run(host='0.0.0.0', port=8111, debug=True)
