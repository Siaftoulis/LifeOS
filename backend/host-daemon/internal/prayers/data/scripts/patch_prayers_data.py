path = 'backend/host-daemon/internal/prayers/prayers_data.go'
with open(path, 'r', encoding='utf-8') as f:
    code = f.read()

target = '\treturn nil, fmt.Errorf("service not found: %s", serviceID)\n}'
replacement = '''\t// Check Euchologion
\tif book, err := loadEuchologion(); err == nil {
\t\tfor _, p := range book.Prayers {
\t\t\tif p.ID == serviceID {
\t\t\t\treturn &PrayerService{
\t\t\t\t\tID:           p.ID,
\t\t\t\t\tTitle:        p.Title,
\t\t\t\t\tCategory:     p.Category,
\t\t\t\t\tSubtitle:     "Ευχολόγιον",
\t\t\t\t\tEstimatedMin: 10,
\t\t\t\t\tSections:     p.Sections,
\t\t\t\t}, nil
\t\t\t}
\t\t}
\t}

\treturn nil, fmt.Errorf("service not found: %s", serviceID)
}'''

if target in code:
    new_code = code.replace(target, replacement)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_code)
    print('Updated prayers_data.go successfully!')
else:
    print('Target not found in prayers_data.go!')
