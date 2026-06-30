# Attribute Atrophy Mechanics

> [!NOTE]
> **Home:** [[04 - LifeOS DevDocs/Home|Home]] | **Related:** [[04 - LifeOS DevDocs/RPG_PLAYER_CARD_SYSTEM|RPG Player Card]]

This document details the mechanics surrounding attribute decay and the compounding XP decay rate.

## 1. XP Decay
XP decays continuously if not actively engaged. The base decay rate is determined by the Willpower attribute, and the actual rate compounds based on consecutive days of inactivity.

- **Base Factor:** `Base = max(1.0, 2 - WP / 100)`
- **Compounding Rate:** `Rate = 1% * Base^(d - 1)`
  *(where `d` is the number of consecutive days inactive)*

## 2. Stat Atrophy
Specific attributes will begin to atrophy (lose XP/levels) if specific tasks tied to them are ignored.

- **Buffer Days:** `Buffer = 1 + floor(WP / 25)`
  *(High willpower delays the onset of atrophy)*
- **Atrophy Rate:** Once the buffer is exceeded, unattended stats lose `-1 point/day`.
