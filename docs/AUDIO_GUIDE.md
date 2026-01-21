# 🎵 Audio Assets Guide

## Overview

This document specifies all audio assets needed for PREY FURY / CROCODILE FURY. The audio system is fully implemented and ready - just add the sound files!

---

## 📁 Directory Structure

```
prey_fury/
  assets/
    audio/
      sfx/              # Sound effects
        ├── eat_prey.wav
        ├── fury_activate.wav
        ├── fury_end.wav
        ├── take_damage.wav
        ├── level_up.wav
        ├── powerup_select.wav
        ├── powerup_appear.wav
        ├── powerup_rare.wav
        ├── powerup_legendary.wav
        ├── combo_increase.wav
        ├── combo_max.wav
        ├── wave_start.wav
        ├── boss_warning.wav
        ├── death.wav
        ├── victory.wav
        ├── button_click.wav
        └── button_hover.wav

      music/            # Background music
        ├── music_calm.mp3
        ├── music_tense.mp3
        ├── music_fury.mp3
        └── music_boss.mp3
```

---

## 🔊 Sound Effects Specifications

### Player Actions (8 sounds)

#### 1. `eat_prey.wav`
- **Trigger:** When player eats a prey during Fury mode
- **Feel:** Satisfying "crunch" or "chomp"
- **Duration:** 0.2-0.3s
- **Pitch:** Varies with combo (higher combo = higher pitch)
- **Reference:** Pac-Man chomp, but more aggressive
- **Volume:** Medium (70%)

#### 2. `fury_activate.wav`
- **Trigger:** When player activates Fury mode
- **Feel:** Epic transformation, power surge
- **Duration:** 0.5-1.0s
- **Pitch:** Fixed
- **Reference:** Super Saiyan transformation (short version)
- **Volume:** Loud (120% of base)

#### 3. `fury_end.wav`
- **Trigger:** When Fury mode expires
- **Feel:** Power down, energy dissipate
- **Duration:** 0.3-0.5s
- **Pitch:** Fixed
- **Reference:** Shield break sound
- **Volume:** Medium (80%)

#### 4. `take_damage.wav`
- **Trigger:** When player takes damage
- **Feel:** Impact, pain
- **Duration:** 0.2-0.3s
- **Pitch:** Fixed
- **Volume:** Varies with damage (70-100%)
- **Reference:** Zelda heart damage

#### 5. `level_up.wav`
- **Trigger:** When player levels up (every 30s or 10 kills)
- **Feel:** Achievement, celebration
- **Duration:** 0.5-0.8s
- **Pitch:** Fixed
- **Reference:** Pokémon level-up jingle
- **Volume:** Loud (110%)

#### 6. `combo_increase.wav`
- **Trigger:** When combo increases (each kill)
- **Feel:** Light, satisfying tick
- **Duration:** 0.1-0.2s
- **Pitch:** Increases with combo level (1.0 to 1.5)
- **Reference:** Super Smash Bros combo hit
- **Volume:** Medium (80%)

#### 7. `combo_max.wav`
- **Trigger:** When combo reaches max (5x)
- **Feel:** Epic milestone
- **Duration:** 0.3-0.5s
- **Pitch:** Fixed
- **Reference:** Devil May Cry SSS rank
- **Volume:** Loud (120%)

#### 8. `death.wav`
- **Trigger:** When player dies
- **Feel:** Dramatic, game over
- **Duration:** 1.0-1.5s
- **Pitch:** Fixed
- **Reference:** Dark Souls "You Died"
- **Volume:** Loud (110%)

---

### Power-Ups (4 sounds)

#### 9. `powerup_appear.wav`
- **Trigger:** When power-up selection screen appears
- **Feel:** Magic, opportunity
- **Duration:** 0.5-0.7s
- **Pitch:** Fixed
- **Reference:** Zelda chest opening
- **Volume:** Medium (90%)

#### 10. `powerup_select.wav`
- **Trigger:** When selecting common/rare power-up
- **Feel:** Confirmation, satisfaction
- **Duration:** 0.3-0.5s
- **Pitch:** Fixed
- **Reference:** Menu confirm sound
- **Volume:** Medium (100%)

#### 11. `powerup_rare.wav`
- **Trigger:** When selecting rare/epic power-up
- **Feel:** Special, valuable
- **Duration:** 0.5-0.8s
- **Pitch:** Fixed
- **Reference:** Hearthstone legendary card
- **Volume:** Loud (100%)

#### 12. `powerup_legendary.wav`
- **Trigger:** When selecting legendary power-up
- **Feel:** EPIC, once-in-a-lifetime
- **Duration:** 0.8-1.2s
- **Pitch:** Fixed
- **Reference:** Apex Legends heirloom open
- **Volume:** Very Loud (100%)

---

### Game Events (5 sounds)

#### 13. `wave_start.wav`
- **Trigger:** When new wave starts
- **Feel:** Alert, anticipation
- **Duration:** 0.3-0.5s
- **Pitch:** Fixed
- **Reference:** Round start sound
- **Volume:** Medium (100%)

#### 14. `boss_warning.wav`
- **Trigger:** When boss is about to spawn
- **Feel:** Danger, epic encounter coming
- **Duration:** 1.0-1.5s
- **Pitch:** Fixed
- **Reference:** Dark Souls boss fog gate
- **Volume:** Very Loud (130%)

#### 15. `victory.wav`
- **Trigger:** When level/wave is completed
- **Feel:** Achievement, celebration
- **Duration:** 1.0-2.0s
- **Pitch:** Fixed
- **Reference:** Final Fantasy victory fanfare
- **Volume:** Loud (120%)

#### 16. `button_click.wav`
- **Trigger:** When clicking UI buttons
- **Feel:** Satisfying click
- **Duration:** 0.05-0.1s
- **Pitch:** Fixed
- **Reference:** iOS button tap
- **Volume:** Quiet (60%)

#### 17. `button_hover.wav`
- **Trigger:** When hovering over UI buttons
- **Feel:** Subtle feedback
- **Duration:** 0.05-0.1s
- **Pitch:** Fixed
- **Reference:** Subtle UI tick
- **Volume:** Very Quiet (40%)

---

## 🎵 Background Music Specifications

### Intensity Layer System

The game uses **adaptive music** that changes based on game state:

#### 1. `music_calm.mp3` (Base Layer)
- **When:** Normal gameplay, few enemies
- **Tempo:** 80-100 BPM
- **Feel:** Mysterious, aquatic, sneaky
- **Instruments:** Synth pads, light percussion, underwater ambience
- **Reference:** Celeste B-sides (atmospheric)
- **Duration:** 2-3 minute loop
- **Crossfade:** Smooth transition to other layers

#### 2. `music_tense.mp3` (Action Layer)
- **When:** Many enemies, low health, critical moment
- **Tempo:** 100-120 BPM
- **Feel:** Urgent, dangerous, pulse-raising
- **Instruments:** Drums intensify, bass drops, synth arpeggios
- **Reference:** DOOM Eternal (low-intensity combat)
- **Duration:** 2-3 minute loop
- **Crossfade:** Can transition to calm or fury

#### 3. `music_fury.mp3` (Power Layer)
- **When:** Fury mode active
- **Tempo:** 120-140 BPM
- **Feel:** EPIC, powerful, unstoppable
- **Instruments:** Heavy drums, distorted synths, choir hits
- **Reference:** Metal Gear Rising boss themes
- **Duration:** 30-60 second loop (short for Fury duration)
- **Crossfade:** Quick fade in (0.5s)

#### 4. `music_boss.mp3` (Epic Layer)
- **When:** Boss fight
- **Tempo:** 140-160 BPM
- **Feel:** Epic, dramatic, final showdown
- **Instruments:** Full orchestra + electronic elements
- **Reference:** Undertale boss themes
- **Duration:** 2-3 minute loop
- **Crossfade:** Dramatic entry

---

## 🎨 Audio Style Guide

### Overall Direction:
- **Genre:** Electronic/Synthwave with aquatic/swamp elements
- **Mood:** Mysterious → Tense → Epic
- **Reference Games:**
  * Hotline Miami (synthwave aesthetic)
  * DOOM Eternal (adaptive intensity)
  * Celeste (atmospheric pads)
  * Vampire Survivors (retro vibes)

### Key Characteristics:
- **Synth-heavy** - Modern electronic production
- **Punchy drums** - Clear, impactful hits
- **Aquatic elements** - Bubbles, water sounds, reverb
- **Retro vibes** - 8-bit/16-bit flavor mixed with modern production
- **High energy** - Fast-paced, exciting

---

## 🔧 Technical Requirements

### File Formats:
- **SFX:** `.wav` or `.ogg` (WAV preferred for quality)
- **Music:** `.mp3` or `.ogg` (MP3 for smaller size)

### Bit Rates:
- **SFX:** 44.1kHz, 16-bit, mono
- **Music:** 44.1kHz, 192-320 kbps, stereo

### File Sizes (Target):
- **Individual SFX:** <100KB each
- **Music tracks:** <5MB each (3-minute loop)
- **Total audio assets:** <25MB

### Looping:
- All music tracks **must loop seamlessly**
- Use fade-out/fade-in for smooth crossfades
- Test loops to ensure no clicks/pops

---

## 📦 Asset Sources (Budget-Friendly)

### Free Resources:
1. **Freesound.org** - CC0 sound effects
2. **OpenGameArt.org** - Free game audio
3. **Incompetech** - Royalty-free music
4. **Pixabay** - Free sound effects

### Paid (Recommended):
1. **Envato Elements** - $16.50/month, unlimited downloads
2. **Artlist** - $9.99/month, high-quality music
3. **Splice** - Sound design samples

### AI Generation:
1. **Suno AI** - Music generation ($10/month)
2. **AIVA** - AI composer (free tier available)
3. **Soundraw** - Custom music generation

### Commissioning:
- **Upwork/Fiverr:** $50-200 for SFX pack
- **Upwork/Fiverr:** $200-500 for 4-track music suite

---

## 🎯 Priority Order

### Phase 1 (Essential - Playable):
1. ✅ eat_prey.wav
2. ✅ fury_activate.wav
3. ✅ take_damage.wav
4. ✅ level_up.wav
5. ✅ powerup_select.wav
6. ✅ music_calm.mp3

### Phase 2 (Polish - Enhanced):
7. ✅ fury_end.wav
8. ✅ combo_increase.wav
9. ✅ combo_max.wav
10. ✅ powerup_rare.wav
11. ✅ powerup_legendary.wav
12. ✅ music_fury.mp3

### Phase 3 (Complete - Release):
13. ✅ All remaining SFX
14. ✅ music_tense.mp3
15. ✅ music_boss.mp3
16. ✅ UI sounds

---

## 🔌 Integration Status

### ✅ IMPLEMENTED:
- Complete AudioManager class
- All sound effect methods
- Music intensity system
- Volume controls
- Pitch variation
- Crossfade support

### 📋 TODO:
- Add actual audio files to `/assets/audio/`
- Update `pubspec.yaml` with asset paths
- Test all audio triggers in-game
- Balance volume levels
- Fine-tune crossfade timings

---

## 📝 pubspec.yaml Configuration

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  flame_audio: ^2.1.0

flutter:
  assets:
    - assets/audio/sfx/
    - assets/audio/music/
```

---

## 🎮 Usage Examples

```dart
// In-game usage:
audioManager.playEatPrey(comboLevel: 3); // Pitch varies with combo
audioManager.playFuryActivate(); // Epic sound!
audioManager.setMusicIntensity(MusicIntensity.fury); // Switch music layer

// Settings:
audioManager.setSfxVolume(0.7);
audioManager.setMusicVolume(0.5);
audioManager.toggleMusic(true);
```

---

## 🎵 Audio Budget Estimate

### Free Option:
- All assets from free resources: **$0**
- Time investment: ~10-15 hours

### Budget Option:
- Envato Elements (1 month): **$16.50**
- Time investment: ~5-8 hours

### Professional Option:
- Commission SFX pack: **$150**
- Commission music suite: **$400**
- Total: **$550**

---

## ✅ Quality Checklist

Before adding audio to game:
- [ ] All files properly named
- [ ] File sizes optimized (<25MB total)
- [ ] Music loops seamlessly (no clicks)
- [ ] SFX volumes balanced
- [ ] No audio clipping/distortion
- [ ] Tested on multiple devices
- [ ] Crossfades smooth
- [ ] Pitch variations sound natural

---

**Audio system is READY - just add the files and the game comes alive! 🎵🔥**
