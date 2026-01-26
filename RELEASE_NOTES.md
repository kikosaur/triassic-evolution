# Triassic Evolution v2.1.0 - The Extinction Update ☄️🦕

**Triassic Evolution v2.1.0** brings major gameplay depth, system stability, and the long-awaited conclusion to the era: The Extinction Event. This update focuses on realism in dinosaur behavior, performance optimizations for large parks, and a robust offline-capable save system.

## 🌟 New Features

### ☄️ Extinction & Endgame
- **Manual Extinction Trigger**: A new unlockable button in the **Settings Panel** allows you to end the era on your own terms.
  - **Unlock Condition**: Requires **All Research Unlocked** AND **All Quests Completed**.
  - **Reset Logic**: Properly resets the Year counter and all Tasks for a fresh start.
- **Improved Win State**: The game now actively tracks your 100% completion status.

### 🥩 Enhanced Ecology & Behavior
- **Predator Hunting Logic**: Carnivores now strictly monitor the **Critter (Meat) Supply**.
  - If Critters hit **0%**, Carnivores enter **Hunt Mode** and will attack Herbivores every 20-30 seconds.
  - Increased Carnivore **Charge Speed** for dynamic, fast-paced attacks.
- **Herbivore Starvation**: Herbivores now react to **Vegetation depletion (0%)** by stomping their feeding behavior and wandering in search of food.
- **Stuck Prevention**: Fixed issues where dinosaurs could get stuck in eating animations loop.

## ⚡ Optimizations & Stability

### 💾 Hybrid Save System (Offline Support)
- **Offline Backup**: The game now **always** creates a local backup (`offline_save.json`) every 60 seconds and on Quit. You can keep playing safely even without an internet connection.
- **Smart Compression**: Optimized save file structure (rounding coordinates and age), significantly reducing file size and load times for large parks.

### 🚀 Performance
- **Cached Predation Pathfinding**: Implemented `O(1)` access lists for hunting logic. Carnivores no longer scan the entire entity list to find prey, drastically reducing lag during mass extinction events.

## 📱 System Requirements (Android)

**Minimum Requirements:**
- **OS**: Android 10 or higher
- **RAM**: 3 GB
- **Storage**: ~150 MB available space
- **Processor**: Snapdragon 660 / Exynos 9611 or equivalent
- **Graphics**: OpenGL ES 3.0 compatible GPU

**Recommended Requirements:**
- **OS**: Android 12 or higher
- **RAM**: 6 GB
- **Processor**: Snapdragon 865 / Dimensity 1200 or better
- **Screen**: 1080p resolution for best UI scaling

---
*Thank you for playing Triassic Evolution! If you encounter any issues, please report them on the Issues tab.*
