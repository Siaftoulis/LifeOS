package main

import (
	"fmt"
	"net"
)

// BroadcastMagicPacket parses a MAC address, constructs the 0xFF packet, and broadcasts it dynamically.
func BroadcastMagicPacket(macStr string) error {
	mac, err := net.ParseMAC(macStr)
	if err != nil {
		return fmt.Errorf("invalid MAC: %v", err)
	}

	var packet []byte
	for i := 0; i < 6; i++ {
		packet = append(packet, 0xFF)
	}
	for i := 0; i < 16; i++ {
		packet = append(packet, mac...)
	}

	ifaces, err := net.Interfaces()
	if err != nil {
		return err
	}

	successCount := 0
	for _, iface := range ifaces {
		if iface.Flags&net.FlagUp == 0 || iface.Flags&net.FlagLoopback != 0 || iface.Flags&net.FlagBroadcast == 0 {
			continue
		}
		addrs, _ := iface.Addrs()
		for _, addr := range addrs {
			if ipnet, ok := addr.(*net.IPNet); ok && ipnet.IP.To4() != nil {
				ip := ipnet.IP.To4()
				mask := ipnet.Mask
				bcast := net.IPv4(ip[0]|^mask[0], ip[1]|^mask[1], ip[2]|^mask[2], ip[3]|^mask[3])
				sendUDP(bcast.String(), packet)
				successCount++
			}
		}
	}

	if successCount == 0 {
		sendUDP("255.255.255.255", packet) // Universal fallback
	}
	return nil
}

func sendUDP(ip string, packet []byte) {
	addr, _ := net.ResolveUDPAddr("udp", fmt.Sprintf("%s:9", ip))
	conn, _ := net.DialUDP("udp", nil, addr)
	if conn != nil {
		conn.Write(packet)
		conn.Close()
	}
}
