//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <desktop_webview_linux/desktop_webview_linux_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) desktop_webview_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "DesktopWebviewLinuxPlugin");
  desktop_webview_linux_plugin_register_with_registrar(desktop_webview_linux_registrar);
}
