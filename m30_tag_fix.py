#!/usr/bin/env python3
"""m30_tag_fix — Strip music files to bare Mechen M30-compatible tags.

The M30 chokes on Picard's 30+ tag fields and mixed-case tags.
Keeps only: TITLE, ARTIST, ALBUM, TRACKNUMBER, GENRE, DATE.

Usage:
  m30_tag_fix.py file.flac [files...]
  find /path -name "*.flac" -exec m30_tag_fix.py {} \\;

After running: delete MUSIC.LIB + ALBUM.PIC from the M30 so it rebuilds its DB.
"""

import sys, os

from mutagen.flac import FLAC
from mutagen.mp3 import MP3
from mutagen.id3 import ID3, TIT2, TPE1, TALB, TRCK, TCON, TYER


def fix_flac(path):
    audio = FLAC(path)

    # Read tags (case-insensitive)
    title = audio.get('title') or audio.get('TITLE') or [None]
    artist = audio.get('artist') or audio.get('ARTIST') or [None]
    album = audio.get('album') or audio.get('ALBUM') or [None]
    track_raw = audio.get('tracknumber') or audio.get('TRACKNUMBER') or [None]
    genre_raw = audio.get('genre') or audio.get('GENRE') or [None]
    date_raw = audio.get('date') or audio.get('DATE') or audio.get('originalyear') or audio.get('ORIGINALYEAR') or [None]

    t = (title[0] or '').strip()
    a = (artist[0] or '').strip()
    al = (album[0] or '').strip()
    tr = (str(track_raw[0] or '').split('/')[0]).strip() if track_raw[0] else ''
    g = (str(genre_raw[0] or '').split(';')[0].strip())[:30] if genre_raw[0] else ''
    d = (str(date_raw[0] or '').split('-')[0].strip())[:4] if date_raw[0] else ''

    if not t and not a:
        return False  # nothing useful

    print(f"  {os.path.basename(path)}  |  {a} — {t}")

    audio.clear()
    audio['TITLE'] = t
    audio['ARTIST'] = a
    if al:
        audio['ALBUM'] = al
    if tr:
        audio['TRACKNUMBER'] = tr
    if g:
        audio['GENRE'] = g
    if d:
        audio['DATE'] = d
    audio.save()
    return True


def fix_mp3(path):
    # Read existing tags via ID3 directly
    try:
        id3 = ID3(path)
    except Exception:
        id3 = ID3()

    title = artist = album = track = genre = year = None
    for fid, frame in id3.items():
        fname = fid.upper()
        text = str(frame)
        if fname == 'TIT2':
            title = text
        elif fname == 'TPE1':
            artist = text
        elif fname == 'TALB':
            album = text
        elif fname == 'TRCK':
            track = text.split('/')[0]
        elif fname == 'TCON':
            genre = text.split(';')[0][:30]
        elif fname in ('TYER', 'TDRC'):
            year = text.split('-')[0][:4]

    if not title and not artist:
        return False

    print(f"  {os.path.basename(path)}  |  {artist} — {title}")

    # Delete all existing frames
    id3.delete()
    id3 = ID3()

    # Write only the 6 essential tags
    if title:
        id3.add(TIT2(encoding=3, text=title))
    if artist:
        id3.add(TPE1(encoding=3, text=artist))
    if album:
        id3.add(TALB(encoding=3, text=album))
    if track:
        id3.add(TRCK(encoding=3, text=track))
    if genre:
        id3.add(TCON(encoding=3, text=genre))
    if year:
        id3.add(TYER(encoding=3, text=year))
    # Write V1 tags too (the M30 may prefer V1)
    id3.save(path, v1=2)
    return True


def main():
    args = sys.argv[1:]
    if not args:
        print("Usage: m30_tag_fix.py file.flac [files...]")
        sys.exit(1)

    ok = skip = err = 0
    for path in args:
        if not os.path.isfile(path):
            print(f"  SKIP (not a file): {path}")
            skip += 1
            continue
        ext = path.rsplit('.', 1)[-1].lower()
        try:
            if ext == 'flac':
                if fix_flac(path):
                    ok += 1
                else:
                    print(f"  SKIP (no tags): {os.path.basename(path)}")
                    skip += 1
            elif ext == 'mp3':
                if fix_mp3(path):
                    ok += 1
                else:
                    print(f"  SKIP (no tags): {os.path.basename(path)}")
                    skip += 1
            else:
                print(f"  SKIP (format): {os.path.basename(path)}")
                skip += 1
        except Exception as e:
            print(f"  ERROR: {os.path.basename(path)} — {e}")
            err += 1

    print(f"\nDone: {ok} fixed, {skip} skipped, {err} errors")


if __name__ == '__main__':
    main()
