import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.0
import QtQuick.LocalStorage 2.15

ApplicationWindow {
    id: app
    visible: true
    title: "Le Qml c'est pas sorcier"
    width : 600
    height: 250

    property real alpha: 1.0
    property var db

    function addTodo(title, status) {
        addDB(title, status)
    }

    function removeTodo(index) {
        removeDB(model.get(index).id)
        removeModel(index)
    }

    function setStatus(index, status) {
        model.set(index, {"id": model.get(index).id, "title": model.get(index).title, "status": status ? 1 : 0})
        editDB(model.get(index).id, model.get(index).title, model.get(index).status)
    }

    function addModel(id, title, status) {
        model.append({"id": Number(id), "title": title, "status": status ? 1 : 0})
        list.positionViewAtEnd()
    }

    function removeModel(index) {
        model.remove(index, 1)
        list.hoveredIndex = -1
    }


    function addDB(title, status) {
        db.transaction( function(tx) {
            var rs = tx.executeSql('INSERT INTO Todo VALUES(?, ?)', [ title, status ]);
            addModel(rs.insertId, title, status)
        })
    }

    function editDB(id, title, status) {
        db.transaction( function(tx) {
            tx.executeSql('UPDATE Todo SET title = ?, status = ? WHERE rowid = ?', [ title, status, id ]);
        })
    }

    function removeDB(id) {
        db.transaction( function(tx) {
            tx.executeSql('DELETE FROM Todo WHERE rowid = ?', id);
        })
    }

    function initDB() {
        db = LocalStorage.openDatabaseSync("QMLTodoExampleDB", "1.0", "The Example QML SQL!", 1000000);
        db.transaction(
            function(tx) {
                tx.executeSql('CREATE TABLE IF NOT EXISTS Todo(title TEXT, status BOOL)');
                var rs = tx.executeSql('SELECT rowid, * FROM Todo');
                for (var i = 0; i < rs.rows.length; i++) {
                    addModel(rs.rows.item(i).rowid, rs.rows.item(i).title, rs.rows.item(i).status)
                }
            }
        )
    }

    ListModel {
        id: model
    }

    Component.onCompleted: initDB()

    SystemPalette {
        id: myPalette
        colorGroup: SystemPalette.Active
    }

    color: Qt.hsla( myPalette.window.hslHue, myPalette.window.hslSaturation, myPalette.window.hslLightness, app.alpha)

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 10

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent" //Qt.hsla( myPalette.alternateBase.hslHue, myPalette.alternateBase.hslSaturation, myPalette.alternateBase.hslLightness, 0.5)

            Text {
                anchors.centerIn: parent
                visible : model.count === 0 ? true : false
                color: myPalette.text
                text: "La liste de tache est vide, ajoutez en une !"
            }

            ListView {
                id: list
                property int hoveredIndex: -1

                anchors.fill: parent
                spacing: 5

                model: model
                delegate: Rectangle {
                    color : index % 2 === 0
                    ? Qt.hsla( myPalette.midlight.hslHue, myPalette.midlight.hslSaturation, myPalette.midlight.hslLightness, 0.5)
                    : Qt.hsla( myPalette.mid.hslHue, myPalette.mid.hslSaturation, myPalette.mid.hslLightness, 0.5)
                    width: list.width; height: 70


                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10

                        CheckBox {
                            checked: status
                            onCheckStateChanged: setStatus(index, checked)
                        }

                        ColumnLayout {
                            Text { text: '<b>Tache :</b> ' + title; color: myPalette.text; }
                            Text { text: '<b>Status :</b> ' + (status ? "Terminé" : "En cours"); color: myPalette.text; }
                        }
                    }

                    Image {
                       id: close
                       height: 20
                       width: 20
                       anchors.verticalCenter: parent.verticalCenter
                       x: index === list.hoveredIndex ? parent.width - width - 10 : parent.width + 10

                       Behavior on x { NumberAnimation { duration: 150 } }

                       source: "https://upload.wikimedia.org/wikipedia/commons/8/8f/Flat_cross_icon.svg"
                       fillMode: Image.PreserveAspectFit
                       mipmap: true

                       MouseArea {
                           anchors.fill: parent
                           onClicked: removeTodo(index)
                       }
                    }

                    MouseArea {
                        propagateComposedEvents: true
                        anchors.fill: parent
                        hoverEnabled: true
                        onHoveredChanged: list.hoveredIndex = index
                        onPressAndHold: list.hoveredIndex = index
                        onExited: list.hoveredIndex = -1
                        onPressed: mouse.accepted = false
                    }
                }

                clip: true

                // Animations
                add: Transition {
                    NumberAnimation {
                        easing {
                            type: Easing.OutElastic
                            amplitude: 1.0
                            period: 0.5
                        }
                        properties: "y";
                        duration: 1000
                    }
                }
                removeDisplaced: Transition { NumberAnimation { properties: "y"; duration: 150 } }
                remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 150 } }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            TextField {
                id: textField

                property int selectStart
                property int selectEnd
                property int curPos

                Layout.fillWidth: true
                placeholderText: "Inscrire une tache..."
                horizontalAlignment: TextEdit.AlignHCenter
                onAccepted: button.clicked()
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                selectByMouse: true

                MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        hoverEnabled: true

                        onClicked: {
                            textField.selectStart = textField.selectionStart;
                            textField.selectEnd = textField.selectionEnd;
                            textField.curPos = textField.cursorPosition;
                            contextMenu.x = mouse.x;
                            contextMenu.y = mouse.y;
                            contextMenu.open();
                            textField.cursorPosition = textField.curPos;
                            textField.select(textField.selectStart,textField.selectEnd);
                        }

                        onPressAndHold: {
                            if (mouse.source === Qt.MouseEventNotSynthesized) {
                                textField.selectStart = textField.selectionStart;
                                textField.selectEnd = textField.selectionEnd;
                                textField.curPos = textField.cursorPosition;
                                contextMenu.x = mouse.x;
                                contextMenu.y = mouse.y;
                                contextMenu.open();
                                textField.cursorPosition = textField.curPos;
                                textField.select(textField.selectStart,textField.selectEnd);
                            }
                        }

                        Menu {
                            id: contextMenu
                            MenuItem {
                                text: "Couper"
                                onTriggered: {
                                    textField.cut()
                                }
                            }
                            MenuItem {
                                text: "Copier"
                                onTriggered: {
                                    textField.copy()
                                }
                            }
                            MenuItem {
                                text: "Coller"
                                onTriggered: {
                                    textField.paste()
                                }
                            }
                        }
                    }
            }

            Button {
                id: button
                text: "Todo !"
                onClicked: if(textField.text !== "") { addTodo(textField.text, false); textField.text = ""; }
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            }
        }
    }
}
