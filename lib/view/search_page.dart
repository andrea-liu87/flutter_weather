import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  SearchPage._({Key? key}) : super(key: key);

  static Route<String> route() {
    return MaterialPageRoute(builder: (_) => SearchPage._());
  }

  @override
  State<StatefulWidget> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();

  String get _text => _controller.text;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('City Search'),
      ),
      body: Row(
        children: [
          Expanded(
              child: Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              decoration:
                  InputDecoration(labelText: 'City', hintText: 'Chicago'),
            ),
          )),
          IconButton(
              key: Key('searchPage_search_iconButton'),
              onPressed: () => Navigator.of(context).pop(_text),
              icon: Icon(Icons.search))
        ],
      ),
    );
  }
}
