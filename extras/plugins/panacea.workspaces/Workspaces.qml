import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "panacea.workspaces"

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }

    return null
  }

  function workspaceIds() {
    var ids = [1, 2, 3, 4, 5]
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.workspaceIds().length
    columnSpacing: 0
    rowSpacing: 0

    Repeater {
      model: root.workspaceIds()

      // Panacea / Nothing-style: dots instead of numbers.
      // Focused = red pill, occupied = white dot, empty = dim dot.
      Item {
        id: cell
        required property int modelData

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData
        readonly property real dot: Math.max(5, Math.round(root.barSize * 0.2))

        implicitWidth: root.vertical ? root.barSize : (focused ? dot * 3.2 : dot) + Style.space(2)
        implicitHeight: root.vertical ? (focused ? dot * 3.2 : dot) + Style.space(2) : root.barSize
        Layout.preferredWidth: implicitWidth
        Layout.preferredHeight: implicitHeight
        Behavior on implicitWidth { NumberAnimation { duration: 220; easing.type: Easing.OutQuint } }
        Behavior on implicitHeight { NumberAnimation { duration: 220; easing.type: Easing.OutQuint } }

        Rectangle {
          anchors.centerIn: parent
          width: root.vertical ? cell.dot : (cell.focused ? cell.dot * 3.2 : cell.dot)
          height: root.vertical ? (cell.focused ? cell.dot * 3.2 : cell.dot) : cell.dot
          radius: cell.dot / 2
          color: cell.focused ? Color.accent : Color.foreground
          opacity: cell.focused ? 1 : (cell.occupied ? 0.9 : 0.28)
          Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutQuint } }
          Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutQuint } }
          Behavior on color { ColorAnimation { duration: 180 } }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.focusWorkspace(cell.modelData)
        }
      }
    }
  }
}
