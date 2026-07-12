package illness

import (
	"encoding/json"
	"log"
	"os"
	"sync"
)

var (
	illnessLock    sync.RWMutex
	currentIllness *IllnessState
	illnessFile    = "./data/illness.json"
)

func init() { loadIllness() }

func loadIllness() {
	illnessLock.Lock()
	defer illnessLock.Unlock()
	data, err := os.ReadFile(illnessFile)
	if err != nil {
		if os.IsNotExist(err) {
			os.MkdirAll("./data", 0755)
			return
		}
		log.Printf("Error reading illness.json: %v", err)
		return
	}
	json.Unmarshal(data, &currentIllness)
}

func saveIllness() {
	data, _ := json.MarshalIndent(currentIllness, "", "  ")
	os.WriteFile(illnessFile, data, 0644)
}

func GetIllness() *IllnessState {
	illnessLock.RLock()
	defer illnessLock.RUnlock()
	if currentIllness == nil {
		return nil
	}
	c := *currentIllness
	return &c
}

func SetIllness(state *IllnessState) {
	illnessLock.Lock()
	defer illnessLock.Unlock()
	currentIllness = state
	saveIllness()
}

func ClearIllness() {
	illnessLock.Lock()
	defer illnessLock.Unlock()
	currentIllness = nil
	saveIllness()
}
