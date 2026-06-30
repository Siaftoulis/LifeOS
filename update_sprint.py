import json

sprint_file = r'c:\Users\PDS_Dev\1_Production\Projects\LifeOS\vault\03 - work\current_sprint.json'

with open(sprint_file, 'r') as f:
    data = json.load(f)

new_macro_task = {
    "macro_task": "Unified Data Flow Sprint",
    "status": "in_progress",
    "sub_tasks": [
        {
            "id": "UDF-001",
            "description": "Workstream A: Delete Legacy, Unify Schema",
            "dependencies": [],
            "status": "pending"
        },
        {
            "id": "UDF-002",
            "description": "Workstream B: Wire CHTMView to Real Data",
            "dependencies": ["UDF-001"],
            "status": "pending"
        },
        {
            "id": "UDF-003",
            "description": "Workstream C: Wire QuestBoard to Real Data",
            "dependencies": ["UDF-001"],
            "status": "pending"
        },
        {
            "id": "UDF-004",
            "description": "Workstream D: Connect Client Completion to Backend",
            "dependencies": ["UDF-002", "UDF-003"],
            "status": "pending"
        },
        {
            "id": "UDF-005",
            "description": "Workstream E: Connect to RPG Systems",
            "dependencies": ["UDF-004"],
            "status": "pending"
        },
        {
            "id": "UDF-006",
            "description": "Workstream F: Backend Calendar & Sync",
            "dependencies": ["UDF-004"],
            "status": "pending"
        },
        {
            "id": "UDF-007",
            "description": "Workstream G: Remove Race Conditions",
            "dependencies": ["UDF-005"],
            "status": "pending"
        }
    ]
}

data.append(new_macro_task)

with open(sprint_file, 'w') as f:
    json.dump(data, f, indent=4)
