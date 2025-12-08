#!/usr/bin/env python3
"""
Gemini Text-to-Speech Script
Generate audio from text using Gemini's native TTS.

Usage:
    python gemini_tts.py "Hello world" -o hello.wav
    python gemini_tts.py -f script.txt -o output.wav --voice Kore
    echo "Text to speak" | python gemini_tts.py -o output.wav

Voices: Puck, Charon, Kore, Fenrir, Aoede
"""

import argparse
import os
import sys
import wave
import struct
from pathlib import Path

def load_api_key():
    """Load API key from environment or .env files"""
    if key := os.environ.get('GEMINI_API_KEY'):
        return key

    env_locations = [
        Path.cwd() / '.env',
        Path.home() / '.claude' / '.env',
        Path.home() / '.claude' / 'skills' / '.env',
        Path.home() / '.claude' / 'skills' / 'ai-multimodal' / '.env',
    ]

    for env_path in env_locations:
        if env_path.exists():
            for line in env_path.read_text().splitlines():
                if line.startswith('GEMINI_API_KEY='):
                    return line.split('=', 1)[1].strip().strip('"\'')

    return None

def main():
    parser = argparse.ArgumentParser(description='Generate speech from text using Gemini TTS')
    parser.add_argument('text', nargs='?', help='Text to convert to speech')
    parser.add_argument('-f', '--file', help='Read text from file')
    parser.add_argument('-o', '--output', required=True, help='Output audio file (wav)')
    parser.add_argument('--voice', default='Kore',
                        choices=['Puck', 'Charon', 'Kore', 'Fenrir', 'Aoede'],
                        help='Voice to use (default: Kore)')
    parser.add_argument('--style', help='Style instruction (e.g., "cheerful", "professional", "whisper")')
    parser.add_argument('--speed', choices=['slow', 'normal', 'fast', 'faster'],
                        default='normal', help='Speaking speed')
    parser.add_argument('--model', default='gemini-2.5-flash-preview-tts',
                        help='Model to use')
    parser.add_argument('--play', action='store_true', help='Play audio after generating')

    args = parser.parse_args()

    # Get text from args, file, or stdin
    if args.file:
        text = Path(args.file).read_text()
    elif args.text:
        text = args.text
    elif not sys.stdin.isatty():
        text = sys.stdin.read()
    else:
        parser.error('Provide text as argument, --file, or via stdin')

    text = text.strip()
    if not text:
        parser.error('No text provided')

    # Load API key
    api_key = load_api_key()
    if not api_key:
        print('Error: GEMINI_API_KEY not found', file=sys.stderr)
        sys.exit(1)

    try:
        from google import genai
        from google.genai import types
    except ImportError:
        print('Error: google-genai not installed. Run: pip install google-genai', file=sys.stderr)
        sys.exit(1)

    # Initialize client
    client = genai.Client(api_key=api_key)

    # Build prompt with style and speed
    modifiers = []
    if args.speed and args.speed != 'normal':
        speed_map = {'slow': 'slowly', 'fast': 'quickly', 'faster': 'very quickly'}
        modifiers.append(f"speak {speed_map[args.speed]}")
    if args.style:
        modifiers.append(f"in a {args.style} tone")

    if modifiers:
        prompt = f"Say the following ({', '.join(modifiers)}): {text}"
    else:
        prompt = text

    print(f"Generating speech with voice '{args.voice}'...", file=sys.stderr)

    try:
        response = client.models.generate_content(
            model=args.model,
            contents=prompt,
            config=types.GenerateContentConfig(
                response_modalities=["AUDIO"],
                speech_config=types.SpeechConfig(
                    voice_config=types.VoiceConfig(
                        prebuilt_voice_config=types.PrebuiltVoiceConfig(
                            voice_name=args.voice,
                        )
                    )
                )
            )
        )

        # Extract audio data
        audio_data = response.candidates[0].content.parts[0].inline_data.data

        # Save as WAV
        output_path = Path(args.output)

        # The API returns raw PCM, need to wrap in WAV header
        # Assuming 24kHz, 16-bit, mono (common for TTS)
        with wave.open(str(output_path), 'wb') as wav_file:
            wav_file.setnchannels(1)  # mono
            wav_file.setsampwidth(2)  # 16-bit
            wav_file.setframerate(24000)  # 24kHz
            wav_file.writeframes(audio_data)

        print(f"Saved to {output_path}", file=sys.stderr)

        # Play if requested
        if args.play:
            import subprocess
            print("Playing audio...", file=sys.stderr)
            played = False
            # Try mpv first (most reliable)
            try:
                subprocess.run(['mpv', '--no-video', '--really-quiet', str(output_path)], check=True)
                played = True
            except (subprocess.CalledProcessError, FileNotFoundError):
                pass
            # Fallback to other players
            if not played:
                for player in ['paplay', 'aplay', 'ffplay']:
                    try:
                        if player == 'ffplay':
                            subprocess.run([player, '-nodisp', '-autoexit', '-loglevel', 'quiet', str(output_path)], check=True)
                        else:
                            subprocess.run([player, str(output_path)], check=True)
                        played = True
                        break
                    except (subprocess.CalledProcessError, FileNotFoundError):
                        continue
            if not played:
                print("No audio player found (tried: mpv, paplay, aplay, ffplay)", file=sys.stderr)

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
