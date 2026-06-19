# m30sync

Transfer music to a **Mechen M30** (or any Actions Semiconductor-based portable player) with minimal metadata — stripping the 30+ MusicBrainz tag fields that cause these chipsets to show "No Artist" / "No Album".

## Quick start

```bash
# Copy a directory of music to the M30 (prompts for gapless merge)
m30sync /path/to/music/Album/

# Dry-run: see what would happen
m30sync -n ~/Music/SomeAlbum/

# Upload a playlist as a folder on the M30
m30sync ~/Music/MyFaves.m3u

# Force gapless merge without prompt
m30sync --gapless /path/to/album/

# Skip gapless prompt, copy individual files
m30sync --no-gapless /path/to/album/

# Just delete the device's database (after manual copies)
m30sync --clean

# Create 'Artist - Album' subdirectories
m30sync --album-dirs /path/to/album/
```

After the transfer, **unplug and replug the M30** so it rebuilds its MUSIC.LIB database from the clean tags.

## Features

### Tag stripping
Reduces each file to the 6 tags the Actions chipset can actually parse:
`TITLE`, `ARTIST`, `ALBUM`, `TRACKNUMBER`, `GENRE` (single value), `DATE` (4-digit)

### Gapless albums
When you point `m30sync` at a directory with multiple tracks, it asks if you want to **merge them into a single gapless FLAC**. This is the only reliable fix for the gap between tracks on this chipset — the ATJ DSP can't decode two files without a pause, but a single merged file plays continuously.

The merged file gets:
- 6 clean tags from the most common values
- An embedded **CUE sheet** with chapter markers for each original track (the M30 supports CUE-based navigation)

Use `--gapless` to skip the prompt, or `--no-gapless` to keep individual tracks.

### Playlist upload
Pass an `.m3u` or `.m3u8` file as source:
```bash
m30sync ~/Music/playlists/roadtrip.m3u
```
This creates a folder on the M30 named after the playlist (`roadtrip/`) and copies all referenced tracks with cleaned tags and standardised filenames. Tracks are copied, not symlinked — they work independently.

### Filename standardisation
All files are renamed to `Artist - Title.ext` — consistent, no track numbers, no underscores, no `(1)` suffixes.

### Database cleanup
After transfer, prompts to delete `MUSIC.LIB` / `ALBUM.PIC` so the M30 rescans and builds a fresh library from the clean tags.

## Why

Actions Semiconductor chipsets (Mechen M30, D-Wave, AK1025, and countless Chinese portable players) use a proprietary MUSIC.LIB database. Their parser is fragile:

- **Tag bloat**: 30+ Picard fields cause the parser to skip the entire tag block → "No Artist"
- **Multivalue genres**: Semicolons are not parsed
- **Case sensitivity**: Mixed-case tags confuse the parser
- **Gapless**: The DSP can't preload two files — only a single merged file plays without a gap

## Files

| File | Description |
|---|---|
| `m30sync` | Main tool — copy, strip, merge gapless, playlist upload |
| `m30_tag_fix.py` | Standalone: strip tags in-place without copying |

## Dependencies

- Python 3 with **mutagen** (ships with Picard; `pip install mutagen` otherwise)
- **ffmpeg** (for gapless merge only)
- M30 mounted at `/run/media/janhellion/MECHEN M30` (adjust `M30_MOUNT` in script if needed)

## Install

```bash
chmod +x m30sync m30_tag_fix.py
cp m30sync m30_tag_fix.py ~/.local/bin/
```
