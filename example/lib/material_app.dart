import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:ui' as ui show PlaceholderAlignment;

import 'package:example/data.dart';

class MyMaterialApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_typeahead demo',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
          appBar: AppBar(
            title: TabBar(tabs: [
              Tab(text: 'Example 1: Navigation'),
              Tab(text: 'Example 2: Form'),
              Tab(text: 'Example 3: Scroll')
            ]),
          ),
          body: TabBarView(children: [
            NavigationExample(),
            FormExample(),
            ScrollExample(),
          ])),
    );
  }
}

class NavigationExample extends StatelessWidget {
  TextEditingController controller = TextEditingController();
  EmailSpanBuilder _emailSpanBuilder;

  @override
  Widget build(BuildContext context) {
    _emailSpanBuilder = EmailSpanBuilder(controller, context);
    return Padding(
      padding: EdgeInsets.all(32.0),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 10.0,
          ),
          TypeAheadField(
            textFieldConfiguration: TextFieldConfiguration(
              autofocus: true,
              controller: controller,
              style: DefaultTextStyle.of(context)
                  .style
                  .copyWith(fontStyle: FontStyle.italic),
              decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'What are you looking for?'),
            ),
            specialTextSpanBuilder: _emailSpanBuilder,
            suggestionsCallback: (pattern) async {
              return await BackendService.getSuggestions(pattern);
            },
            itemBuilder: (context, suggestion) {
              return ListTile(
                leading: Icon(Icons.shopping_cart),
                title: Text(suggestion['name']),
                subtitle: Text('\$${suggestion['price']}'),
              );
            },
            onSuggestionSelected: (suggestion) {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ProductPage(product: suggestion)));
            },
          ),
        ],
      ),
    );
  }
}

class FormExample extends StatefulWidget {
  @override
  _FormExampleState createState() => _FormExampleState();
}

class _FormExampleState extends State<FormExample> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _typeAheadController = TextEditingController();

  String _selectedCity;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: this._formKey,
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          children: <Widget>[
            Text('What is your favorite city?'),
            TypeAheadFormField(
              textFieldConfiguration: TextFieldConfiguration(
                decoration: InputDecoration(labelText: 'City'),
                controller: this._typeAheadController,
              ),
              suggestionsCallback: (pattern) {
                return CitiesService.getSuggestions(pattern);
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  title: Text(suggestion),
                );
              },
              transitionBuilder: (context, suggestionsBox, controller) {
                return suggestionsBox;
              },
              onSuggestionSelected: (suggestion) {
                this._typeAheadController.text = suggestion;
              },
              validator: (value) {
                if (value.isEmpty) {
                  return 'Please select a city';
                }
              },
              onSaved: (value) => this._selectedCity = value,
            ),
            SizedBox(
              height: 10.0,
            ),
            RaisedButton(
              child: Text('Submit'),
              onPressed: () {
                if (this._formKey.currentState.validate()) {
                  this._formKey.currentState.save();
                  Scaffold.of(context).showSnackBar(SnackBar(
                      content:
                      Text('Your Favorite City is ${this._selectedCity}')));
                }
              },
            )
          ],
        ),
      ),
    );
  }
}

class ScrollExample extends StatelessWidget {
  final List<String> items = List.generate(5, (index) => "Item $index");

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Suggestion box will resize when scrolling"),
          )),
      SizedBox(height: 200),
      TypeAheadField<String>(
        getImmediateSuggestions: true,
        textFieldConfiguration: TextFieldConfiguration(
          decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'What are you looking for?'),
        ),
        suggestionsCallback: (String pattern) async {
          return items
              .where((item) =>
              item.toLowerCase().startsWith(pattern.toLowerCase()))
              .toList();
        },
        itemBuilder: (context, String suggestion) {
          return ListTile(
            title: Text(suggestion),
          );
        },
        onSuggestionSelected: (String suggestion) {
          print("Suggestion selected");
        },
      ),
      SizedBox(height: 500),
    ]);
  }
}

class ProductPage extends StatelessWidget {
  final Map<String, dynamic> product;

  ProductPage({this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          children: [
            Text(
              this.product['name'],
              style: Theme.of(context).textTheme.headline,
            ),
            Text(
              this.product['price'].toString() + ' USD',
              style: Theme.of(context).textTheme.subhead,
            )
          ],
        ),
      ),
    );
  }
}

class EmailSpanBuilder extends SpecialTextSpanBuilder {
  EmailSpanBuilder(this.controller, this.context);
  final TextEditingController controller;
  final BuildContext context;
  @override
  SpecialText createSpecialText(String flag,
      {TextStyle textStyle,SpecialTextGestureTapCallback onTap, int index}) {
    if (flag == null || flag == '') {
      return null;
    }

    if (!flag.startsWith(' ') && !flag.startsWith('@')) {
      return EmailText(textStyle, onTap,
          start: index,
          context: context,
          controller: controller,
          startFlag: flag);
    }
    return null;
  }
}

class EmailText extends SpecialText {
  EmailText(TextStyle textStyle, SpecialTextGestureTapCallback onTap,
      {this.start, this.controller, this.context, String startFlag})
      : super(startFlag, ' ', textStyle, onTap: onTap);
  final TextEditingController controller;
  final int start;
  final BuildContext context;
  @override
  bool isEnd(String value) {
    final int index = value.indexOf('@');
    final int index1 = value.indexOf('.');

    return index >= 0 &&
        index1 >= 0 &&
        index1 > index + 1 &&
        super.isEnd(value);
  }

  @override
  InlineSpan finishText() {
    final String text = toString();

    return ExtendedWidgetSpan(
      actualText: text,
      start: start,
      alignment: ui.PlaceholderAlignment.middle,
      child: GestureDetector(
        child: Padding(
          padding: const EdgeInsets.only(right: 5.0, top: 2.0, bottom: 2.0),
          child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(5.0)),
              child: Container(
                padding: const EdgeInsets.all(5.0),
                color: Colors.orange,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      text.trim(),
                      //style: textStyle?.copyWith(color: Colors.orange),
                    ),
                    const SizedBox(
                      width: 5.0,
                    ),
                    InkWell(
                      child: Icon(
                        Icons.close,
                        size: 15.0,
                      ),
                      onTap: () {
                        controller.value = controller.value.copyWith(
                            text: controller.text
                                .replaceRange(start, start + text.length, ''),
                            selection: TextSelection.fromPosition(
                                TextPosition(offset: start)));
                      },
                    )
                  ],
                ),
              )),
        ),
        onTap: () {
          showDialog<void>(
              context: context,
              barrierDismissible: true,
              builder: (BuildContext c) {
                final TextEditingController textEditingController =
                TextEditingController()..text = text.trim();
                return Column(
                  children: <Widget>[
                    Expanded(
                      child: Container(),
                    ),
                    Material(
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: TextField(
                            controller: textEditingController,
                            decoration: InputDecoration(
                                suffixIcon: FlatButton(
                                  child: const Text('OK'),
                                  onPressed: () {
                                    controller.value = controller.value.copyWith(
                                        text: controller.text.replaceRange(
                                            start,
                                            start + text.length,
                                            textEditingController.text + ' '),
                                        selection: TextSelection.fromPosition(
                                            TextPosition(
                                                offset: start +
                                                    (textEditingController.text + ' ')
                                                        .length)));

                                    Navigator.pop(context);
                                  },
                                )),
                          ),
                        )),
                    Expanded(
                      child: Container(),
                    )
                  ],
                );
              });
        },
      ),
      deleteAll: true,
    );
  }
}
