# m30sync

Transfer music to a **Mechen M30** (or any Actions Semiconductor-based portable player) with minimal metadata — stripping the 30+ MusicBrainz tag fields that cause these chipsets to show "No Artist" / "No Album".

## Quick start

```bash
# Copy a directory of music to the M30
m30sync /path/to/music/Album/

# Dry-run: see what would happen
m30sync -n ~/Music/SomeAlbum/

# Just delete the device's database (after manual copies)
m30sync --clean

# Create 'Artist - Album' subdirectories
m30sync --album-dirs /path/to/music/Album/
```

After the transfer or cleanup, **unplug and replug the M30** so it rebuilds its MUSIC.LIB database from the clean tags.

## What it does

1. Finds all FLAC/MP3 files under the source path
2. **Strips tags** down to only 6 fields the M30's chipset can actually parse:
   `TITLE`, `ARTIST`, `ALBUM`, `TRACKNUMBER`, `GENRE` (single value), `DATE` (4-digit)
3. **Copies** to the M30 with clean filenames: `Artist - Title.ext`
4. **Prompts** to delete `MUSIC.LIB` / `ALBUM.PIC` so the device rescans

## Why

Actions Semiconductor chipsets (found in the Mechen M30, D-Wave, AK1025, and countless Chinese portable players) use a proprietary MUSIC.LIB database. Their parser is fragile:

- **Tag bloat**: Picard writes 30+ fields (MUSICBRAINZ_TRACKID, ENGINEER, ISRC, REPLAYGAIN, ACCURATERIPRESULT...). The parser hits an unexpected field and **skips the entire tag block**, showing "No Artist"
- **Multivalue genres**: `GENRE=Alternative Metal;Alternative Rock;Art Rock` can't be parsed
- **Case sensitivity**: Mixed-case tags confuse the parser
- **File name chaos**: Mixed numbering schemes, inconsistent artist prefixes, `(1)` dupes

`m30sync` reduces each file to the minimum the hardware can reliably read.

## Tools

| File | Description |
|---|---|
| `m30sync` | Main tool — copy + strip tags + clean filenames |
| `m30_tag_fix.py` | Standalone: strip tags in-place without copying |

## Dependencies

- Python 3 with **mutagen** (ships with Picard; `pip install mutagen` otherwise)
- The M30 mounted at `/run/media/janhellion/MECHEN M30` (adjust `M30_MOUNT` in the script if needed)

## Install

```bash
chmod +x m30sync m30_tag_fix.py
cp m30sync m30_tag_fix.py ~/.local/bin/
```
