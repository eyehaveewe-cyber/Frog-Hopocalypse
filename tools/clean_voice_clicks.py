"""Repair short impulses in approved voices, always from retained originals.

Requires ffmpeg, ffprobe and numpy. No filtering is applied to synthesized hops.
The detection count is a signal-processing measure, not identified keystrokes.
"""
import hashlib
import json
import math
from pathlib import Path
import re
import subprocess
import tempfile
import wave

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
ORIGINALS = ROOT / 'docs/audio-originals/pre-keyboard-cleanup'
AUDIO = ROOT / 'game/audio'
PREVIEW = ROOT / 'docs/previews/voice-cleanup'
FILTER = 'adeclick=w=55:o=75:a=2:t=2:b=2'


def run(*args):
    return subprocess.run(args, check=True, capture_output=True)


def decode(path):
    return np.frombuffer(run('ffmpeg', '-v', 'error', '-i', str(path),
                             '-f', 'f32le', '-').stdout, dtype='<f4')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def db(value):
    return 20 * math.log10(max(float(value), 1e-12))


def main():
    PREVIEW.mkdir(parents=True, exist_ok=True)
    manifest = json.loads((ORIGINALS / 'manifest.json').read_text())
    report = {'filter': FILTER, 'encoder': 'libvorbis quality 6', 'clips': [],
              'scope': 'Short impulsive-noise repair; no trim, gate, resample or pitch change. '
                       'No independent human listening; detection counts do not identify keystrokes.'}
    for clip in manifest['clips']:
        source, target = ORIGINALS / clip['file'], AUDIO / clip['file']
        meta = json.loads(run('ffprobe', '-v', 'error', '-show_streams',
                              '-of', 'json', str(source)).stdout)['streams'][0]
        rate, channels = int(meta['sample_rate']), int(meta['channels'])
        before = decode(source)
        with tempfile.TemporaryDirectory(prefix='hopan-voice-') as temp:
            raw = Path(temp) / 'repaired.f32'
            result = run('ffmpeg', '-hide_banner', '-nostdin', '-i', str(source),
                         '-af', FILTER, '-f', 'f32le', str(raw))
            repaired = np.fromfile(raw, dtype='<f4')
            assert len(before) == len(repaired), clip['file']
            log = result.stderr.decode()
            match = re.search(r'Detected clicks in (\d+) of (\d+) samples', log)
            assert match, log
            detected, total = map(int, match.groups())
            assert detected / total < 0.10, (clip['file'], 'excessive repair')
            run('ffmpeg', '-v', 'error', '-nostdin', '-f', 'f32le', '-ar', str(rate),
                '-ac', str(channels), '-i', str(raw), '-c:a', 'libvorbis', '-q:a', '6',
                '-y', str(target))
        after = decode(target)
        assert abs(len(after) - len(before)) / rate / channels < .01
        rms_before = float(np.sqrt(np.mean(before.astype('float64') ** 2)))
        rms_after = float(np.sqrt(np.mean(after.astype('float64') ** 2)))
        rms_delta = db(rms_after / rms_before)
        assert abs(rms_delta) < 1.0, (clip['file'], rms_delta)
        peak = float(np.max(np.abs(after)))
        assert peak < .95, (clip['file'], 'insufficient headroom')
        record = dict(file=clip['file'], original_sha256=sha(source), sha256=sha(target),
                      sample_rate=rate, channels=channels, samples_before=len(before),
                      samples_after=len(after), detected_impulse_samples=detected,
                      detected_percent=round(100 * detected / total, 4),
                      rms_delta_db=round(rms_delta, 4), peak_dbfs=round(db(peak), 3),
                      clipped_samples=int(np.sum(np.abs(after) >= 1)))
        report['clips'].append(record)
        clip.update(bytes=target.stat().st_size, sha256=record['sha256'],
                    peak_dbfs=record['peak_dbfs'], clipped_samples=0,
                    keyboard_cleanup={'original_sha256': record['original_sha256'],
                                      'filter': FILTER, 'original': str(source.relative_to(ROOT))})
        print(f"{source.name}: {record['detected_percent']:.2f}% impulse samples, "
              f"{rms_delta:+.3f} dB RMS, peak {record['peak_dbfs']:.2f} dBFS")
    manifest['status'] = 'User-mapped clips with conservative impulsive-noise repair; listening acceptance pending'
    (AUDIO / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    (PREVIEW / 'measurements.json').write_text(json.dumps(report, indent=2) + '\n')
    # All phrases in manifest order, before then after. Separate WAVs allow A/B playback.
    for label, directory in [('before', ORIGINALS), ('after', AUDIO)]:
        with wave.open(str(PREVIEW / f'{label}.wav'), 'wb') as output:
            output.setnchannels(1)
            output.setsampwidth(2)
            output.setframerate(24000)
            for clip in manifest['clips']:
                values = decode(directory / clip['file'])
                output.writeframes((np.clip(values, -1, 1) * 32767).astype('<i2').tobytes())
                output.writeframes(bytes(12000))  # 250 ms between phrases


if __name__ == '__main__':
    main()
