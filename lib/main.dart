import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: ListaTarefas(),
  ));
}

class ListaTarefas extends StatefulWidget {
  @override
  _ListaTarefasState createState() => _ListaTarefasState();
}

class _ListaTarefasState extends State<ListaTarefas> {

  List toDoList = [];

  Map<String, dynamic> ultimoItemDismissed;
  int ultimoIndexItemDismissed;
  TextEditingController tfToDoController = TextEditingController();

  void addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = tfToDoController.text;
      newToDo["ok"] = false;
      toDoList.add(newToDo);

      tfToDoController.text = "";

      saveData();
    });
  }

  Future<Null> refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      toDoList.sort((a, b) {
        if (a["ok"] && !b["ok"]) {
          saveData();
          return 1;
        } else if (!a["ok"] && b["ok"]) {
          saveData();
          return -1;
        } else {
          saveData();
          return 0;
        }
      });
      return null;
    });
  }

  Future<File> getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> saveData() async {
    String data = json.encode(toDoList);

    final file = await getFile();
    return file.writeAsString(data);
  }

  Future<String> readData() async {
    try {
      final file = await getFile();

      return file.readAsString();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        title: Text(
          "Lista de Tarefas",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: tfToDoController,
                    decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.blueAccent)),
                  ),
                ),
                Container(
                  color: Colors.blueAccent,
                  height: 50,
                  child: RaisedButton(
                    color: Colors.blueAccent,
                    child: Row(
                      children: <Widget>[
                        Text(
                          "ADD",
                          style: TextStyle(color: Colors.white),
                        ),
                        Icon(
                          Icons.add,
                          color: Colors.white,
                        )
                      ],
                    ),
                    onPressed: addToDo,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
                child: ListView.builder(
                    itemCount: toDoList.length,
                    padding: EdgeInsets.only(top: 10),
                    itemBuilder: buildItem),
                onRefresh: refresh),
          )
        ],
      ),
    );
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
            alignment: Alignment(-0.7, 0),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
                Text(
                  "Remover",
                  style: TextStyle(color: Colors.white),
                )
              ],
            )),
      ),
      child: CheckboxListTile(
        title: Text(toDoList[index]["title"]),
        value: toDoList[index]["ok"],
        onChanged: (c) {
          setState(() {
            toDoList[index]["ok"] = c;
            saveData();
          });
        },
        secondary: CircleAvatar(
          child: Icon(toDoList[index]["ok"] ? Icons.check : Icons.error),
        ),
      ),
      onDismissed: (direction) {
        setState(() {
          ultimoItemDismissed = Map.from(toDoList[index]);
          ultimoIndexItemDismissed = index;
          toDoList.removeAt(index);

          saveData();

          final snack = SnackBar(
            duration: Duration(seconds: 2),
            content:
                Text("Tarefa \"${ultimoItemDismissed["title"]}\" removida!"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  toDoList.insert(
                      ultimoIndexItemDismissed, ultimoItemDismissed);
                  saveData();
                });
              },
            ),
          );
          Scaffold.of(context).showSnackBar(snack);
        });
      },
      direction: DismissDirection.startToEnd,
    );
  }

  @override
  void initState() {
    super.initState();
    readData().then((data) {
      setState(() {
        toDoList = json.decode(data);
      });
    });
  }
}
