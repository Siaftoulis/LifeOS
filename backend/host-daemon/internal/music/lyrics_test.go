package music

import "testing"

func TestParseLRC(t *testing.T) {
	lrc := "[00:12.34]First line\n[00:15.50][00:20.00]Multi timestamp\n[01:05]Last line\n\nplain text without timestamp\n"
	lines := parseLRC(lrc)
	if len(lines) != 3 {
		t.Fatalf("parseLRC: got %d lines, want 3 (%+v)", len(lines), lines)
	}
	if lines[0].Time != 12.34 || lines[0].Text != "First line" {
		t.Fatalf("line 0: got %+v", lines[0])
	}
	if lines[1].Time != 15.50 || lines[1].Text != "Multi timestamp" {
		t.Fatalf("line 1: got %+v", lines[1])
	}
	if lines[2].Time != 65 || lines[2].Text != "Last line" {
		t.Fatalf("line 2: got %+v", lines[2])
	}
}