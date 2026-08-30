import os
import sys
import re

print("=== Patching appflowy_editor & Windows CMake for Flutter 3.44+ ===")

client_dir = os.path.realpath(os.path.join(os.path.dirname(__file__), ".."))

candidate_roots = [
    os.environ.get("PUB_CACHE"),
    os.path.join(os.environ.get("LOCALAPPDATA", ""), "Pub", "Cache"),
    os.path.join(os.environ.get("APPDATA", ""), "Pub", "Cache"),
    os.path.expanduser("~/.pub-cache"),
    os.path.join(os.environ.get("USERPROFILE", ""), ".pub-cache"),
    os.path.join(os.environ.get("USERPROFILE", ""), "AppData", "Local", "Pub", "Cache"),
    r"C:\Users\runneradmin\.pub-cache",
    r"C:\Users\runneradmin\AppData\Local\Pub\Cache",
    r"C:\hostedtoolcache",
    "/opt/hostedtoolcache",
    os.path.join(client_dir, "..", "appflowy_repo"),
]

scan_dirs = []
for r in candidate_roots:
    if not r or not os.path.exists(r):
        continue
    # Check pub.dev hosted directory first if it exists
    pub_dev = os.path.join(r, "hosted", "pub.dev")
    if os.path.exists(pub_dev):
        scan_dirs.append(pub_dev)
    pub_dartlang = os.path.join(r, "hosted", "pub.dartlang.org")
    if os.path.exists(pub_dartlang):
        scan_dirs.append(pub_dartlang)
    scan_dirs.append(r)

patched = 0
visited = set()

for sdir in scan_dirs:
    sdir_real = os.path.realpath(sdir)
    if sdir_real in visited or not os.path.exists(sdir_real):
        continue
    visited.add(sdir_real)
    print(f"Scanning: {sdir_real}")

    for root, dirs, files in os.walk(sdir_real):
        if "file_picker" in root:
            internal_web = os.path.join(root, "lib", "_internal", "file_picker_web.dart")
            platform_web_dir = os.path.join(root, "lib", "src", "platform", "web")
            platform_web = os.path.join(platform_web_dir, "file_picker_web.dart")
            if os.path.exists(internal_web) and not os.path.exists(platform_web):
                try:
                    os.makedirs(platform_web_dir, exist_ok=True)
                    with open(platform_web, "w", encoding="utf-8") as f:
                        f.write("export '../../../_internal/file_picker_web.dart';\n")
                    print(f"  [CREATED] {platform_web}")
                    patched += 1
                except Exception as e:
                    print(f"  [ERROR] {platform_web}: {e}")

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

# Patch Windows CMake to make plugin loading robust
cmake_file = os.path.join(client_dir, "windows", "flutter", "generated_plugins.cmake")
if os.path.exists(cmake_file):
    try:
        c = open(cmake_file, encoding="utf-8").read()

        # Remove rich_clipboard_windows from plugin list as it lacks native windows implementation
        c = re.sub(r'^\s*rich_clipboard_windows\s*$\n?', '', c, flags=re.MULTILINE)

        plugin_loop_pattern = re.compile(
            r"foreach\(plugin \$\{FLUTTER_PLUGIN_LIST\}\).*?endforeach\(plugin\)",
            re.DOTALL
        )
        plugin_loop_replacement = """foreach(plugin ${FLUTTER_PLUGIN_LIST})
  set(plugin_dir "flutter/ephemeral/.plugin_symlinks/${plugin}/windows")
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${plugin_dir}")
    add_subdirectory(${plugin_dir} plugins/${plugin})
    target_link_libraries(${BINARY_NAME} PRIVATE ${plugin}_plugin)
    list(APPEND PLUGIN_BUNDLED_LIBRARIES $<TARGET_FILE:${plugin}_plugin>)
    list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${plugin}_bundled_libraries})
  endif()
endforeach(plugin)"""

        ffi_loop_pattern = re.compile(
            r"foreach\(ffi_plugin \$\{FLUTTER_FFI_PLUGIN_LIST\}\).*?endforeach\(ffi_plugin\)",
            re.DOTALL
        )
        ffi_loop_replacement = """foreach(ffi_plugin ${FLUTTER_FFI_PLUGIN_LIST})
  set(ffi_dir "flutter/ephemeral/.plugin_symlinks/${ffi_plugin}/windows")
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${ffi_dir}")
    add_subdirectory(${ffi_dir} plugins/${ffi_plugin})
    list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${ffi_plugin}_bundled_libraries})
  endif()
endforeach(ffi_plugin)"""

        c = plugin_loop_pattern.sub(plugin_loop_replacement, c)
        c = ffi_loop_pattern.sub(ffi_loop_replacement, c)

        open(cmake_file, "w", encoding="utf-8").write(c)
        print(f"  [PATCHED] {cmake_file}")
    except Exception as e:
        print(f"  [ERROR] {cmake_file}: {e}")

# Patch Windows generated_plugin_registrant.cc to strip rich_clipboard_windows dummy references
registrant_file = os.path.join(client_dir, "windows", "flutter", "generated_plugin_registrant.cc")
if os.path.exists(registrant_file):
    try:
        c = open(registrant_file, encoding="utf-8").read()
        c = re.sub(r'#include\s*<rich_clipboard_windows/[^>]+>\s*\n?', '', c)
        c = re.sub(r'\s*noneRegisterWithRegistrar[\s\S]*?\);\n?', '\n', c)
        open(registrant_file, "w", encoding="utf-8").write(c)
        print(f"  [PATCHED] {registrant_file}")
    except Exception as e:
        print(f"  [ERROR] {registrant_file}: {e}")

# Ensure dummy static library and header for rich_clipboard_windows in ephemeral plugin symlinks if needed
dummy_dir = os.path.join(client_dir, "windows", "flutter", "ephemeral", ".plugin_symlinks", "rich_clipboard_windows", "windows")
try:
    if os.path.exists(os.path.dirname(dummy_dir)):
        os.makedirs(dummy_dir, exist_ok=True)
        dummy_inc = os.path.join(dummy_dir, "include", "rich_clipboard_windows")
        os.makedirs(dummy_inc, exist_ok=True)
        none_h = os.path.join(dummy_inc, "none.h")
        with open(none_h, "w", encoding="utf-8") as f:
            f.write("#pragma once\n#include <flutter/plugin_registrar_windows.h>\ninline void noneRegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar) {}\n")

        dummy_cpp = os.path.join(dummy_dir, "dummy.cpp")
        with open(dummy_cpp, "w", encoding="utf-8") as f:
            f.write("void rich_clipboard_dummy() {}\n")

        dummy_cmake = os.path.join(dummy_dir, "CMakeLists.txt")
        with open(dummy_cmake, "w", encoding="utf-8") as f:
            f.write("cmake_minimum_required(VERSION 3.14)\nproject(rich_clipboard_windows_plugin LANGUAGES CXX)\nadd_library(rich_clipboard_windows_plugin STATIC dummy.cpp)\ntarget_include_directories(rich_clipboard_windows_plugin PUBLIC include)\n")
        print(f"  [CREATED/UPDATED] {dummy_cmake} & {none_h}")
except Exception as e:
    print(f"  [ERROR] Creating dummy cmake: {e}")

print(f"=== Total patched files: {patched} ===")
