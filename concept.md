# [cite_start]Triassic Evolution: Reborn [cite: 1]

## Project Overview
* [cite_start]**Genre:** 2D Idle Strategy / Simulation [cite: 3]
* [cite_start]**Platform:** Mobile (Android/iOS) Landscape [cite: 4]
* [cite_start]**Engine:** Godot 4.5.1 [cite: 5]
* [cite_start]**Visual Style:** 16-Bit Pixel Art "Living Terrarium" [cite: 6]
* [cite_start]**Core Goal:** Evolve a balanced ecosystem, harvest premium fossils, and prestige to the next era[cite: 7].

---

## [cite_start]1. The Economy (Dual Currency) [cite: 8]

### [cite_start]A. DNA (Soft Currency) [cite: 9]
* [cite_start]**Role:** The standard resource for growth[cite: 10].
* [cite_start]**Source (Active):** Clicking the environment or dinosaurs[cite: 11].
* [cite_start]**Source (Passive):** Generated every second by living dinosaurs[cite: 13].
* **Usage:**
    * [cite_start]**Spawning:** Buying new dinosaur units from the Lineage Tab[cite: 14].
    * [cite_start]**Research:** Unlocking new nodes in the Phylogenetic Tree[cite: 14].
    * [cite_start]**Habitat:** Increasing Vegetation and Critter density[cite: 15].

### [cite_start]B. Fossils (VIP / Premium Currency) [cite: 16]
* [cite_start]**Role:** The "Hard Currency" representing rare scientific discovery[cite: 18].
* **Source:**
    * [cite_start]**Harvesting:** Clicking a dinosaur skeleton after death (+1 Fossil)[cite: 19].
    * [cite_start]**Extinction:** Resetting the game grants a huge payout based on progress[cite: 20].
    * [cite_start]**Rare Events:** Small chance to find a fossil when clicking dirt[cite: 21].
* **Usage:**
    * [cite_start]**Time Warps:** Instantly skip 1 hour of game time[cite: 24].
    * [cite_start]**Golden Eggs:** Instantly spawn a high-tier dinosaur without DNA[cite: 25].
    * [cite_start]**Permanent Upgrades:** Buy "Global Multipliers" that persist across resets[cite: 26].

---

## [cite_start]2. The Core Loop [cite: 27]

1.  [cite_start]**Gather:** Collect DNA from clicking and passive income[cite: 28].
2.  [cite_start]**Research:** Spend DNA to unlock traits and new species in the Tree[cite: 29].
3.  [cite_start]**Expand:** Terraform the land (Vegetation/Critters) to support new life[cite: 30].
4.  [cite_start]**Cycle:** Dinosaurs live, eat, and die[cite: 31].
    * [cite_start]*Harvest:* Collect bones for Fossils[cite: 33].
5.  [cite_start]**Spend VIP:** Use Fossils to skip waiting times or buy boosts[cite: 34].
6.  [cite_start]**Extinction:** Trigger the meteor to reset the map and gain a massive Fossil reward[cite: 35].

---

## [cite_start]3. System A: The Dynamic Habitat [cite: 36]

* [cite_start]**Density System:** Manage global "Vegetation %" and "Critter %"[cite: 37].
* [cite_start]**Visuals:** As density rises, trees and rocks "pop" into existence automatically[cite: 38].

### Phases
* [cite_start]**0-30%:** Desert (Red)[cite: 40].
* [cite_start]**31-60%:** Oasis (Green)[cite: 41].
* [cite_start]**61-100%:** Jungle (Dark Green)[cite: 42].

---

## [cite_start]4. System B: Ecosystem & AI [cite: 43]

* **Diet:** Herbivores eat Vegetation. [cite_start]Carnivores eat Critters[cite: 44].
* [cite_start]**The Desperation Rule:** If a Carnivore is hungry and Critter Density is 0%, it will hunt and kill a Herbivore unit[cite: 45].
* [cite_start]**Environmental Mortality:** Dinosaurs have an Ideal Biome Phase[cite: 46].
    * [cite_start]*Note:* If they live in the wrong phase (e.g., Jungle Dino in Desert), they age 3x faster and die quickly[cite: 46].

---

## [cite_start]5. System C: Progression (Research Tree) [cite: 47]

* [cite_start]**Structure:** A branching web starting from Archosaur[cite: 49].
* [cite_start]**Unlock Cost:** DNA[cite: 50].
* [cite_start]**Requirement:** To unlock a node, you must own the Parent Node and have enough DNA[cite: 51].
* [cite_start]**Breakthrough:** Unlocking a species grants 1 free unit[cite: 52].

---

## [cite_start]6. Data Tables (The Balance) [cite: 53]

### [cite_start]A. Dinosaur Roster [cite: 54]

| Species | Diet | Biome Phase | DNA Cost | Yield/Click | Passive/Sec | Description |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Archosaur** | Herbivore | 1 (Desert) | 10 | 1 | 1 | [cite_start]"The hardy ancestor." [cite: 55] |
| **Lagosuchus** | Carnivore | 1 (Desert) | 50 | 3 | 2 | [cite_start]"Small, agile runner." [cite: 56] |
| **Eoraptor** | Herbivore | 2 (Oasis) | 150 | 8 | 5 | [cite_start]"Thrives near water." [cite: 56] |
| **Herrerasaurus** | Carnivore | 2 (Oasis) | 400 | 15 | 12 | [cite_start]"Ambush predator." [cite: 56] |
| **Panphagia** | Herbivore | 2 (Oasis) | 600 | 25 | 25 | [cite_start]"Transition grazer." [cite: 56] |
| **Coelophysis** | Carnivore | 2 (Oasis) | 850 | 35 | 40 | [cite_start]"Fast pack hunter." [cite: 56] |
| **Plateosaurus** | Herbivore | 3 (Jungle) | 1,000 | 50 | 100 | [cite_start]"High browser giant." [cite: 56] |
| **Liliensternus** | Carnivore | 3 (Jungle) | 2,500 | 120 | 250 | [cite_start]"Jungle apex." [cite: 56] |
| **Riojasaurus** | Herbivore | 3 (Jungle) | 5,000 | 250 | 500 | [cite_start]"The Game Ender." [cite: 56] |

### [cite_start]B. Habitat Features [cite: 57]

| Feature | Type | DNA Cost | Density Gain | Description |
| :--- | :--- | :--- | :--- | :--- |
| **Fern Bundle** | Vegetation | 25 | +10% | [cite_start]"Basic ground cover." [cite: 58] |
| **Cycad Crate** | Vegetation | 100 | +50% | [cite_start]"Dense foliage." [cite: 58] |
| **Jar of Beetles** | Critters | 40 | +15% | [cite_start]"Snack for small hunters." [cite: 58] |
| **Dragonfly Swarm** | Critters | 150 | +60% | [cite_start]"High protein feast." [cite: 58] |

---

## [cite_start]7. Development Roadmap [cite: 59]

[cite_start]We will implement this in layers, starting with the Foundation[cite: 60].

* [cite_start]**Sprint 1:** The Foundation (Project Setup, DNA Logic, Clicker)[cite: 61].
* [cite_start]**Sprint 2:** The First Life (Dino Data, Spawning, Movement)[cite: 61].
* [cite_start]**Sprint 3:** The Living World (Habitat Density, Visual Pop-in)[cite: 62].
* [cite_start]**Sprint 4:** Mortality & VIP Economy (Death, Fossils, Premium Shop)[cite: 62].
* [cite_start]**Sprint 5:** Intelligence (Hunger, Predation AI, Environmental Stress)[cite: 63].
* [cite_start]**Sprint 6:** Research Tree (UI, Progression Logic)[cite: 63].
* [cite_start]**Sprint 7:** Extinction (Reset Loop)[cite: 64].