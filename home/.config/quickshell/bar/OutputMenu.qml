import QtQuick
import Quickshell.Services.Pipewire
import qs
import qs.widgets

Popup {
    id: root

    title: "Звук"

    readonly property var sinks: Pipewire.nodes
        ? Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
        : []

    readonly property var currentSink: Pipewire.defaultAudioSink
    readonly property var currentAudio: root.currentSink ? root.currentSink.audio : null

    readonly property var currentSource: Pipewire.defaultAudioSource
    readonly property var sourceAudio: root.currentSource ? root.currentSource.audio : null

    function sinkName(node): string {
        return node.description || node.nickname || node.name;
    }

    PwObjectTracker {
        objects: root.currentSource
            ? root.sinks.concat([root.currentSource])
            : root.sinks
    }

    Repeater {
        model: root.sinks

        MenuRow {
            required property var modelData

            width: root.contentWidth
            label: root.sinkName(modelData)
            highlight: modelData === root.currentSink
            glyph: modelData === root.currentSink ? "󰓃" : "󰤽"
            trailing: modelData === root.currentSink ? "активно" : ""

            onClicked: {
                Pipewire.preferredDefaultAudioSink = modelData;
                root.close();
            }
        }
    }

    MenuRow {
        width: root.contentWidth
        visible: root.sinks.length === 0
        rowEnabled: false
        glyph: "󰝟"
        label: "Устройств не найдено"
    }

    MenuSeparator { width: root.contentWidth }

    MenuSlider {
        width: root.contentWidth
        audio: root.currentAudio
        glyph: "󰕾"
        mutedGlyph: "󰝟"
    }

    MenuSlider {
        width: root.contentWidth
        visible: root.currentSource !== null
        audio: root.sourceAudio
        glyph: "󰍬"
        mutedGlyph: "󰍭"
    }
}
