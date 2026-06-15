package location

import (
	"math"
)

type Point struct {
	Latitude  float64 `json:"lat"`
	Longitude float64 `json:"lon"`
}

type Geofence struct {
	ID       string  `json:"id"`
	Name     string  `json:"name"`
	Type     string  `json:"type"` // "circle" or "polygon"
	Latitude float64 `json:"lat,omitempty"`
	Longitude float64 `json:"lon,omitempty"`
	Radius   float64 `json:"radius,omitempty"`
	Polygon  []Point `json:"polygon,omitempty"`
	IsActive bool    `json:"is_active"`
}

type LocationReport struct {
	DeviceID  string  `json:"device_id"`
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	Velocity  float64 `json:"velocity,omitempty"`
	Altitude  float64 `json:"altitude,omitempty"`
	Timestamp int64   `json:"timestamp"`
}

type TriggeredGeofence struct {
	ID       string  `json:"id"`
	Name     string  `json:"name"`
	Distance float64 `json:"distance_meters"`
}

func haversineDistance(lat1, lon1, lat2, lon2 float64) float64 {
	const R = 6371000
	dLat := (lat2 - lat1) * math.Pi / 180
	dLon := (lon2 - lon1) * math.Pi / 180
	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1*math.Pi/180)*math.Cos(lat2*math.Pi/180)*
			math.Sin(dLon/2)*math.Sin(dLon/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
	return R * c
}

func pointInPolygon(pt Point, polygon []Point) bool {
	inside := false
	for i, j := 0, len(polygon)-1; i < len(polygon); i, j = i+1, i {
		if ((polygon[i].Longitude > pt.Longitude) != (polygon[j].Longitude > pt.Longitude)) &&
			(pt.Latitude < (polygon[j].Latitude-polygon[i].Latitude)*(pt.Longitude-polygon[i].Longitude)/(polygon[j].Longitude-polygon[i].Longitude)+polygon[i].Latitude) {
			inside = !inside
		}
	}
	return inside
}

func checkProximity(report LocationReport, fences []Geofence) []TriggeredGeofence {
	var triggered []TriggeredGeofence
	for _, f := range fences {
		if !f.IsActive {
			continue
		}
		
		if f.Type == "polygon" && len(f.Polygon) >= 3 {
			if pointInPolygon(Point{Latitude: report.Latitude, Longitude: report.Longitude}, f.Polygon) {
				triggered = append(triggered, TriggeredGeofence{
					ID:       f.ID,
					Name:     f.Name,
					Distance: 0, // Inside polygon
				})
			}
		} else {
			dist := haversineDistance(report.Latitude, report.Longitude, f.Latitude, f.Longitude)
			if dist <= f.Radius {
				triggered = append(triggered, TriggeredGeofence{
					ID:       f.ID,
					Name:     f.Name,
					Distance: math.Round(dist*100) / 100,
				})
			}
		}
	}
	return triggered
}

func defaultGeofences() []Geofence {
	return []Geofence{
		{ID: "g1", Name: "Home Base", Type: "circle", Latitude: 37.9838, Longitude: 23.7275, Radius: 150, IsActive: true},
		{ID: "g2", Name: "Work Polygon", Type: "polygon", Polygon: []Point{
			{37.9760, 23.7350}, {37.9765, 23.7350}, {37.9765, 23.7360}, {37.9760, 23.7360},
		}, IsActive: true},
	}
}
