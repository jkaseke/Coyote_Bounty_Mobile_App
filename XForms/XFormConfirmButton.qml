/* Copyright 2018 Esri
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

import QtQuick 2.9
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

Item {
    id: button

    property color accentColor: "#88c448"
    property color backgroundColor: Qt.lighter(accentColor, 1.75)//"#d1e392"// "#f0f0f0"
    property color hoverColor: Qt.darker(backgroundColor, 1.25)
    property color pressedColor: Qt.darker(backgroundColor, 1.25)
    property color borderColor: accentColor //#40000000"
    property color textColor: "black"

    property alias text: labelText.text
    property real textPointSize: xform.style.buttonTextPointSize
    property string fontFamily: xform.style.fontFamily

    //--------------------------------------------------------------------------

    signal clicked()

    //--------------------------------------------------------------------------

    implicitWidth: labelText.paintedWidth + 40 * AppFramework.displayScaleFactor
    implicitHeight: labelText.paintedHeight + 10 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    RectangularGlow {
        anchors.fill: background

        visible: mouseArea.containsMouse
        glowRadius: 5 * AppFramework.displayScaleFactor
        spread: 0.2
        color: hoverColor
        cornerRadius: background.radius + glowRadius
    }

    Rectangle {
        id: background

        anchors.fill: parent

        color: mouseArea.pressed ? pressedColor : backgroundColor
        radius: height / (labelText.lineCount + 1)
        border {
            color: borderColor
            width: 1
        }

        Text {
            id: labelText

            anchors.centerIn: parent

            font {
                pointSize: textPointSize
                family: fontFamily
            }
            color: textColor

            renderType: Text.QtRendering
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent

        hoverEnabled: true

        onClicked: {
            button.clicked();
        }
    }
}
