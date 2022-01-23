import 'dart:convert';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  String _logradouro = "";
  String _complemento = "";
  String _bairro = "";
  String _cidade = "";
  String _uf = "";
  String _ddd = "";

  final cepController = TextEditingController();

  List _cepList = [];

  Map<String, dynamic> ?_lastRemoved;

  late int _lastRemovidedPos;


  @override
  void initState() {
    super.initState();

    _readData().then((data){
      setState(() {
        _cepList = json.decode(data!);
      });

    });
  }

  void _addCep(){
   setState(() {
     Map<String, dynamic> newCep = Map();
     newCep["title"] = cepController.text;
     newCep["logradouro"] = _logradouro;
     newCep["cidade"] = _cidade;
     newCep["bairro"] = _bairro;
     newCep["complemento"] = _complemento;
     newCep["uf"] = _uf;
     newCep["ddd"] = _ddd;
     cepController.text = "";
     _cepList.add(newCep);
     _saveData();
   });
  }

  void searchCep()async{
    String url = "http://viacep.com.br/ws/${cepController.text}/json/";
    http.Response response;
    response = await http.get(url);
    Map <String, dynamic> retorno = json.decode(response.body);

    String logradouro = retorno["logradouro"];
    String complemento = retorno["complemento"];
    String bairro = retorno["bairro"];
    String cidade = retorno["localidade"];
    String uf = retorno["uf"];
    String ddd = retorno["ddd"];

    print("resposta: "+response.body);

    setState(() {
      _logradouro = logradouro;
      _complemento = complemento;
      _bairro = bairro;
      _cidade = cidade;
      _uf = uf;
      _ddd = ddd;
      showAlertDialog(context);
    });
  }

  _limparDados(){
    setState(() {
      _logradouro = "";
      _complemento = "";
      _bairro = "";
      _cidade = "";
      _uf = "";
      _ddd = "";
    });

  }

  showAlertDialog(BuildContext context){
    Widget okButton = TextButton(
        onPressed: (){
          _addCep();
          Navigator.of(context).pop();
        },
        child: Text("OK")
    );

    AlertDialog alerta = AlertDialog(
      title: Text("${cepController.text}"),
      content: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text("CEP: $_logradouro"),
            Text("Bairro: $_bairro"),
            Text("Cidade: $_cidade"),
            Text("UF: $_uf"),
            Text("DDD: $_ddd"),

          ],
        ),
      ),
      actions: [
        okButton
      ],
    );
    showDialog(
        context: context,
        builder: (BuildContext context){
          return alerta;
        }
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Busca CEP"),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(
              children: [
                Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      controller: cepController,
                      decoration: InputDecoration(
                          labelText: "Insira um CEP",
                          labelStyle: TextStyle(color: Colors.deepOrange)
                      ),
                    ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(primary: Colors.deepOrange),
                    onPressed: (){
                    searchCep();
                   //_addCep();
                      //showAlertDialog(context);
                    },
                    child: Icon(Icons.search)
                )
              ],
            ),
          ),
          Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(top: 10),
                  itemCount: _cepList.length,
                  itemBuilder: buildItem
              ),
          )
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, index){
    return Dismissible(
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0),
          child: Icon(Icons.delete, color: Colors.white,),
        ),
      ),
        direction: DismissDirection.startToEnd,
        key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
        child: ListTile(
          title: Text(_cepList[index]["title"]),
          leading: CircleAvatar(
            child: Image.asset("images/correios.png"),
          ),
          subtitle: Text("${_cepList[index]["logradouro"]}, ${_cepList[index]["bairro"]}, ${_cepList[index]["cidade"]}, ${_cepList[index]["uf"]}"),
        ),
        onDismissed: (direction){
        setState(() {
          _lastRemoved = _cepList[index];
          //_lastRemoved = index;
          _cepList.removeAt(index);

          _saveData();
        }
        );
    },
    );
  }


  Future<io.File> _getFile() async{
    final  directory = await getApplicationDocumentsDirectory();
    return io.File("${directory.path}/data.json");
  }

  Future<io.File> _saveData() async{
    String data = json.encode(_cepList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String?> _readData() async{
    try{
      final file = await _getFile();
      return file.readAsString();
    }catch(e){
      return null;
    }
  }

}
