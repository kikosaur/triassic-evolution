# Triassic Evolution: Feature & Function Documentation
**Thesis Project: Interactive Simulation of Triassic Evolutionary Biology**

---

## 1. Project Overview
**Triassic Evolution** is a 2D strategy simulation game that gamifies the evolutionary history of the Triassic period. It is designed to be educational, demonstrating biological concepts such as **Phylogeny** (evolutionary trees), **Trophic Levels** (food webs), and **Ecosystem Balance** through interactive gameplay mechanics.

---

## 2. Core Gameplay Systems

### A. The Ecosystem (Food Web)
The game simulates a fragile ecosystem where every unit relies on a lower trophic level.

*   **Vegetation (Producers):** The foundation of life.
    *   *System:* Players spend DNA to increase `Vegetation Density`.
    *   *Usage:* Consumed by Herbivorous dinosaurs. If density hits 0%, herbivores starve.
*   **Critters (Primary Consumers):** Small insects and lizards.
    *   *System:* Players spend DNA to increase `Critter Density`.
    *   *Usage:* Consumed by Carnivorous dinosaurs.
*   **Starvation Mechanics:**
    *   **Timer:** Every dinosaur has a 5-minute starvation timer.
    *   **Feeding:** Eating correctly (Herbivore → Plants, Carnivore → Critters) resets the timer.
    *   **Visual Feedback:** A **Warning System** alerts the player when < 60 seconds remain. ("The Herbivores will die in 00:45").
    *   **Consequence:** If the timer reaches 0, the dinosaur dies permanently, leaving only a fossil.

### B. Evolutionary Progression (The Tech Tree)
Unlike standard games where units are simply bought, species in Triassic Evolution must be **Evolved**.

*   **Phylogenetic Lineage:** The research tree follows real scientific ancestry. You cannot unlock a descendant (e.g., *Eoraptor*) without first unlocking its ancestor (*Lagosuchus*).
*   **Traits:** Players must research evolutionary adaptations (Nodes) to progress:
    *   *Examples:* "Hollow Bones", "Serrated Teeth", "Quadrupedalism".
*   **Habitat Requirements:** Advanced species require specific environmental phases (Desert → Oasis → Jungle) to unlock.

### C. The Economy (Dual Currency)
*   **DNA (Soft Currency):**
    *   *Source:* Generated passively by living dinosaurs and actively by clicking.
    *   *Function:* Used for basic growth (buying units, researching traits, planting vegetation).
*   **Fossils (Hard/Prestige Currency):**
    *   *Source:* Found rarely by excavating dead dinosaurs, or earned by triggering Extinction.
    *   *Function:* Used for high-tier upgrades and "Time Warps" (skipping time).

### D. The Extinction Cycle (Prestige)
*   **The Loop:** The game does not end; it cycles.
*   **Trigger:** Players manually trigger a "Mass Extinction Event" when they have reached the peak of the era.
*   **Reward:** The world resets, but the player gains **Fossils** and a **Prestige Multiplier**, making the next evolution run faster and allowing for deeper exploration.

---

## 3. Technical Implementation

### A. Global Managers (Singleton Pattern)
The game uses a centralized architecture managed by `GameManager.gd`.
*   **State Tracking:** Tracks global variables (`current_dna`, `vegetation_density`, `unlocked_research`).
*   **Signal Bus:** Uses Godot's Signal system to decouple UI from Logic. Use cases: `dinosaur_died`, `research_unlocked`, `habitat_updated`.

### B. Data Persistence (Save/Load)
*   **Cloud Integration:** Connects to **Supabase** for cross-device cloud saving.
*   **Offline Earnings:** The game calculates time passed since the last login (`Time.get_unix_time_from_system()`).
    *   *Logic:* It simulates consumption and growth for the offline duration, awarding DNA for the time away—but only if the ecosystem was balanced enough to sustain it.

### C. Dynamic AI (DinoUnit)
Each dinosaur is an independent agent (`DinoUnit.gd`).
*   **Choosing Actions:** Uses a customized State Machine (Idle → Move → Eat → Hunt).
*   **Smart Hunting:** Carnivores check the global entity list to find the *nearest* herbivore when hungry.
*   **Lifespan:** Dinosaurs age in real-time. If they live in a "Mismatched Biome" (e.g., a Swamp dino in a Desert), they age 2x faster (Stress Mechanic).

### D. Warning System (Observer UI)
A dedicated UI system (`WarningSystem.gd`) observes the game state every frame.
*   **Aggregator:** It groups issues by type (Starvation, Depletion, Stress).
*   **Priority:** Critical issues (Death imminent) pulse Red; Warnings are Orange; Info is Green.
*   **Feedback:** Provides clear, actionable text to the player ("The Carnivores will die in 02:00").

---

## 4. User Interface Functions

| Feature | Function |
| :--- | :--- |
| **Research Panel** | Visualizes the evolutionary tree. Shows locked/unlocked paths and costs. |
| **Shop Panel** | Interface for spending DNA on Habitat (Vegetation/Critters) and managing population caps. |
| **Museum** | Educational archive. Displays 3D-style frames of unlocked species with scientific facts. |
| **Settings** | Controls for Audio, Save Management, and the Extinction Trigger. |
| **Alert Button** | A dedicated "!" button that reveals the Warning Panel when held, showing critical ecosystem status. |

---

**Developed for Thesis Defense 2026**
*Immaculate Conception I-College*
