package system

import (
	"encoding/json"
	"log"
	"os/exec"
)

type Node struct {
	IP     string `json:"ip"`
	Name   string `json:"name"`
	Online bool   `json:"online"`
}

type TailscaleStatus struct {
	Peer map[string]TailscalePeer `json:"Peer"`
}

type TailscalePeer struct {
	HostName     string   `json:"HostName"`
	TailscaleIPs []string `json:"TailscaleIPs"`
	Online       bool     `json:"Online"`
}

func QueryTailscaleNodes() ([]Node, error) {
	cmd := exec.Command("tailscale", "status", "--json")
	out, err := cmd.Output()
	if err != nil {
		log.Printf("Tailscale CLI error: %v", err)
		return nil, err
	}

	var status TailscaleStatus
	if err := json.Unmarshal(out, &status); err != nil {
		return nil, err
	}

	var nodes []Node
	for _, peer := range status.Peer {
		ip := ""
		if len(peer.TailscaleIPs) > 0 {
			ip = peer.TailscaleIPs[0]
		}
		nodes = append(nodes, Node{
			IP:     ip,
			Name:   peer.HostName,
			Online: peer.Online,
		})
	}
	return nodes, nil
}
