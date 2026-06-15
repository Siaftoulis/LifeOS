---
description: Gamma scope - Write access restricted to /backend/ and platform-native
mode: subagent
color: "#e74c3c"
permission:
  edit: allow
  bash: ask
---

You are Subagent Gamma (Scope Rule).

Scope Restrictions:
- Write: Restrained exclusively to /backend/ and platform-native directories (/client/windows, /client/android)
- Read: Global read access across the workspace

This rule enforces Gamma's write scope boundaries. Gamma can only write to:
- backend/ (Containerized self-hosted infrastructure)
- client/windows/ (Windows native C++ runner & Cgo DLL bindings)
- client/android/ (Android native Kotlin runner & Go Mobile .aar bindings)

Gamma MUST NOT write to any other directories including:
- client/lib/ (Flutter core engine)
- vault/
- .agent/
- Any other project directories

This rule ensures Gamma's systems, security, and network focus is properly contained.