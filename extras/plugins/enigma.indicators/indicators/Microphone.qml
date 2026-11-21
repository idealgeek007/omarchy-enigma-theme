import QtQuick
import qs.Commons
import qs.Ui

BarIndicator {
  id: root

  // Polled once centrally by Indicators.qml (indicatorHost) so this file,
  // which the framework instantiates twice (inactive + active block), never
  // spawns its own pactl/jq process pair.
  readonly property bool micInUse: !!root.indicatorHost && root.indicatorHost.micInUse === true
  readonly property string micApp: root.indicatorHost ? String(root.indicatorHost.micTooltip || "") : ""

  active: micInUse
  activeText: ""
  inactiveText: ""
  activeTooltipText: micApp !== "" ? ("Microphone in use: " + micApp) : "Microphone in use"
  // Nothing to toggle here, so it never clutters the hover-revealed inactive row.
  revealWhenInactive: false
  pressable: false
  // Tight Nothing-dot spacing instead of the shared statusSlot: only matters
  // while active, since an inactive instance collapses to zero width anyway.
  fixedWidth: vertical ? -1 : (Style.space(6) + Style.space(4))
  fixedHeight: vertical ? (Style.space(6) + Style.space(4)) : -1

  Rectangle {
    anchors.centerIn: parent
    visible: root.effectiveActive
    width: Style.space(6)
    height: Style.space(6)
    radius: width / 2
    color: Color.accent
  }
}
