"""在 macOS 构建机逐句合成入门课程，按真实音频时长生成字幕。
仅写入 assets/demo/personal-*，不删除或修改原有材料。
"""
import json
import math
from pathlib import Path
import subprocess
import tempfile
import wave

def load_courses():
    result = subprocess.run(["dart", "scripts/export_personal_courses.dart"], check=True, capture_output=True, text=True)
    return json.loads(result.stdout)

def timestamp(seconds):
    ms = round(seconds * 1000)
    return f"{ms // 3600000:02}:{ms // 60000 % 60:02}:{ms // 1000 % 60:02},{ms % 1000:03}"

def generate():
    output = Path("assets/demo")
    output.mkdir(parents=True, exist_ok=True)
    # 云端临时目录保留至构建机回收，不在脚本中批量删除。
    scratch = tempfile.mkdtemp(prefix='personal_course_audio_')
    for course_id, title, sentences in load_courses():
        base = output / ("personal-" + course_id)
        subtitles = []
        elapsed = 0
        with wave.open(str(base) + ".wav", "wb") as combined:
            combined.setnchannels(1)
            combined.setsampwidth(2)
            combined.setframerate(22050)
            for index, english in enumerate(sentences):
                aiff = Path(scratch) / f"{course_id}-{index}.aiff"
                wav = Path(scratch) / f"{course_id}-{index}.wav"
                subprocess.run(["say", "-v", "Samantha", "-r", "130", "-o", str(aiff), english], check=True)
                subprocess.run(["afconvert", "-f", "WAVE", "-d", "LEI16@22050", "-c", "1", str(aiff), str(wav)], check=True)
                with wave.open(str(wav), "rb") as segment:
                    assert segment.getnchannels() == 1 and segment.getsampwidth() == 2
                    assert segment.getframerate() == 22050
                    frames = segment.readframes(segment.getnframes())
                    duration = segment.getnframes() / 22050
                assert duration > 0
                subtitles.append(f"{index + 1}\n{timestamp(elapsed)} --> {timestamp(elapsed + duration)}\n{english}\n")
                combined.writeframes(frames)
                pause_frames = 13230
                combined.writeframes(bytes(pause_frames * 2))
                elapsed += duration + pause_frames / 22050
        Path(str(base) + ".srt").write_text("\n".join(subtitles), encoding="utf-8")
        Path(str(base) + ".json").write_text(json.dumps({"duration": math.ceil(elapsed), "voice": "Samantha", "rate": 130}), encoding="utf-8")
        print(f"{title}: {elapsed:.1f}s, {len(sentences)} sentences")

if __name__ == "__main__":
    generate()
