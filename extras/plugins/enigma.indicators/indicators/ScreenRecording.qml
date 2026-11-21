import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

BarIndicator {
  id: root

  property bool recording: false

  active: recording
  // Active state is a red dot (Nothing-style privacy indicator) instead of
  // the glyph; the glyph stays for the inactive, clickable-to-start state.
  activeText: ""
  inactiveText: "󰻂"
  activeTooltipText: I18n.t("bar.stopRecording")
  inactiveTooltipText: I18n.t("bar.screenRecording")
  // Same tight Nothing-dot slot as Microphone/Camera while active (mic +
  // screen recording together is the common case, not an edge case), but the
  // normal statusSlot while inactive so the clickable glyph keeps its usual
  // hit target among the other hover-revealed indicators.
  fixedWidth: vertical ? -1 : (effectiveActive ? (Style.space(6) + Style.space(4)) : Style.bar.statusSlot)
  fixedHeight: vertical ? (effectiveActive ? (Style.space(6) + Style.space(4)) : Style.bar.statusSlot) : -1

  Rectangle {
    id: dot
    anchors.centerIn: parent
    visible: root.effectiveActive
    width: Style.space(6)
    height: Style.space(6)
    radius: width / 2
    color: Color.accent
    opacity: 1

    // Dropped mid-pulse, so the next activation always starts from full
    // opacity instead of resuming at whatever phase it stopped on.
    onVisibleChanged: if (!visible) opacity = 1

    // Recording is an active action, so it gets a gentle pulse; the mic and
    // camera dots (passive presence) stay steady. Style.duration() collapses
    // to 0 under reduce-motion, which would spin an infinite loop, so the
    // animation just doesn't run then and the dot stays solid.
    SequentialAnimation on opacity {
      running: root.effectiveActive && !Style.reduceMotion
      loops: Animation.Infinite
      NumberAnimation { to: 0.4; duration: Style.duration(900); easing.type: Easing.InOutSine }
      NumberAnimation { to: 1.0; duration: Style.duration(900); easing.type: Easing.InOutSine }
    }
  }

  function refresh() {
    if (!root.bar || statusProc.running) return
    statusProc.command = ["omarchy-capture-screenrecording", "--status"]
    statusProc.running = true
  }

  onBarChanged: refresh()
  Component.onCompleted: refresh()

  Connections {
    target: root.indicatorHost
    ignoreUnknownSignals: true
    function onRefreshRequested() { root.refresh() }
  }

  Process {
    id: statusProc
    onExited: function(exitCode) {
      root.recording = exitCode === 0
    }
  }

  onPressed: function() {
    if (root.bar) {
      root.bar.run(root.recording ? "omarchy-capture-screenrecording --stop-recording" : "omarchy-menu toggle trigger.capture.screenrecord")
    }
  }
}
