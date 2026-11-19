import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "panacea.system-stats"

  property int cpuPercent: 0
  property int memoryPercent: 0
  property real previousIdle: -1
  property real previousTotal: -1
  property string loadAverage: ""

  function refresh() {
    if (!statsProc.running) statsProc.running = true
  }

  function updateStats(raw) {
    var lines = String(raw || "").trim().split("\n")
    for (var i = 0; i < lines.length; i++) {
      var fields = lines[i].split("\t")
      if (fields[0] === "cpu" && fields.length >= 3) {
        var idle = Number(fields[1])
        var total = Number(fields[2])
        if (previousIdle >= 0 && previousTotal >= 0 && total > previousTotal) {
          var busyDelta = (total - previousTotal) - (idle - previousIdle)
          cpuPercent = Math.max(0, Math.min(100, Math.round(100 * busyDelta / (total - previousTotal))))
        }
        previousIdle = idle
        previousTotal = total
      } else if (fields[0] === "memory" && fields.length >= 2) {
        memoryPercent = Math.max(0, Math.min(100, Math.round(Number(fields[1]))))
      } else if (fields[0] === "load" && fields.length >= 2) {
        loadAverage = fields[1]
      }
    }
  }

  implicitWidth: statsRow.implicitWidth + Style.space(12)
  implicitHeight: barSize

  Component.onCompleted: refresh()

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: statsProc
    command: ["omarchy-system-stats", "--bar-widget"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateStats(text)
    }
  }

  // Panacea / Nothing: dim small-caps label, dot-matrix value,
  // value turns red past 85%.
  component Stat: Row {
    property string label
    property int value
    spacing: Style.space(3)
    readonly property color fg: root.bar ? root.bar.foreground : Color.foreground
    Text {
      anchors.baseline: num.baseline
      text: parent.label
      color: parent.fg
      opacity: 0.5
      font.family: root.bar ? root.bar.fontFamily : ""
      font.pixelSize: Style.font.caption
      font.letterSpacing: 1
    }
    Text {
      id: num
      text: parent.value + "%"
      color: parent.value >= 85 ? Color.accent : parent.fg
      font.family: "Doto"
      font.pixelSize: Style.font.body * 1.3
      Behavior on color { ColorAnimation { duration: 200 } }
    }
  }

  Row {
    id: statsRow
    anchors.centerIn: parent
    spacing: Style.space(10)

    Stat { label: "CPU"; value: root.cpuPercent }
    Stat { label: "RAM"; value: root.memoryPercent }
  }
}
