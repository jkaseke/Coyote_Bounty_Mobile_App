/* Copyright 2019 Esri
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

import QtQuick 2.11
import QtLocation 5.9
import QtPositioning 5.8

MouseArea {
    //--------------------------------------------------------------------------

    property Map map: parent
    readonly property var coordinate: map.toCoordinate(Qt.point(mouseX, mouseY))

    //--------------------------------------------------------------------------

    anchors.fill: map

    //--------------------------------------------------------------------------

    function toCoordinate(mouse) {
        return map.toCoordinate(Qt.point(mouse.x, mouse.y));
    }

    //--------------------------------------------------------------------------
}
