import os
import sys

print("=== Patching appflowy_editor compatibility for Flutter 3.44+ ===")

scan_roots = [
    os.path.expanduser("~"),
    os.path.expandvars(r"%LOCALAPPDATA%"),
    os.environ.get("PUB_CACHE", ""),
    r"C:\hostedtoolcache\windows\flutter",
    "/opt/hostedtoolcache/flutter",
]

patched = 0
for sr in scan_roots:
    if not sr or not os.path.exists(sr):
        continue
    for root, dirs, files in os.walk(sr):
        if "appflowy_editor" in root:
            for f in files:
                p = os.path.join(root, f)
                if f == "delta_markdown_decoder.dart":
                    try:
                        c = open(p, encoding="utf-8").read()
                        if "with md.NodeVisitor" in c:
                            c = c.replace("with md.NodeVisitor", "implements md.NodeVisitor")
                            open(p, "w", encoding="utf-8").write(c)
                            print(f"Patched: {p}")
                            patched += 1
                    except Exception as e:
                        print(f"Error patching {p}: {e}")
                elif f == "delta_input_service.dart":
                    try:
                        c = open(p, encoding="utf-8").read()
                        if "onFocusReceived" not in c:
                            c = c.replace(
                                "class DeltaTextInputService extends TextInputService with DeltaTextInputClient {",
                                "class DeltaTextInputService extends TextInputService with DeltaTextInputClient {\n  @override\n  bool onFocusReceived() => false;\n",
                            )
                            open(p, "w", encoding="utf-8").write(c)
                            print(f"Patched: {p}")
                            patched += 1
                    except Exception as e:
                        print(f"Error patching {p}: {e}")
                elif f == "file_picker_impl.dart":
                    try:
                        c = open(p, encoding="utf-8").read()
                        if "fp.FilePicker.getDirectoryPath" in c:
                            c = c.replace("fp.FilePicker.getDirectoryPath", "fp.FilePicker.platform.getDirectoryPath")
                            c = c.replace("fp.FilePicker.pickFiles", "fp.FilePicker.platform.pickFiles")
                            c = c.replace("fp.FilePicker.saveFile", "fp.FilePicker.platform.saveFile")
                            open(p, "w", encoding="utf-8").write(c)
                            print(f"Patched: {p}")
                            patched += 1
                    except Exception as e:
                        print(f"Error patching {p}: {e}")

print(f"=== Total patched files: {patched} ===")
