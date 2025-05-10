import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:provider/provider.dart';

import 'package:band_names/models/band.dart';
import 'package:band_names/services/socket_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Band> bands = [];

  @override
  void initState() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.on('active-bands', _handleActiveBands);
    super.initState();
  }

  _handleActiveBands(dynamic payload) {
    bands = (payload as List).map((band) => Band.fromMap(band)).toList();
    setState(() {});
  }

  @override
  void dispose() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.off('active-bands');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Center(
          child: Text('Band Names', style: TextStyle(color: Colors.black)),
        ),
        elevation: 1,
        actions: <Widget>[
          Container(
            margin: EdgeInsets.only(right: 12),
            child:
                (socketService.serverStatus == ServerStatus.Online)
                    ? Icon(Icons.check_circle, color: Colors.green[300])
                    : Icon(Icons.offline_bolt_rounded, color: Colors.red[900]),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          _showGraph(),

          Expanded(
            child: ListView.builder(
              itemCount: bands.length,
              itemBuilder: (context, i) => _bandTile(bands[i]),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add_to_photos_outlined),
        backgroundColor: const Color.fromARGB(255, 125, 171, 194),
        elevation: 1,
        onPressed: () {
          addNewBand();
        },
      ),
    );
  }

  Widget _bandTile(Band band) {
    final socketService = Provider.of<SocketService>(context, listen: false);

    return Dismissible(
      key: Key(band.id),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) => socketService.emit('delete-band', {'id': band.id}),

      background: Container(
        padding: EdgeInsets.only(left: 10),
        color: Colors.amberAccent,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('Delete Band', style: TextStyle(color: Colors.redAccent)),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color.fromARGB(255, 125, 171, 194),
          child: Text(
            band.name.substring(0, 2),
            style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255)),
          ),
        ),
        title: Text(band.name),
        trailing: Text('${band.votes}', style: TextStyle(fontSize: 20)),
        onTap: () => socketService.socket.emit('vote-band', {'id': band.id}),
      ),
    );
  }

  addNewBand() {
    final textController = TextEditingController();
    if (Platform.isAndroid) {
      return showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              backgroundColor: const Color.fromARGB(255, 157, 205, 230),
              title: Text('New band name'),
              content: TextField(controller: textController),
              actions: <Widget>[
                MaterialButton(
                  child: Text('Add'),
                  elevation: 5,
                  textColor: const Color.fromARGB(198, 255, 255, 255),
                  onPressed: () => addBandToList(textController.text),
                ),
              ],
            ),
      );
    }
    showCupertinoDialog(
      context: context,
      builder:
          (_) => CupertinoAlertDialog(
            title: Text('New band name'),
            content: CupertinoTextField(controller: textController),
            actions: <Widget>[
              CupertinoDialogAction(
                isDefaultAction: true,
                child: Text('Add'),
                onPressed: () => addBandToList(textController.text),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: Text('Dismiss'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  void addBandToList(String name) {
    if (name.length > 1) {
      //podemos agregar
      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.emit('add-band', {'name': name});
    }
    Navigator.pop(context);
  }

  //Mostrar gráfica
  Widget _showGraph() {
    Map<String, double> dataMap = new Map();
    /*dataMap.putIfAbsent("Flutter", () => 5);
    dataMap.putIfAbsent("React", () => 5);
    dataMap.putIfAbsent("Xamarin", () => 5);
    dataMap.putIfAbsent("Ionic", () => 5);*/
    bands.forEach((band) {
      dataMap.putIfAbsent(band.name, () => band.votes.toDouble());
    });
    final List<Color> colorList = [
      Colors.blue.shade300,
      Colors.blue.shade900,
      Colors.yellow.shade300,
      Colors.yellow.shade800,
      Colors.pink.shade300,
      Colors.pink.shade900,
    ];

    return Container(
      padding: EdgeInsets.only(top: 12),
      width: double.infinity,
      height: 175,
      child: PieChart(
        dataMap: dataMap,
        chartType: ChartType.ring,
        colorList: colorList,
        centerText: "BANDS",
        legendOptions: LegendOptions(
          showLegendsInRow: false,
          legendPosition: LegendPosition.left,
          showLegends: true,
          legendTextStyle: TextStyle(fontWeight: FontWeight.bold),
        ),
        chartLegendSpacing: 16,
        chartRadius: MediaQuery.of(context).size.width / 2.1,
      ),
    );
  }
}
