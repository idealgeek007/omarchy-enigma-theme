import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "OsdModel.js" as OsdModel

Item {
  id: root

  property bool opened: false
  property string icon: ""
  property string message: ""
  property string iconKey: ""
  property int value: 0
  property int maxValue: 100
  property bool hasProgress: true
  property int duration: 1200

  readonly property bool mediaOsd: iconKey.indexOf("media") === 0 || iconKey.indexOf("player") === 0

  // The card is built out of measured columns instead of fixed widths, so it
  // keeps exactly `pad` between border and content on every side whatever
  // glyph or message it carries. Messages grow with their text up to
  // `maxMessageWidth` and elide beyond it.
  readonly property int pad: Style.space(16)
  readonly property int gap: Style.space(16)
  // A glyph next to a message reads airier than it measures: the icon outline
  // and the letterforms both fall away from their ink extremes, so the space
  // between them opens up well past the nominal gap. Text takes two thirds of
  // it; the progress bar's hard edge keeps the full gap.
  readonly property int messageGap: Math.round(root.gap * 2 / 3)
  readonly property int barWidth: Style.space(142)
  readonly property int maxMessageWidth: root.mediaOsd ? Style.space(325) : Style.space(190)

  // Nerd Font glyphs draw well outside their monospace cell, so the icon
  // column is measured by ink rather than by advance width. Progress OSDs pin
  // it to the widest glyph the model can return, so the bar doesn't shift when
  // volume crosses an icon threshold.
  readonly property int iconInkWidth: Math.ceil(iconMetrics.tightBoundingRect.width)
  readonly property int iconWidth: root.hasProgress
    ? Math.max(root.iconInkWidth, Math.ceil(widestIconMetrics.tightBoundingRect.width))
    : root.iconInkWidth
  // Same idea for the readout: it is as wide as the longest percentage so the
  // digits don't jitter between 9% and 100%. The progress readout renders in
  // Doto (see percentMetrics below), so it is sized off that font rather than
  // messageMetrics's -- a +1px pad covers Doto's rounding so "100%" never
  // clips into an ellipsis.
  readonly property int valueWidth: root.hasProgress
    ? Math.ceil(Math.max(valueMetrics.advanceWidth, percentMetrics.advanceWidth)) + 1
    : Math.ceil(Math.max(valueMetrics.advanceWidth, messageMetrics.advanceWidth))
  readonly property int messageWidth: Math.min(Math.ceil(messageMetrics.advanceWidth), root.maxMessageWidth)
  readonly property int contentWidth: root.hasProgress
    ? root.iconWidth + root.gap + root.barWidth + root.gap + root.valueWidth
    : (root.message === "" ? root.iconWidth : root.iconWidth + root.messageGap + root.messageWidth)

  function iconFor(name, percent) {
    return OsdModel.iconFor(name, percent)
  }

  function show(iconName, rawMessage, rawValue, rawMax, rawProgressText, rawDuration) {
    var next = OsdModel.stateForShow(iconName, rawMessage, rawValue, rawMax, rawProgressText, rawDuration, Commons.I18n.formatNumber)
    // Update before opening so a fresh OSD starts at its new value; only
    // subsequent updates while it remains open animate the progress bar.
    iconKey = next.iconKey
    maxValue = next.maxValue
    hasProgress = next.hasProgress
    value = next.value
    message = next.message
    icon = next.icon
    duration = next.duration
    opened = true
    if (duration > 0) hideTimer.restart()
    else hideTimer.stop()
    maybePlayVolumeSound()
  }

  // A tiny tick for a volume change only -- never brightness, mic, or the
  // rest -- and never while muted (the real volume keybinding only ever
  // sends "volume-high" or "volume-muted", never a mid-range icon).
  property real lastSoundAt: 0
  function maybePlayVolumeSound() {
    if (root.iconKey.indexOf("volume") !== 0) return
    if (root.iconKey.indexOf("mute") >= 0) return
    var now = Date.now()
    if (now - root.lastSoundAt < 120) return
    root.lastSoundAt = now
    Util.execDetached(
      '[ -e "$HOME/.config/omarchy/enigma-sounds-off" ] && exit 0; ' +
      'wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -q MUTED && exit 0; ' +
      'snd="$HOME/.local/share/sounds/enigma/volume.wav"; ' +
      'if command -v pw-play >/dev/null 2>&1; then exec pw-play "$snd"; ' +
      'elif command -v paplay >/dev/null 2>&1; then exec paplay "$snd"; fi'
    )
  }

  function open(payloadJson) {
    try {
      var p = JSON.parse(payloadJson || "{}")
      show(p.icon || "", p.message || "", p.value === undefined ? "" : String(p.value), p.max === undefined ? "100" : String(p.max), p.progressText || "", p.duration === undefined ? "1200" : String(p.duration))
    } catch (e) {}
  }

  function close() { opened = false }

  Timer {
    id: hideTimer
    interval: root.duration
    onTriggered: root.opened = false
  }

  TextMetrics {
    id: messageMetrics
    font.family: Style.font.family
    font.bold: true
    font.pixelSize: Style.font.title
    text: root.message
  }

  TextMetrics {
    id: valueMetrics
    font: percentMetrics.font
    text: Commons.I18n.formatNumber(100) + "%"
  }

  // The progress readout (percentage, or a custom progressText) renders in
  // Doto -- a static ExtraBold instance, so no font.bold here -- at 1.3x the
  // title size, matching the dot-matrix look of enigma.audio. Measured
  // separately from messageMetrics so the wider Doto glyphs size their own
  // column instead of the default font's.
  TextMetrics {
    id: percentMetrics
    font.family: "Doto"
    font.pixelSize: Math.round(Style.font.title * 1.3)
    text: root.message
  }

  TextMetrics {
    id: iconMetrics
    font.family: Style.font.family
    font.pixelSize: Style.font.displayLarge
    text: root.icon
  }

  TextMetrics {
    id: widestIconMetrics
    font: iconMetrics.font
    text: OsdModel.widestIcon
  }

  ShellIpc {
    target: "osd"
    function show(payloadJson: string): string {
      root.open(payloadJson)
      return "ok"
    }
    function close(): string { root.close(); return "ok" }
    function state(): string { return root.opened ? "open" : "closed" }
    function ping(): string { return "ok" }
  }

  OverlayWindow {
    id: panel
    shown: root.opened
    shownKeyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "omarchy-osd"
    // Visual-only surface: keep the layer-shell input region empty so the OSD
    // never blocks clicks to the desktop below it.
    mask: Region {}

    BorderSurface {
      id: card
      width: card.borderLeft + root.pad + root.contentWidth + root.pad + card.borderRight
      height: card.borderTop + root.pad + Style.font.displayLarge + root.pad + card.borderBottom
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: Style.space(67)
      color: Util.alpha(Commons.Color.background, 0.97)
      borderSpec: Border.surfaceSpec("popups", "border", Commons.Color.popups.border, Math.max(1, Style.space(2)))
      radius: Style.cornerRadius
      opacity: root.opened ? 1 : 0

      Row {
        anchors.fill: parent
        anchors.topMargin: card.borderTop + root.pad
        anchors.rightMargin: card.borderRight + root.pad
        anchors.bottomMargin: card.borderBottom + root.pad
        anchors.leftMargin: card.borderLeft + root.pad
        spacing: root.hasProgress ? root.gap : root.messageGap
        Item {
          width: root.iconWidth
          height: parent.height
          Text {
            textFormat: Text.PlainText
            // Sit the glyph's ink flush in the column, centered when the
            // column is wider than this particular glyph.
            x: Math.round((root.iconWidth - root.iconInkWidth) / 2 - iconMetrics.tightBoundingRect.x)
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            font: iconMetrics.font
            color: Commons.Color.popups.text
          }
        }
        DotTrack {
          visible: root.hasProgress
          width: root.barWidth
          anchors.verticalCenter: parent.verticalCenter
          progress: root.value / root.maxValue
          // No explicit "muted" flag reaches this OSD -- callers keep sending
          // the real percentage alongside a "*-muted" icon -- so mute is read
          // off iconKey, same as a true 0 level.
          muted: root.iconKey.indexOf("mute") >= 0 || root.value <= 0
        }
        Text {
          textFormat: Text.PlainText
          visible: root.message !== ""
          width: root.hasProgress ? root.valueWidth : root.messageWidth
          // The readout hugs the card edge so a short percentage doesn't leave
          // a hole in the padding; the slack lands in the gap after the bar.
          horizontalAlignment: root.hasProgress ? Text.AlignRight : Text.AlignLeft
          anchors.verticalCenter: parent.verticalCenter
          text: root.message
          font: root.hasProgress ? percentMetrics.font : messageMetrics.font
          color: Commons.Color.popups.text
          // valueWidth already pads for Doto, but plain messages can still
          // run long, so keep eliding only on that branch.
          elide: root.hasProgress ? Text.ElideNone : Text.ElideRight
          maximumLineCount: 1
        }
      }
    }
  }

  // Dot-matrix style level indicator (Nothing OS look), reusing the
  // enigma.audio DotTrack approach: a fixed-width row of round dots, filled
  // up to the level with the last filled dot in accent, the rest dim.
  component DotTrack: Item {
    id: dotTrack
    property real progress: 0
    property bool muted: false

    readonly property real dotSize: Math.max(3, Style.space(5))
    readonly property real dotGap: Math.max(2, Style.space(5))
    readonly property int dotCount: Math.max(5, Math.floor((width + dotGap) / (dotSize + dotGap)))
    readonly property int currentIndex: Math.max(0, Math.min(dotCount - 1, Math.round(progress * (dotCount - 1))))

    implicitHeight: dotTrack.dotSize

    Row {
      anchors.verticalCenter: parent.verticalCenter
      spacing: dotTrack.dotGap

      Repeater {
        model: dotTrack.dotCount

        Rectangle {
          required property int index
          width: dotTrack.dotSize
          height: dotTrack.dotSize
          radius: width / 2
          color: (!dotTrack.muted && index === dotTrack.currentIndex) ? Commons.Color.accent : Commons.Color.popups.text
          opacity: dotTrack.muted ? 0.18 : (index <= dotTrack.currentIndex ? 1.0 : 0.18)
        }
      }
    }
  }
}
