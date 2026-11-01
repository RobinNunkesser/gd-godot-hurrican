# Hurrican Godot 4 (2D Action Platformer Remake)

> **Genre:** 2D Run-and-Gun Sci-Fi Action Platformer  
> **Engine:** Godot Engine 4.x (Forward+ / Mobile / Web Compatibility)  
> **Vorbild:** *Hurrican* (Poke53280 / Eiswuxe, 2007) & *Turrican* (Manfred Trenz, Rainbow Arts / Factor 5)  
> **Referenz-Codebase:** `artifacts/references/external/Hurrican` (C++ / SDL2)  
> **Development Standard:** Spec-Driven Intent-Engineering nach Vorlesung *07: Agentic Game Development*

---

## 🎮 High Concept

Ein modernes, plattformunabhängiges Godot-4-Remake des legendären Jump-and-Shoot-Klassikers *Hurrican*.  
Dieses Projekt implementiert die charakteristische Physik, das ikonische Waffen-Arsenal, die Morph-Kugel (*Gyro-Wheel*) und den 360°-Rundum-Blitzstrahl (*Lightning Beam*) mit nativer Unterstützung für macOS, Linux, Windows und WebAssembly (GitHub Pages).

---

## 🕹️ Steuerung

| Aktion | Tastatur | Gamepad |
| :--- | :--- | :--- |
| **Laufen ($X$)** | `A` / `D` bzw. `Pfeiltasten` | Linker Analogstick / D-Pad |
| **Ducken ($Y$)** | `S` / `Pfeiltaste Unten` | Linker Analogstick Runter |
| **Zielen (Oben / Diagonal)** | `W` / `Pfeiltaste Oben` (+ `A`/`D`) | Linker Analogstick Oben / Schräg |
| **Springen** | `Leertaste` bzw. `X` | Button A (Kreuz) |
| **Standard-Feuer** | `J` bzw. `C` / Linksklick | Button X (Viereck) |
| **360° Rundum-Blitzstrahl** | `K` bzw. `V` / Rechtsklick | Button Y (Dreieck) + Rechter Stick |
| **Gyro-Wheel (Stachelrad)** | `L` bzw. `Shift` / `S` + `Sprung` | Button B (Kreis) |
| **Waffen-Wechsel** | `E` bzw. `Tab` | Schultertaste RB / R1 |

---

## 🏗️ Projekt-Architektur

- **`scripts/hurrican_config.gd` (`HurricanConfig`):** Zentral isolierte Parameter für Kinematik, Sprunghöhe, Waffen-Timings und Energie-Drain/Recharge.
- **`scripts/player.gd` (`HurricanPlayer`):** `CharacterBody2D` mit vollständiger State Machine (`IDLE`, `RUN`, `JUMP`, `CROUCH`, `WHEEL`, `LIGHTNING`), Spritesheet-Steuerung und Kollisionsform-Anpassung.
- **`scripts/lightning_beam.gd` (`LightningBeam`):** Prozeduraler 360°-Elektroblitz mit `RayCast2D` für Echtzeit-Kollision und `Line2D` mit dynamischem Jitter-Effekt.
- **`scripts/bullet.gd` (`HurricanBullet`):** Projektil-System für Spread-Shot (Fächer), Laser (Durchdringung) und Bounce-Shot (Wandreflexion).
- **`scripts/dummy_target.gd` (`DummyTarget`):** Zerstörbare Übungsdrohne mit Trefferblitz und Explosions-Audio.
- **`scripts/hud.gd` (`HurricanHUD`):** Retro-Anzeige für Schild-Energie, Rad-Batterie, aktive Waffe und Steuerungsübersicht.
- **`scenes/main.gd`:** Dynamische Test-Arena mit Sprungplattformen, 45°-Schrägen, Parallax-Dschungelhintergrund und Kamera-Smoothing.

---

## 🧪 Headless CI/CD & Unit Tests

Das Projekt verfügt über einen vollständig headless lauffähigen Test-Runner in Godot 4:

```bash
godot --headless -s test_gameplay.gd
```
Exits mit `0` bei Erfolg.

