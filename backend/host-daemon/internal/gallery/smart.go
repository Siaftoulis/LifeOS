package gallery

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"image"
	"sort"
	"strings"
	"time"

	"golang.org/x/image/draw"
)

// ----- "small AI model" v1: deterministic image analysis -----
// ponytail: rule-based heuristics (hash, colors, source, date, place).
// Upgrade path: swap in an on-device ML model later, same signatures.

// DHash computes a 64-bit perceptual hash: 9x8 grayscale resize, compare
// adjacent horizontal pixels. Identical/similar photos share a hash.
func DHash(img image.Image) string {
	dst := image.NewGray(image.Rect(0, 0, 9, 8))
	draw.CatmullRom.Scale(dst, dst.Bounds(), img, img.Bounds(), draw.Over, nil)

	var bits uint64
	for y := 0; y < 8; y++ {
		for x := 0; x < 8; x++ {
			bits <<= 1
			if dst.GrayAt(x, y).Y > dst.GrayAt(x+1, y).Y {
				bits |= 1
			}
		}
	}
	return fmt.Sprintf("%016x", bits)
}

// HashBytes is a content hash for non-decodable files (videos).
func HashBytes(b []byte) string {
	sum := sha256.Sum256(b)
	return hex.EncodeToString(sum[:])
}

// DominantColors downsamples to 8x8 and quantizes to 4-bit bins,
// returning the top N colors as hex strings.
func DominantColors(img image.Image, n int) []string {
	dst := image.NewRGBA(image.Rect(0, 0, 8, 8))
	draw.CatmullRom.Scale(dst, dst.Bounds(), img, img.Bounds(), draw.Over, nil)

	counts := map[uint32]int{}
	for y := 0; y < 8; y++ {
		for x := 0; x < 8; x++ {
			c := dst.RGBAAt(x, y)
			bin := (uint32(c.R>>6) << 4) | (uint32(c.G>>6) << 2) | uint32(c.B>>6)
			counts[bin]++
		}
	}

	type pair struct {
		bin   uint32
		count int
	}
	var list []pair
	for k, v := range counts {
		list = append(list, pair{k, v})
	}
	sort.Slice(list, func(i, j int) bool { return list[i].count > list[j].count })

	colors := []string{}
	for i := 0; i < len(list) && i < n; i++ {
		bin := list[i].bin
		r := (bin >> 4) & 0x3
		g := (bin >> 2) & 0x3
		b := bin & 0x3
		colors = append(colors, fmt.Sprintf("#%02X%02X%02X", r*85, g*85, b*85))
	}
	return colors
}

// DetectSource classifies where a file came from based on its filename.
func DetectSource(filename, assetType string) string {
	f := strings.ToLower(filename)
	switch {
	case strings.Contains(f, "reddit"):
		return "reddit"
	case strings.Contains(f, "instagram") || strings.HasPrefix(f, "ig_"):
		return "instagram"
	case strings.Contains(f, "screenshot") || strings.Contains(f, "screen_shot") || strings.Contains(f, "screencap"):
		return "screenshot"
	case strings.Contains(f, "whatsapp"):
		return "whatsapp"
	case strings.Contains(f, "telegram"):
		return "telegram"
	case strings.Contains(f, "download"):
		return "downloaded"
	case strings.Contains(f, "img_") || strings.Contains(f, "dsc") || strings.Contains(f, "pxl"):
		return "camera"
	default:
		if assetType == "VIDEO" {
			return "video"
		}
		return "camera"
	}
}

// SuggestTitle builds a human-friendly title: "Place · 2026-08-08 · camera".
func SuggestTitle(place string, date time.Time, source string) string {
	parts := []string{}
	if place != "" {
		parts = append(parts, place)
	}
	if !date.IsZero() {
		parts = append(parts, date.Format("2006-01-02"))
	}
	if source != "" && source != "camera" {
		parts = append(parts, source)
	}
	if len(parts) == 0 {
		parts = append(parts, "Untitled")
	}
	return strings.Join(parts, " · ")
}

// SuggestTags builds search-friendly tags from all available metadata.
func SuggestTags(place string, date time.Time, source string, colors []string) []string {
	tags := []string{}
	if place != "" {
		tags = append(tags, place)
	}
	if source != "" && source != "camera" {
		tags = append(tags, source)
	}
	if !date.IsZero() {
		tags = append(tags, fmt.Sprintf("%d", date.Year()))
		tags = append(tags, date.Month().String())
		hour := date.Hour()
		switch {
		case hour < 12:
			tags = append(tags, "morning")
		case hour < 18:
			tags = append(tags, "afternoon")
		default:
			tags = append(tags, "evening")
		}
	}
	for _, c := range colors {
		tags = append(tags, c)
	}
	return tags
}

// ----- helper for reading image dimensions/hash when decoding fails -----

func imageSize(img image.Image) (int, int) {
	b := img.Bounds()
	return b.Dx(), b.Dy()
}
