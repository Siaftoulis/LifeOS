package player

import (
	"log"
	"lifeos/host-daemon/internal/points"
)

type TaskCompletion struct {
	TaskID     string
	Attribute  string // "Stamina", "Intelligence", "Focus", "Charisma", "Willpower"
	BaseXP     int
	BasePoints int
	IsSick     bool
}

type TaskReward struct {
	PointsAdded      int
	XPAdded          int
	AttributeXPAdded int
	AttributeName    string
}

// ProcessTaskCompletion distributes rewards based on system rules
func ProcessTaskCompletion(task TaskCompletion) TaskReward {
	reward := TaskReward{
		PointsAdded:      task.BasePoints,
		XPAdded:          task.BaseXP,
		AttributeXPAdded: task.BaseXP, // Attribute XP scales 1:1 with base XP as a default
		AttributeName:    task.Attribute,
	}

	// Mild Illness modifier: +200% Willpower XP for completing ANY task
	if task.IsSick {
		reward.AttributeName = "Willpower"
		reward.AttributeXPAdded = task.BaseXP * 3 // 100% base + 200% bonus
		log.Printf("Illness Modifier applied: Willpower XP boosted by 200%% for task %s", task.TaskID)
	}

	// Apply decay first
	ApplyDecay()

	// Here we interface with the DB to save the ledger changes
	UpdatePlayerXP(reward.XPAdded)
	UpdateAttributeXP(reward.AttributeName, reward.AttributeXPAdded)
	points.AddPoints("panospds", reward.PointsAdded) // Using a hardcoded ID for now since auth is proxy based

	return reward
}
