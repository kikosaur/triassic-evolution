# 🦖 Triassic Evolution

> **A 2D Idle Simulation Game built with Godot 4.x** > *Thesis Project: Interactive Simulation of Triassic Evolutionary Biology*

![Game Banner](https://via.placeholder.com/800x200?text=Triassic+Evolution+Banner) 
*(Replace this link with a screenshot of your game running)*

## 📖 About The Project

**Mesozoic Evolution** is an idle strategy game that challenges players to reconstruct the prehistoric ecosystem of the Triassic Period. Unlike standard clicker games, this project implements a **Multi-Dependency Evolution System**, requiring players to align biological research, habitat terraforming, and phylogenetic lineage to unlock new species.

The game features a dynamic **Food Web Synergy** mechanic, ensuring players must maintain a balanced ecosystem of predators and prey rather than simply spamming high-tier units.

---

## 🎮 Key Features

### 🧬 The Multi-Dependency System
Species are not simply bought; they are "discovered" based on scientific conditions:
* **Lineage:** Must own the direct evolutionary ancestor (e.g., *Lagosuchus* → *Eoraptor*).
* **Biology:** Must research specific traits (e.g., *Hollow Bones*, *Serrated Teeth*).
* **Habitat:** Must terraform the environment to support life (e.g., *Ephemeral Pools*, *Conifer Forests*).

### 🌍 Dynamic Biome Pages
The game world expands visually as the player progresses:
1.  **Arid Scrubland:** The starting desert for ancestors.
2.  **Seasonal Oasis:** Unlocked by water upgrades; home to early dinosaurs.
3.  **Deep Jungle:** Unlocked by canopy upgrades; home to the giants.

### ⚖️ Ecosystem Balance Logic
* **Trophic Levels:** Carnivores require a specific ratio of Herbivores to sustain themselves.
* **Starvation Mechanic:** If the predator/prey ratio creates an imbalance, passive DNA generation drops by 90%, forcing strategic population management.

### ☄️ Extinction & Prestige
* **The Loop:** Upon reaching the late Triassic apex predators (*Riojasaurus* or *Liliensternus*), players can trigger the **Extinction Event**.
* **Fossils:** Resets the world in exchange for a permanent multiplier to evolution speed, simulating geological time scales.

---

## 🛠️ Technical Stack

* **Engine:** Godot 4.x
* **Language:** GDScript
* **Platform:** Windows / Android (Mobile Touch Supported)
* **Architecture:**
    * **Resource-Based Data:** All Units, Traits, and Tasks are modular `.tres` files for easy balancing.
    * **Event-Driven UI:** Decoupled UI systems using Signals for performance.
    * **Autoload Managers:** Global Singletons for Economy, Biomes, and Save/Load states.

---

## 📂 Project Structure

```text
res://
├── assets/                 # Sprites, Backgrounds, Audio
├── resources/              # The Data (ScriptableObjects)
│   ├── dinosaurs/          # .tres files for every species
│   ├── traits/             # .tres files for biological upgrades
│   ├── habitats/           # .tres files for land features
│   └── tasks/              # .tres files for the Field Guide
├── scenes/                 
│   ├── ui/                 # Reusable buttons (TraitButton, HabitatButton)
│   ├── managers/           # Logic controllers
│   ├── DinoUnit.tscn       # The visual walking dinosaur actor
│   └── MainGame.tscn       # The primary game loop scene
└── scripts/
    ├── managers/           # GameManager.gd, BiomeManager.gd, SaveManager.gd
    └── resources/          # Custom Resource definitions
```

---

## 🚀 How to Run

**Prerequisites**
Godot Engine 4.x (Standard Version)

**Installation**
1. Clone the Repository:
```git clone [https://github.com/YourUsername/mesozoic-evolution.git](https://github.com/YourUsername/mesozoic-evolution.git)```

2. Open in Godot:
- Launch Godot.
- Click Import.
- Navigate to the folder and select project.godot.

3. Play:

- Press F5 to run the project.
- (Note: The main scene is located at res://scenes/MainGame.tscn)

**Mobile Export**
1. Go to Project > Export.
2. Install the Android Build Template if prompted.
3. Connect an Android device with USB Debugging enabled.
4. Click the Android Icon in the top-right of the editor to One-Click Deploy.

---

## 🕹️ Controls & Cheats
- **Tap/Click Background:** Collect active DNA.
- **Tap/Click Dinosaur:** Collect bonus DNA and view Info Card.
- **Developer Menu:** Tap the Top-Right Corner of the screen 5 times fast to open the debug menu (Add DNA, Reset Save, etc.).

## 📝 Thesis Information
**Title:** Mesozoic Evolution: An Interactive Simulation of Triassic Biology

**Developer:**
- Ciriaca, Kyle Justin D.
- Liwanag, Amiel D.

**Institution:** Immaculate Conception I-College, Philippines

Date: 2025

This project was developed to demonstrate how game mechanics can be used to scaffold learning of complex biological systems, specifically phylogenetic trees and trophic interactions.

📄 License
This project is for educational and thesis defense purposes.
