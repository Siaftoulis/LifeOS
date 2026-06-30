# RPG Player Card & Stats System

> [!NOTE]
> **Home:** [[04 - LifeOS DevDocs/Home|Home]] | **Related:** [[04 - LifeOS DevDocs/LEVELING_FORMULAS|Leveling Formulas]]

This document outlines the core RPG mechanics, defining the biological soft cap, stat attributes, and task flow distribution.

## 1. Attributes
The system utilizes five core attributes, each with distinct growth potential:
- **Stamina:** Anatomical cap at level 18.
- **Intelligence:** No age cap.
- **Focus:** Standard leveling curve.
- **Charisma:** No age cap.
- **Willpower:** Uncapped. Acts as a core modifier for recovery and decay resistance.

## 2. Progression Systems

### 2.1. Level System & Biological Soft Cap
The maximum level a player can achieve before saturation drops XP gains severely is determined by their age.
`BC(Age) = floor(100 / (1 + e^(-0.08 * (Age-15))))`

### 2.2. Task Flow Mechanics
When a task is completed, rewards are distributed across three distinct vectors:
- **Points:** Allocated to the Star Wallet for economy usage.
- **XP:** Allocated to the overall Level calculation.
- **Attribute XP:** Directed to the specific attribute governing the completed task.
