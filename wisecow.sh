#!/bin/bash

# Wisecow Application
# A simple web server that serves fortune cookies with cowsay

# Default port
PORT=${PORT:-4499}

# Function to generate fortune with cowsay
generate_fortune() {
    if command -v fortune >/dev/null 2>&1 && command -v cowsay >/dev/null 2>&1; then
        fortune | cowsay
    else
        cowsay "Hello! Fortune and cowsay are not installed. Please install them for full functionality."
    fi
}

# Function to serve HTTP responses
serve_request() {
    # Generate HTML response
    local fortune_output
    fortune_output="$(generate_fortune)"
    
    # Escape HTML characters in fortune output
    fortune_output=$(echo "$fortune_output" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')
    
    # Calculate content length
    local html_content="<!DOCTYPE html>
<html>
<head>
    <title>Wisecow Application</title>
    <meta charset=\"UTF-8\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
    <style>
        body {
            font-family: 'Courier New', monospace;
            background-color: #f0f0f0;
            margin: 0;
            padding: 20px;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
        }
        .container {
            background-color: white;
            border-radius: 10px;
            padding: 30px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            max-width: 800px;
            text-align: center;
        }
        .fortune {
            background-color: #f8f8f8;
            border: 1px solid #ddd;
            border-radius: 5px;
            padding: 20px;
            white-space: pre-wrap;
            font-family: 'Courier New', monospace;
            line-height: 1.4;
        }
        .refresh-btn {
            background-color: #4CAF50;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
            margin-top: 20px;
        }
        .refresh-btn:hover {
            background-color: #45a049;
        }
        h1 {
            color: #333;
            margin-bottom: 20px;
        }
    </style>
</head>
<body>
    <div class=\"container\">
        <h1>🐄 Wisecow Fortune 🐄</h1>
        <div class=\"fortune\">$fortune_output</div>
        <button class=\"refresh-btn\" onclick=\"window.location.reload()\">Get New Fortune</button>
        <p style=\"margin-top: 30px; color: #666; font-size: 14px;\">
            Powered by fortune and cowsay | Running on port $PORT
        </p>
    </div>
</body>
</html>"

    local content_length=${#html_content}
    
    # Send proper HTTP/1.1 response
    cat <<EOF
HTTP/1.1 200 OK
Content-Type: text/html; charset=UTF-8
Content-Length: $content_length
Connection: close
Server: Wisecow/1.0

$html_content
EOF
}

# Main server function using Python for better HTTP handling
start_server_python() {
    cat > /tmp/wisecow_server.py <<'PYEOF'
import socket
import subprocess
import threading
import os
from datetime import datetime

PORT = int(os.environ.get('PORT', 4499))

def generate_fortune():
    try:
        result = subprocess.run(['fortune'], capture_output=True, text=True, timeout=5)
        fortune_text = result.stdout.strip() if result.returncode == 0 else "Fortune not available"
        
        cowsay_result = subprocess.run(['cowsay'], input=fortune_text, capture_output=True, text=True, timeout=5)
        return cowsay_result.stdout if cowsay_result.returncode == 0 else fortune_text
    except:
        return "🐄 Moo! Welcome to Wisecow! 🐄"

def handle_client(client_socket):
    try:
        request = client_socket.recv(1024).decode('utf-8')
        
        if not request:
            return
            
        # Generate fortune
        fortune_output = generate_fortune()
        fortune_output = fortune_output.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;')
        
        # HTML content
        html_content = f"""<!DOCTYPE html>
<html>
<head>
    <title>Wisecow Application</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {{
            font-family: 'Courier New', monospace;
            background-color: #f0f0f0;
            margin: 0;
            padding: 20px;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
        }}
        .container {{
            background-color: white;
            border-radius: 10px;
            padding: 30px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            max-width: 800px;
            text-align: center;
        }}
        .fortune {{
            background-color: #f8f8f8;
            border: 1px solid #ddd;
            border-radius: 5px;
            padding: 20px;
            white-space: pre-wrap;
            font-family: 'Courier New', monospace;
            line-height: 1.4;
        }}
        .refresh-btn {{
            background-color: #4CAF50;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
            margin-top: 20px;
        }}
        .refresh-btn:hover {{
            background-color: #45a049;
        }}
        h1 {{
            color: #333;
            margin-bottom: 20px;
        }}
    </style>
</head>
<body>
    <div class="container">
        <h1>🐄 Wisecow Fortune ��</h1>
        <div class="fortune">{fortune_output}</div>
        <button class="refresh-btn" onclick="window.location.reload()">Get New Fortune</button>
        <p style="margin-top: 30px; color: #666; font-size: 14px;">
            Powered by fortune and cowsay | Running on port {PORT}
        </p>
    </div>
</body>
</html>"""
        
        # Proper HTTP response
        response = f"""HTTP/1.1 200 OK\r
Content-Type: text/html; charset=UTF-8\r
Content-Length: {len(html_content.encode('utf-8'))}\r
Connection: close\r
Server: Wisecow/1.0\r
\r
{html_content}"""
        
        client_socket.send(response.encode('utf-8'))
        
    except Exception as e:
        error_response = f"""HTTP/1.1 500 Internal Server Error\r
Content-Type: text/plain\r
Content-Length: 21\r
Connection: close\r
\r
Internal Server Error"""
        client_socket.send(error_response.encode('utf-8'))
    finally:
        client_socket.close()

def start_server():
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    
    try:
        server_socket.bind(('0.0.0.0', PORT))
        server_socket.listen(5)
        print(f"Starting Wisecow server on port {PORT}...")
        print(f"Access the application at http://localhost:{PORT}")
        
        while True:
            client_socket, addr = server_socket.accept()
            print(f"Connection from {addr[0]}:{addr[1]} at {datetime.now()}")
            client_thread = threading.Thread(target=handle_client, args=(client_socket,))
            client_thread.daemon = True
            client_thread.start()
            
    except KeyboardInterrupt:
        print("\nShutting down server...")
    except Exception as e:
        print(f"Server error: {e}")
    finally:
        server_socket.close()

if __name__ == "__main__":
    start_server()
PYEOF

    python3 /tmp/wisecow_server.py
}

# Fallback netcat server (original version)
start_server_netcat() {
    echo "Starting Wisecow server on port $PORT..."
    echo "Access the application at http://localhost:$PORT"
    echo "Note: Use 'curl --http0.9' or a web browser for testing"
    
    while true; do
        # Listen for incoming connections
        {
            echo "Waiting for connection..."
            
            # Read the HTTP request
            request=$(timeout 10 cat)
            
            if [[ -n "$request" ]]; then
                echo "Received request at $(date)"
                # Serve the response
                serve_request "$request"
            fi
        } | nc -l "$PORT"
        
        # Small delay to prevent rapid restarts
        sleep 1
    done
}

# Check dependencies and start appropriate server
start_server() {
    if command -v python3 >/dev/null 2>&1; then
        echo "Using Python HTTP server (better compatibility)..."
        start_server_python
    elif command -v nc >/dev/null 2>&1; then
        echo "Using netcat server (basic HTTP)..."
        start_server_netcat
    else
        echo "Error: Neither Python3 nor netcat (nc) is available."
        echo "Please install one of them:"
        echo "  - Python3: brew install python3"
        echo "  - Netcat: brew install netcat"
        exit 1
    fi
}

# Handle script arguments
case "${1:-}" in
    "start"|"")
        start_server
        ;;
    "test")
        echo "Testing fortune generation:"
        generate_fortune
        ;;
    "help"|"-h"|"--help")
        cat <<EOF
Wisecow Application Usage:

./wisecow.sh [command]

Commands:
  start     Start the web server (default)
  test      Test fortune generation
  help      Show this help message

Environment Variables:
  PORT      Port to listen on (default: 4499)

Examples:
  ./wisecow.sh              # Start server on default port 4499
  PORT=8080 ./wisecow.sh    # Start server on port 8080
  ./wisecow.sh test         # Test fortune generation

Testing:
  curl http://localhost:4499        # Should work with improved version
  curl --http0.9 http://localhost:4499  # Fallback for netcat version

EOF
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use './wisecow.sh help' for usage information"
        exit 1
        ;;
esac
