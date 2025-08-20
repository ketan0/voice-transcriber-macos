#!/usr/bin/env python3
"""
Simple test script to verify Python server functionality without parakeet-mlx.
"""

import json
import sys


def main():
    print("Test transcription server started", file=sys.stderr)
    
    for line in sys.stdin:
        try:
            command = json.loads(line.strip())
            
            if command.get("action") == "transcribe":
                # Mock transcription response
                response = {
                    "success": True,
                    "text": "This is a test transcription from the mock server.",
                    "sentences": [
                        {
                            "text": "This is a test transcription from the mock server.",
                            "start": 0.0,
                            "end": 3.0,
                            "duration": 3.0
                        }
                    ]
                }
            elif command.get("action") == "ping":
                response = {"success": True, "message": "pong"}
            elif command.get("action") == "quit":
                response = {"success": True, "message": "Shutting down"}
                print(json.dumps(response))
                break
            else:
                response = {"error": f"Unknown action: {command.get('action')}"}
            
            print(json.dumps(response))
            sys.stdout.flush()
            
        except json.JSONDecodeError as e:
            error_response = {"error": f"Invalid JSON: {str(e)}"}
            print(json.dumps(error_response))
            sys.stdout.flush()
        except Exception as e:
            error_response = {"error": f"Server error: {str(e)}"}
            print(json.dumps(error_response))
            sys.stdout.flush()


if __name__ == "__main__":
    main()