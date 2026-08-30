import os
import sys

print("=== Patching appflowy_editor & Windows CMake for Flutter 3.44+ ===")

scan_roots = [
    os.path.expanduser("~"),
    os.environ.get("LOCALAPPDATA", ""),
    os.environ.get("APPDATA", ""),
    os.environ.get("USERPROFILE", ""),
    os.environ.get("PUB_CACHE", ""),
    r"C:\Users\runneradmin",
    r"C:\Users",
    r"C:\hostedtoolcache",
    "/opt/hostedtoolcache",
]

patched = 0
visited = set()

for sr in scan_roots:
    if not sr or not os.path.exists(sr):
        continue
    sr_real = os.path.realpath(sr)
    if sr_real in visited:
        continue
    visited.add(sr_real)
    print(f"Scanning: {sr_real}")

    for root, dirs, files in os.walk(sr_real):
        if "appflowy_editor" in root:
            for f in files:
                p = os.path.join(root, f)
                if f == "delta_markdown_decoder.dart":
                    try:
                        c = open(p, encoding="utf-8").read()
                        if "with md.NodeVisitor" in c:
                            c = c.replace("with md.NodeVisitor", "implements md.NodeVisitor")
                            open(p, "w", encoding="utf-8").write(c)
                            print(f"  [PATCHED] {p}")
                            patched += 1
                    except Exception as e:
                        print(f"  [ERROR] {p}: {e}")
                elif f == "delta_input_service.dart":
                    try:
                        c = open(p, encoding="utf-8").read()
                        if "onFocusReceived" not in c:
                            c = c.replace(
                                "class DeltaTextInputService extends TextInputService with DeltaTextInputClient {",
                                "class DeltaTextInputService extends TextInputService with DeltaTextInputClient {\n  @override\n  bool onFocusReceived() => false;\n",
                            )
                            open(p, "w", encoding="utf-8").write(c)
                            print(f"  [PATCHED] {p}")
                            patched += 1
                    except Exception as e:
                        print(f"  [ERROR] {p}: {e}")
                elif f == "file_picker_impl.dart":
                    try:
                        c = open(p, encoding="utf-8").read()
                        if "fp.FilePicker.getDirectoryPath" in c or "fp.FilePicker.pickFiles" in c or "fp.FilePicker.saveFile" in c:
                            c = c.replace("fp.FilePicker.getDirectoryPath", "fp.FilePicker.platform.getDirectoryPath")
                            c = c.replace("fp.FilePicker.pickFiles", "fp.FilePicker.platform.pickFiles")
                            c = c.replace("fp.FilePicker.saveFile", "fp.FilePicker.platform.saveFile")
                            open(p, "w", encoding="utf-8").write(c)
                            print(f"  [PATCHED] {p}")
                            patched += 1
                    except Exception as e:
                        print(f"  [ERROR] {p}: {e}")

# Patch Windows CMake if needed
client_dir = os.path.realpath(os.path.join(os.path.dirname(__file__), ".."))
cmake_file = os.path.join(client_dir, "windows", "flutter", "generated_plugins.cmake")
if os.path.exists(cmake_file):
    try:
        c = open(cmake_file, encoding="utf-8").read()
        c = c.replace("  rich_clipboard_windows\n", "")
        c = c.replace("  rich_clipboard_windows", "")
        c = c.replace(
            "add_subdirectory(flutter/ephemeral/.plugin_symlinks/${plugin}/windows plugins/${plugin})",
            "set(pdir \"flutter/ephemeral/.plugin_symlinks/${plugin}/windows\")\n  if(EXISTS \"${CMAKE_CURRENT_SOURCE_DIR}/${pdir}\")\n    add_subdirectory(${pdir} plugins/${plugin})"
        )
        c = c.replace(
            "add_subdirectory(flutter/ephemeral/.plugin_symlinks/${ffi_plugin}/windows plugins/${ffi_plugin})",
            "set(fdir \"flutter/ephemeral/.plugin_symlinks/${ffi_plugin}/windows\")\n  if(EXISTS \"${CMAKE_CURRENT_SOURCE_DIR}/${fdir}\")\n    add_subdirectory(${fdir} plugins/${ffi_plugin})"
        )
        open(cmake_file, "w", encoding="utf-8").write(c)
        print(f"  [PATCHED] {cmake_file}")
    except Exception as e:
        print(f"  [ERROR] {cmake_file}: {e}")

# Ensure dummy CMakeLists for rich_clipboard_windows in ephemeral plugin symlinks
dummy_dir = os.path.join(client_dir, "windows", "flutter", "ephemeral", ".plugin_symlinks", "rich_clipboard_windows", "windows")
try:
    os.makedirs(dummy_dir, exist_ok=True)
    dummy_cmake = os.path.join(dummy_dir, "CMakeLists.txt")
    if not os.path.exists(dummy_cmake):
        with open(dummy_cmake, "w", encoding="utf-8") as f:
            f.write("cmake_minimum_required(VERSION 3.14)\nproject(rich_clipboard_windows_plugin LANGUAGES CXX)\nadd_library(rich_clipboard_windows_plugin INTERFACE)\n")
        print(f"  [CREATED] {dummy_cmake}")
except Exception as e:
    print(f"  [ERROR] Creating dummy cmake: {e}")

print(f"=== Total patched files: {patched} ===")
