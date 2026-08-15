package gallery

import (
	"image"
	"image/color"
	"testing"
	"time"
)

func testImg() image.Image {
	img := image.NewRGBA(image.Rect(0, 0, 64, 64))
	for y := 0; y < 64; y++ {
		for x := 0; x < 64; x++ {
			img.Set(x, y, color.RGBA{uint8(x * 4), uint8(y * 4), 128, 255})
		}
	}
	return img
}

func TestDHashStableAndDistinct(t *testing.T) {
	a := DHash(testImg())
	b := DHash(testImg())
	if a == "" || len(a) != 16 {
		t.Fatalf("unexpected hash %q", a)
	}
	if a != b {
		t.Fatal("same image produced different hashes")
	}
	diff := testImg()
	for y := 0; y < 64; y++ {
		for x := 0; x < 32; x++ {
			diff.(*image.RGBA).Set(x, y, color.RGBA{255, 0, 0, 255})
		}
	}
	if DHash(diff) == a {
		t.Fatal("different image produced same hash")
	}
}

func TestSuggestTitleTags(t *testing.T) {
	date := time.Date(2026, 8, 8, 20, 30, 0, 0, time.UTC)
	title := SuggestTitle("Athens", date, "camera")
	if title != "Athens · 2026-08-08" {
		t.Fatalf("unexpected title %q", title)
	}
	tags := SuggestTags("Athens", date, "instagram", []string{"#FF0000"})
	want := map[string]bool{"Athens": true, "instagram": true, "2026": true, "August": true, "evening": true, "#FF0000": true}
	for _, tag := range tags {
		if !want[tag] {
			t.Fatalf("unexpected tag %q in %v", tag, tags)
		}
		delete(want, tag)
	}
	if len(want) != 0 {
		t.Fatalf("missing tags %v", want)
	}
}

func TestDetectSource(t *testing.T) {
	cases := map[string]string{
		"IG_123.jpg":      "instagram",
		"reddit_video.mp4": "reddit",
		"IMG_2026.jpg":    "camera",
		"Screen_Shot_1.png": "screenshot",
		"video.mp4":       "video",
	}
	for name, want := range cases {
		if got := DetectSource(name, "PHOTO"); got != want {
			if name == "video.mp4" && DetectSource(name, "VIDEO") != want {
				t.Fatalf("%s: got %s want %s", name, got, want)
			}
			if name != "video.mp4" {
				t.Fatalf("%s: got %s want %s", name, got, want)
			}
		}
	}
}

func TestDominantColors(t *testing.T) {
	colors := DominantColors(testImg(), 4)
	if len(colors) == 0 || len(colors) > 4 {
		t.Fatalf("unexpected colors %v", colors)
	}
	for _, c := range colors {
		if len(c) != 7 || c[0] != '#' {
			t.Fatalf("bad color %q", c)
		}
	}
}
