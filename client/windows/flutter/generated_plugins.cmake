#
# Generated file, do not edit.
#

list(APPEND FLUTTER_PLUGIN_LIST
  desktop_multi_window
  flutter_secure_storage_windows
  geolocator_windows
  media_kit_libs_windows_audio
  nsd_windows
  permission_handler_windows
  screen_retriever_windows
  share_plus
  url_launcher_windows
  window_manager
)

list(APPEND FLUTTER_FFI_PLUGIN_LIST
  jni
)

set(PLUGIN_BUNDLED_LIBRARIES)

foreach(plugin ${FLUTTER_PLUGIN_LIST})
  set(plugin_dir "flutter/ephemeral/.plugin_symlinks/${plugin}/windows")
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${plugin_dir}")
    add_subdirectory(${plugin_dir} plugins/${plugin})
    target_link_libraries(${BINARY_NAME} PRIVATE ${plugin}_plugin)
    list(APPEND PLUGIN_BUNDLED_LIBRARIES $<TARGET_FILE:${plugin}_plugin>)
    list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${plugin}_bundled_libraries})
  endif()
endforeach(plugin)

foreach(ffi_plugin ${FLUTTER_FFI_PLUGIN_LIST})
  set(ffi_dir "flutter/ephemeral/.plugin_symlinks/${ffi_plugin}/windows")
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${ffi_dir}")
    add_subdirectory(${ffi_dir} plugins/${ffi_plugin})
    list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${ffi_plugin}_bundled_libraries})
  endif()
endforeach(ffi_plugin)
