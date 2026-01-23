# 🦖 Triassic Evolution

> **A 2D Idle Simulation Game built with Godot 4.5**
> *Thesis Project: Interactive Simulation of Triassic Evolutionary Biology*

## 📖 About The Project

**Triassic Evolution** is an idle strategy game that challenges players to reconstruct the prehistoric ecosystem of the Triassic Period. Unlike standard clicker games, this project implements a **Multi-Dependency Evolution System**, requiring players to align biological research, habitat terraforming, and phylogenetic lineage to unlock new species.

The game features a dynamic **Food Web Synergy** mechanic, ensuring players must maintain a balanced ecosystem of predators and prey.

---

## 🎮 Key Features

### 🧬 The Multi-Dependency System
Species are not simply bought; they are "discovered" based on scientific conditions:
* **Lineage:** Must own the direct evolutionary ancestor (e.g., *Lagosuchus* → *Eoraptor*).
* **Biology:** Must research specific traits (e.g., *Hollow Bones*, *Serrated Teeth*) via the Research Tree.
* **Habitat:** Must terraform the environment to support life (e.g., *Ephemeral Pools*, *Conifer Forests*).

### 🎨 Prehistoric UI & Immersion
* **Themed Interface:** Custom "Slate & Fern" aesthetic with grounded colors and rounded, organic UI elements.
* **Abbreviated Currencies:** Clean UI supporting massive scale (e.g., "1.5m DNA", "10b Fossils").
* **Dynamic Biomes:** The world background evolves visually as you upgrade vegetation density (Desert -> Oasis -> Jungle).

### ⚖️ Ecosystem Balance Logic
* **Trophic Levels:** Carnivores require a specific ratio of Herbivores to sustain themselves.
* **Hunger Mechanic:** If the predator/prey ratio creates an imbalance, passive DNA generation stops, forcing strategic population management.
* **Offline Progression:** Earn DNA while away (requires Cloud Save).

### ☁️ Cloud & Persistence
* **Supabase Integration:** Secure cloud saving and authentication.
* **Cross-Session Persistence:** Quests and game state save automatically.

---

## 🛠️ Technical Stack

* **Engine:** Godot 4.5
* **Language:** GDScript
* **Backend:** Supabase (Auth & Database)
* **Architecture:**
	* **Resource-Based Data:** All Units, Traits, and Tasks are modular `.tres` files.
	* **Event-Driven UI:** Decoupled UI systems using Signals.
	* **Autoload Managers:** Global Singletons for Economy, Auth, Quests, and Save/Load.

---

## 📂 Project Structure

```text
res://
├── assets/                 # Sprites, Backgrounds, Audio
├── resources/              # The Data (ScriptableObjects)
│   ├── dinosaurs/          # .tres files for every species
│   ├── research/           # .tres files for tech tree nodes
│   ├── habitats/           # .tres files for land features
│   └── tasks/              # .tres files for quests
├── scenes/                 
│   ├── ui/                 # Reusable panels (ShopPanel, ResearchMenu)
│   ├── world/              # MainGame.tscn
│   └── units/              # DinoUnit.tscn
└── scripts/
	├── managers/           # GameManager.gd, AuthManager.gd, QuestManager.gd
	└── ui/                 # UI Controllers
```

---

## 🚀 How to Run

1. **Prerequisites**: Godot Engine 4.5+ (Standard Version).
2. **Clone**: Clone the repository.
3. **Open**: Import the `project.godot` file.
4. **Config**: Ensure `secrets.cfg` is present (for Cloud Auth) or rely on the built-in fallback mode.
5. **Run**: Press F5 to launch the main scene.

---

## 🕹️ Controls & Cheats

- **Tap/Click Background**: Collect active DNA (Emergency income).
- **Tap/Click Dinosaur**: Collect bonus DNA.
- **Time Warp**: Spend Fossils in Settings to skip time.

## 📝 Thesis Information
**Title:** Triassic Evolution: An Interactive Simulation of Triassic Biology

**developers:**
- Ciriaca, Kyle Justin D.
- Liwanag, Amiel D.

**Institution:** Immaculate Conception I-College, Philippines
**Date:** 2026

**License**: Educational / Thesis Defense Purposes.
