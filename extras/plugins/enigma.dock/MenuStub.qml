import QtQuick

// Never shown. Omarchy only hands the app list (appLibrary) to plugins that
// declare the "menu" kind, and a "menu" kind needs a menu entry point. The
// dock's app grid needs that list, so this empty stub satisfies the check.
Item {
  property var shell: null
  property var manifest: null
  visible: false
}
