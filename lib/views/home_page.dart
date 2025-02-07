import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:todo_list/helpers/task_helper.dart';
import 'package:todo_list/models/task.dart';
import 'package:todo_list/views/task_dialog.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int block;
  List<Task> _taskList = [];
  TaskHelper _helper = TaskHelper();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _helper.getAll().then((list) {
      setState(() {
        _taskList = list;
        _loading = false;
      });
    });
  }

  double _percent() {
    int total = _taskList.length;
    int isDone = _taskList.where((t) => t.isDone).length;
    return isDone / total;
  }

  String _namePercent() {
    int total = _taskList.length;
    int isDone = _taskList.where((t) => t.isDone).length;
    double result = (isDone / total) * 100;
    return result.isNaN ? '0' : result.toStringAsFixed(1).toString();
  }

  double _corPercent() {
    int total = _taskList.length;
    int isDone = _taskList.where((t) => t.isDone).length;
    double result = (isDone / total) * 100;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Tarefas'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: CircularPercentIndicator(
              radius: 50.0,
              lineWidth: 5.0,
              percent: _percent(),
              backgroundColor: Colors.white,
              center: Text(_namePercent()),
              progressColor: _corPercent() <= 25
                  ? Colors.red
                  : _corPercent() <= 50
                      ? Colors.orange
                      : _corPercent() <= 75 ? Colors.yellow : Colors.green,
            ),
          )
        ],
      ),
      floatingActionButton:
          FloatingActionButton(child: Icon(Icons.add), onPressed: _addNewTask),
      body: _buildTaskList(),
    );
  }

  Widget _buildTaskList() {
    if (_taskList.isEmpty) {
      return Center(
        child: _loading ? CircularProgressIndicator() : Text("Sem Tarefas!"),
      );
    } else {
      return ListView.separated(
        separatorBuilder: (BuildContext context, int index) => Divider(),
        itemBuilder: _buildTaskItemSlidable,
        itemCount: _taskList.length,
      );
    }
  }

  Widget _buildTaskItem(BuildContext context, int index) {
    final task = _taskList[index];
    return ListTileTheme(
      contentPadding: EdgeInsets.only(left: 3.0, right: 15.0),
      child: CheckboxListTile(
        activeColor: Colors.red,
        value: task.isDone,
        title: Text(task.title),
        subtitle: Text(task.description),
        secondary: Container(
          constraints: BoxConstraints.expand(width: 8.0),
          color: task.getPriorityColor(),
        ),
        onChanged: (bool isChecked) {
          setState(() {
            task.isDone = isChecked;
          });

          _helper.update(task);
        },
      ),
    );
  }

  Widget _buildTaskItemSlidable(BuildContext context, int index) {
    return Slidable(
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.25,
      child: _buildTaskItem(context, index),
      actions: <Widget>[
        IconSlideAction(
          caption: 'Editar',
          color: Colors.red,
          icon: Icons.edit,
          onTap: () {
            _addNewTask(editedTask: _taskList[index], index: index);
          },
        ),
        IconSlideAction(
          caption: 'Deletar',
          color: Colors.red,
          icon: Icons.delete,
          onTap: () {
            setState(() {
              block = 0;
            });
            _deleteTask(deletedTask: _taskList[index], index: index);
          },
        ),
      ],
    );
  }

  Future _addNewTask({Task editedTask, int index}) async {
    final task = await showDialog<Task>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return TaskDialog(task: editedTask);
      },
    );

    if (task != null) {
      setState(() {
        if (index == null) {
          _taskList.add(task);
          _helper.save(task);
        } else {
          _taskList[index] = task;
          _helper.update(task);
        }
      });
    }
  }

  void _deleteTask({Task deletedTask, int index}) {
    setState(() {
      _taskList.removeAt(index);
    });

    _helper.delete(deletedTask.id);

    Flushbar(
      title: "Deletando Tarefa",
      message: "Tarefa \"${deletedTask.title}\" foi Deletada.",
      margin: EdgeInsets.all(8),
      borderRadius: 8,
      duration: Duration(seconds: 3),
      mainButton: FlatButton(
        child: Text(
          "Undo",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          if (block < 1) {
            setState(() {
              block++;
              _taskList.insert(index, deletedTask);
              _helper.update(deletedTask);
            });
          }
        },
      ),
    )..show(context);
  }
}
