# Illness & Injury System (Debuffs & Stasis)

> [!NOTE]
> **Home:** [[04 - LifeOS DevDocs/Home|Home]] | **Related:** [[04 - LifeOS DevDocs/RPG_PLAYER_CARD_SYSTEM|RPG Player Card]]

This document defines the mechanics for handling real-life debuffs through Illness and Injury states, modifying the base progression loops in the LifeOS RPG system.

## 1. System States & Mechanics

The system introduces four explicit states with distinct mechanical implications for XP, penalties, and task completion.

### 1.1. Stasis Mode (Hospitalization)
A complete system freeze intended for severe conditions.
- **XP Decay:** 0%
- **Penalties:** Frozen (no atrophy, no habit loss)
- **Habits:** All habits are protected and maintain their current streak.

### 1.2. Physical Injury
Applies a targeted debuff on physical attributes while allowing mental growth.
- **Task Locking:** Locks all Stamina/Strength categorized tasks.
- **Atrophy Protection:** Protects Stamina/Strength stats from atrophy during the injury duration.
- **Mental Growth:** Intelligence and Charisma tasks remain unlocked and can grow normally.
- **Visual Debuff:** Applies a -50% visual modifier to affected physical stats in the UI.

### 1.3. Mild Illness
A partial debuff that tests willpower and endurance.
- **XP Decay:** 50% reduction in base XP decay.
- **Atrophy Grace:** Doubles the atrophy grace days buffer.
- **Willpower Bonus:** +200% Willpower XP for completing *any* task while the sick state is active.

## 2. Recovery Mechanics

Recovery duration is dynamic, influenced by the player's Willpower attribute.

### 2.1. Recovery Formula
The actual time spent in a debuff state is reduced by a high Willpower stat.

Actual Days = BaseDays * (1 - min(WP, 150) / 300)

**Variables:**
- **BaseDays:** The base duration assigned to the injury or illness.
- **WP:** Current Willpower attribute level. Cap applied at 150 for the calculation, meaning maximum possible reduction is 50%.
