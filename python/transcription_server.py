#!/usr/bin/env python3
"""
Transcription server for Voice Transcriber app.
Listens for audio file paths via stdin and returns transcribed text as JSON.
"""

import json
import sys
import logging
from pathlib import Path
from typing import Optional

try:
    from parakeet_mlx import from_pretrained
except ImportError:
    print(json.dumps({"error": "parakeet_mlx not installed. Run: uv add parakeet-mlx"}))
    sys.exit(1)


class TranscriptionServer:
    def __init__(self, model_name: str = "mlx-community/parakeet-tdt-0.6b-v2"):
        self.model = None
        self.model_name = model_name
        self._load_model()
    
    def _load_model(self):
        """Load the Parakeet model."""
        try:
            logging.info(f"Loading model: {self.model_name}")
            self.model = from_pretrained(self.model_name)
            logging.info("Model loaded successfully")
        except Exception as e:
            logging.error(f"Failed to load model: {e}")
            raise
    
    def transcribe(self, audio_path: str) -> dict:
        """Transcribe audio file and return result as dict."""
        try:
            if not Path(audio_path).exists():
                return {"error": f"Audio file not found: {audio_path}"}
            
            logging.info(f"Transcribing: {audio_path}")
            result = self.model.transcribe(audio_path)
            
            return {
                "success": True,
                "text": result.text,
                "sentences": [
                    {
                        "text": sentence.text,
                        "start": sentence.start,
                        "end": sentence.end,
                        "duration": sentence.duration
                    }
                    for sentence in result.sentences
                ]
            }
        except Exception as e:
            logging.error(f"Transcription failed: {e}")
            return {"error": f"Transcription failed: {str(e)}"}
    
    def run(self):
        """Main server loop - read commands from stdin."""
        logging.info("Transcription server started")
        
        for line in sys.stdin:
            try:
                command = json.loads(line.strip())
                
                if command.get("action") == "transcribe":
                    audio_path = command.get("audio_path")
                    if not audio_path:
                        response = {"error": "Missing audio_path parameter"}
                    else:
                        response = self.transcribe(audio_path)
                
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


def main():
    # Set up logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler('/tmp/voice_transcriber.log'),
            logging.StreamHandler(sys.stderr)
        ]
    )
    
    try:
        server = TranscriptionServer()
        server.run()
    except Exception as e:
        logging.error(f"Server startup failed: {e}")
        print(json.dumps({"error": f"Server startup failed: {str(e)}"}))
        sys.exit(1)


if __name__ == "__main__":
    main()