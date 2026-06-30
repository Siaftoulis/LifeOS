# Leveling Formulas

> [!NOTE]
> **Home:** [[04 - LifeOS DevDocs/Home|Home]] | **Related:** [[04 - LifeOS DevDocs/RPG_PLAYER_CARD_SYSTEM|RPG Player Card]]

This document standardizes the formulas for converting between raw XP and Player Levels, including saturation points based on age.

## 1. Core Level & XP Conversion

### Lifetime XP Calculation
Given a target level `L`, the total lifetime XP required is:
`LifetimeXP = floor(50 * L^1.8)`

### Inverse: Raw Level from XP
Given a total `XP`, the raw level (without soft cap) is:
`L_raw = floor((XP / 50)^0.55)`

## 2. XP Saturation (Biological Soft Cap)
The raw level is saturated by the biological cap `BC`, creating an asymptotic approach to the maximum capability for a given age.

`Level = floor(BC * (1 - e^(-L_raw / BC)))`

This ensures that as players approach their biological cap, gaining actual levels requires exponentially more XP.
