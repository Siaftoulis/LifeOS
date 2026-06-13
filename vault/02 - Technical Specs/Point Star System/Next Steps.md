# Next Steps | Point Star System

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Point Star System|Point Star System]]

## 1. Backend Implementation (Beyond Stubs)
- **True Server-Authoritative Ledger:** The Go Daemon must persist the `PointsLedger` table into its own local SQLite database (`host-daemon/data/lifeos.db`) so that if the mobile client is wiped, the points balance is restored from the host.
- **Webhook Web-Lock:** The TV Lockout webhook must be integrated with the actual Home Management module to physically cut power to the TV via IoT plugs when balance drops to zero.

## 2. Data Interconnectivity & Relationships
- **Global Nexus:** Every single module (Habits, YouTube, Movies, Music, Zen Editor) routes its gamification hooks into this central ledger. It is the heart of the LifeOS gamification engine.

## 3. Open Design Questions
1. Should there be a "bankruptcy" mechanic if points fall too deeply into the negative, or just an indefinite lockout until habits are completed?
2. Do you want to implement specific Vouchers (e.g., "Cheat Day" or "Order Pizza") that can be redeemed for a high point cost?
