import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// TODO: Save Pokemon local on Device
// TODO: Add Search for Pokemon
// TODO: Find out how to use the SimpleDialog withina function to reduce code complexity
// TODO: Create own files for Pokemon/Ability

void main() {
  // debugPaintSizeEnabled = true;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class Ability {
  final String name;
  final String url;
  final bool isHidden;
  final int slot;
  bool _infosAlreadyFetched = false;
  String germaneName = '';
  String germanFlavorText = '';
  String germanDescription = '';

  /// Generates a Ability from a given JSON-String
  Ability.fromJson(Map<String, dynamic> json)
      : name = json['ability']['name'],
        url = json['ability']['url'],
        isHidden = json['is_hidden'],
        slot = json['slot'];

  /// Fetches further Information for the ability
  Future<bool> fetchInfos() async {
    if (_infosAlreadyFetched) {
      return true;
    }

    var url = Uri.parse(this.url);
    var response = await http.get(url);

    // Search for the german Name of the ability
    for (var entry in jsonDecode(response.body)['names']) {
      if (entry['language']['name'] == 'de') {
        germaneName = entry['name'];
        break;
      }
    }

    // Search for the german flavor Text of the ability
    for (var entry in jsonDecode(response.body)['flavor_text_entries']) {
      if (entry['language']['name'] == 'de') {
        germanFlavorText = entry['flavor_text'];
      }
    }

    // Search for the german description
    for (var entry in jsonDecode(response.body)['effect_entries']) {
      if (entry['language']['name'] == 'de') {
        germanDescription = entry['effect'];
      }
    }

    _infosAlreadyFetched = true;

    return true;
  }

  /// Fetches the german name of the ability
  Future<bool> fetchGermanName() async {
    if (germaneName != '') {
      return true;
    }

    var url = Uri.parse(this.url);
    var response = await http.get(url);

    for (var entry in jsonDecode(response.body)['names']) {
      if (entry['language']['name'] == 'de') {
        germaneName = entry['name'];
        break;
      }
    }

    return true;
  }
}

class Pokemon {
  final String name;
  final int id;
  final String spriteFrontDefault;
  final String spriteBackDefault;
  final String species;
  final String speciesUrl;
  int hp = 0;
  int attack = 0;
  int defense = 0;
  List<Ability> abilityList = [];
  String germanName = '';

  Pokemon.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        spriteFrontDefault = json['sprites']['front_default'],
        spriteBackDefault = json['sprites']['back_default'],
        species = json['species']['name'],
        speciesUrl = json['species']['url'] {
    for (var entry in json['abilities']) {
      var ability = Ability.fromJson(entry);
      abilityList.add(ability);
    }

    for (var entry in json['stats']) {
      if (entry['stat']['name'] == 'hp') {
        hp = entry['base_stat'];
      } else if (entry['stat']['name'] == 'attack') {
        attack = entry['base_stat'];
      } else if (entry['stat']['name'] == 'defense') {
        defense = entry['base_stat'];
      }
    }

    debugPrint('$hp');
    debugPrint('$attack');
    debugPrint('$defense');
  }

  fetchGermanName() async {
    var url = Uri.parse(speciesUrl);
    var response = await http.get(url);

    for (var entry in jsonDecode(response.body)['names']) {
      if (entry['language']['name'] == 'de') {
        germanName = entry['name'];
        break;
      }
    }

    //return '';
  }
}

class _MyHomePageState extends State<MyHomePage> {
  final List<Pokemon> _pokemonList = [];

  _MyHomePageState() {
    // _readPokemon();
  }

  void _readPokemon() async {
    debugPrint('Start reading');

    setState(() {
      _pokemonList.clear();
    });

    var url = Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=3&offset=0');
    var response = await http.get(url);
    var json = jsonDecode(response.body);

    debugPrint('Fetching Pokemon done!');

    int counter = 0;
    for (var entry in json['results']) {
      debugPrint('Fetching Pokemon $counter of 50');
      ++counter;

      var url = Uri.parse(entry['url']);
      var response = await http.get(url);

      var p = Pokemon.fromJson(jsonDecode(response.body));

      await p.fetchGermanName();

      setState(() {
        _pokemonList.add(p);
      });
    }

    debugPrint('All Pokemon fetched');
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: ListView.builder(
        itemCount: _pokemonList.length,
        itemBuilder: (BuildContext context, int index) {
          var p = _pokemonList[index];
          return ListTile(
            leading: Image.network(p.spriteFrontDefault),
            title: Text(p.germanName),
            onTap: () {
              var name = p.germanName;
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => DetailPage(p: p)));
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _readPokemon,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class DetailPage extends StatelessWidget {
  const DetailPage({required this.p, Key? key}) : super(key: key);
  final Pokemon p;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Details zu ' + p.germanName),
      ),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  p.germanName,
                  style: Theme.of(context).textTheme.headline3,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Image.network(p.spriteFrontDefault),
              Image.network(p.spriteBackDefault),
            ],
          ),
          Expanded(
            child: ListView.builder(
                itemCount: p.abilityList.length,
                itemBuilder: (BuildContext context, int index) {
                  var ability = p.abilityList[index];
                  return FutureBuilder<bool>(
                    future: ability.fetchInfos(),
                    builder: (context, AsyncSnapshot<bool> snapshot) {
                      if (snapshot.hasData) {
                        return ListTile(
                          title: Text(ability.germaneName),
                          subtitle: Text(ability.germanFlavorText),
                          onTap: () {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) => AlertDialog(
                                      title: Text(ability.germaneName),
                                      content: Text(ability.germanDescription),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Schließen'),
                                        ),
                                      ],
                                    ));
                          },
                        );
                      } else {
                        return Row(
                          children: const [CircularProgressIndicator()],
                        );
                      }
                    },
                  );
                  // return ListTile(
                  //   title: Text(p.abilityList[index].germaneName),
                  // );
                }),
          )
        ],
      ),
    );
  }
}
