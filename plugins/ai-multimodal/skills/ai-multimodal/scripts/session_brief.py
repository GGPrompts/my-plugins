#!/usr/bin/env python3
"""
Claude Session Briefing - Summarize recent conversation and optionally speak it.

Usage:
    python session_brief.py                    # Summarize last 5 messages
    python session_brief.py --messages 10      # Summarize last 10 messages
    python session_brief.py --speak            # Summarize and read aloud
    python session_brief.py --since "5 min"    # Summarize messages from last 5 minutes
"""

import argparse
import json
import os
import sys
import subprocess
from pathlib import Path
from datetime import datetime, timedelta
import re

def load_api_key():
    """Load API key from environment or .env files"""
    if key := os.environ.get('GEMINI_API_KEY'):
        return key
    env_locations = [
        Path.cwd() / '.env',
        Path.home() / '.claude' / '.env',
    ]
    for env_path in env_locations:
        if env_path.exists():
            for line in env_path.read_text().splitlines():
                if line.startswith('GEMINI_API_KEY='):
                    return line.split('=', 1)[1].strip().strip('"\'')
    return None

def find_current_session():
    """Find the most recently modified session file"""
    projects_dir = Path.home() / '.claude' / 'projects'
    if not projects_dir.exists():
        return None

    # Find most recent .jsonl file across all project dirs
    latest = None
    latest_time = 0

    for project_dir in projects_dir.iterdir():
        if not project_dir.is_dir():
            continue
        for session_file in project_dir.glob('*.jsonl'):
            mtime = session_file.stat().st_mtime
            if mtime > latest_time:
                latest_time = mtime
                latest = session_file

    return latest

def parse_time_spec(spec):
    """Parse time specification like '5 min', '1 hour', '30 sec'"""
    match = re.match(r'(\d+)\s*(sec|min|hour|hr|h|m|s)', spec.lower())
    if not match:
        return None

    value = int(match.group(1))
    unit = match.group(2)

    if unit in ('sec', 's'):
        return timedelta(seconds=value)
    elif unit in ('min', 'm'):
        return timedelta(minutes=value)
    elif unit in ('hour', 'hr', 'h'):
        return timedelta(hours=value)
    return None

def extract_messages(session_file, max_messages=5, since=None):
    """Extract recent messages from session file"""
    messages = []
    cutoff_time = None

    if since:
        delta = parse_time_spec(since)
        if delta:
            cutoff_time = datetime.utcnow() - delta

    with open(session_file, 'r') as f:
        for line in f:
            if not line.strip():
                continue
            try:
                data = json.loads(line)
                if data.get('type') in ('user', 'assistant') and 'message' in data:
                    msg = data['message']
                    role = msg.get('role', data.get('type'))
                    content = msg.get('content', '')

                    # Handle content that might be a list
                    if isinstance(content, list):
                        text_parts = []
                        for part in content:
                            if isinstance(part, dict):
                                # Extract text content, skip tool_use/tool_result/thinking
                                if part.get('type') == 'text':
                                    text_parts.append(part.get('text', ''))
                            elif isinstance(part, str):
                                text_parts.append(part)
                        content = '\n'.join(text_parts)

                    # Skip if content is empty or looks like a tool result
                    if not content or len(content) < 20:
                        continue
                    if content.startswith('[{"tool_use_id"') or content.startswith('{"type":"tool'):
                        continue

                    if content and len(content) > 20:  # Skip tiny messages
                        timestamp = None
                        if 'timestamp' in data:
                            try:
                                timestamp = datetime.fromisoformat(data['timestamp'].replace('Z', '+00:00'))
                            except:
                                pass

                        messages.append({
                            'role': role,
                            'content': content[:2000],  # Truncate long messages
                            'timestamp': timestamp
                        })
            except json.JSONDecodeError:
                continue

    # Filter by time if specified
    if cutoff_time:
        messages = [m for m in messages if m.get('timestamp') and m['timestamp'].replace(tzinfo=None) >= cutoff_time]

    # Return last N messages
    return messages[-max_messages:] if max_messages else messages

def summarize_with_haiku(messages):
    """Summarize messages using Claude Haiku (fast, cheap)"""
    # Format messages for summary
    formatted = []
    for msg in messages:
        role = "User" if msg['role'] == 'user' else "Claude"
        formatted.append(f"{role}: {msg['content'][:500]}")

    conversation = "\n\n".join(formatted)

    prompt = f"""Summarize this Claude Code conversation in 2-3 sentences, focusing on:
- What was accomplished or decided
- Key information or findings
- Any pending actions or next steps

Keep it concise and suitable for reading aloud as a brief status update.

Conversation:
{conversation}

Summary:"""

    try:
        # Use claude CLI with haiku
        result = subprocess.run(
            ['claude', '-p', prompt, '--model', 'haiku'],
            capture_output=True,
            text=True,
            timeout=60
        )
        if result.returncode == 0:
            return result.stdout.strip()
        else:
            print(f"Claude CLI error: {result.stderr}", file=sys.stderr)
            return None
    except FileNotFoundError:
        print("Claude CLI not found", file=sys.stderr)
        return None
    except subprocess.TimeoutExpired:
        print("Claude CLI timed out", file=sys.stderr)
        return None


def summarize_with_gemini_cli(messages):
    """Summarize messages using Gemini CLI (fallback)"""
    # Format messages for summary
    formatted = []
    for msg in messages:
        role = "User" if msg['role'] == 'user' else "Claude"
        formatted.append(f"{role}: {msg['content'][:500]}")

    conversation = "\n\n".join(formatted)

    prompt = f"""Summarize this Claude Code conversation in 2-3 sentences, focusing on:
- What was accomplished or decided
- Key information or findings
- Any pending actions or next steps

Keep it concise and suitable for reading aloud as a brief status update.

Conversation:
{conversation}

Summary:"""

    try:
        result = subprocess.run(
            ['gemini', '-m', 'gemini-2.5-flash', prompt],
            capture_output=True,
            text=True,
            timeout=60
        )
        if result.returncode == 0:
            return result.stdout.strip()
        else:
            print(f"Gemini CLI error: {result.stderr}", file=sys.stderr)
            return None
    except FileNotFoundError:
        print("Gemini CLI not found", file=sys.stderr)
        return None
    except subprocess.TimeoutExpired:
        print("Gemini CLI timed out", file=sys.stderr)
        return None


def summarize_with_gemini_api(messages, api_key):
    """Summarize messages using Gemini API (fallback)"""
    try:
        from google import genai
    except ImportError:
        return None

    client = genai.Client(api_key=api_key)

    # Format messages for summary
    formatted = []
    for msg in messages:
        role = "User" if msg['role'] == 'user' else "Claude"
        formatted.append(f"{role}: {msg['content'][:500]}")

    conversation = "\n\n".join(formatted)

    prompt = f"""Summarize this Claude Code conversation in 2-3 sentences, focusing on:
- What was accomplished or decided
- Key information or findings
- Any pending actions or next steps

Keep it concise and suitable for reading aloud as a brief status update.

Conversation:
{conversation}

Summary:"""

    try:
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=prompt
        )
        return response.text.strip()
    except Exception as e:
        print(f"Gemini API error: {e}", file=sys.stderr)
        return None

def speak_text(text, voice='en-GB-RyanNeural', speed='fast'):
    """Convert text to speech using Edge TTS and play it"""
    import tempfile

    with tempfile.NamedTemporaryFile(suffix='.mp3', delete=False) as f:
        output_file = f.name

    try:
        # Use Edge TTS (free, no API limits)
        # Rate: +40% for slightly faster speech
        subprocess.run([
            'edge-tts', 'synthesize',
            '-v', voice,
            '-r', '+40%',
            '-t', text,
            '-o', output_file.replace('.mp3', '')  # edge-tts adds .mp3
        ], check=True, capture_output=True)

        actual_file = output_file.replace('.mp3', '') + '.mp3'

        # Play with mpv
        subprocess.run(['mpv', '--no-video', '--really-quiet', actual_file], check=True)
    except subprocess.CalledProcessError as e:
        print(f"TTS failed: {e}", file=sys.stderr)
    except FileNotFoundError:
        print("edge-tts or mpv not found", file=sys.stderr)
    finally:
        try:
            os.unlink(output_file.replace('.mp3', '') + '.mp3')
        except:
            pass

def main():
    parser = argparse.ArgumentParser(description='Summarize recent Claude session')
    parser.add_argument('--messages', '-n', type=int, default=5, help='Number of recent messages to summarize')
    parser.add_argument('--since', help='Time window (e.g., "5 min", "1 hour")')
    parser.add_argument('--speak', '-s', action='store_true', help='Read summary aloud (uses Edge TTS)')
    parser.add_argument('--voice', default='en-GB-RyanNeural',
                        help='Edge TTS voice (default: en-GB-RyanNeural). Run "edge-tts voice-list" for options')
    parser.add_argument('--session', help='Specific session file to summarize')

    args = parser.parse_args()

    # Find session
    if args.session:
        session_file = Path(args.session)
    else:
        session_file = find_current_session()

    if not session_file or not session_file.exists():
        print("No active session found", file=sys.stderr)
        sys.exit(1)

    # Extract messages
    messages = extract_messages(session_file, args.messages, args.since)

    if not messages:
        print("No recent messages found", file=sys.stderr)
        sys.exit(1)

    print(f"Summarizing {len(messages)} messages from session...", file=sys.stderr)

    # Try Gemini 2.5 Flash first (free tier), then Haiku as fallback
    summary = summarize_with_gemini_cli(messages)

    if not summary:
        print("Falling back to Gemini API...", file=sys.stderr)
        api_key = load_api_key()
        if api_key:
            summary = summarize_with_gemini_api(messages, api_key)

    if not summary:
        print("Falling back to Haiku...", file=sys.stderr)
        summary = summarize_with_haiku(messages)

    if not summary:
        print("Could not generate summary", file=sys.stderr)
        sys.exit(1)

    print(f"\n📋 Session Brief:\n{summary}\n")

    # Speak if requested
    if args.speak:
        print("🔊 Speaking...", file=sys.stderr)
        speak_text(summary, args.voice)

if __name__ == '__main__':
    main()
