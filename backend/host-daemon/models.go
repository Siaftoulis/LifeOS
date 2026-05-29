package main

// ActionPayload represents the incoming JSON RPC command payload
type ActionPayload struct {
	ActionType string `json:"action_type"`
	TargetID   string `json:"target_id,omitempty"`
	Timestamp  int64  `json:"timestamp"`
	Signature  string `json:"signature"`
}

// ActionResponse represents the JSON output sent back to the client
type ActionResponse struct {
	Status  string `json:"status"`
	Message string `json:"message"`
}

// VMInfo represents the state of a queried Hyper-V Virtual Machine
type VMInfo struct {
	Name  string `json:"Name"`
	State int    `json:"State"`
}
