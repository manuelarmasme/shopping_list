import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;

  //remeber ? tells dart that this variable at the begining  at least is null
  String? _error;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    //getitems

    _loadItems();
  }

  void _loadItems() async {
    //setting the url
    final url = Uri.https(
        'flutter-shopping-list-dbb5b-default-rtdb.firebaseio.com',
        'shopping-list.json');

    try {
      //getting https result
      final response = await http.get(url);

      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Something happend fetchin the data. Try again later';
        });
      }

      if (response.body == 'null') {
        //update the ui to not loading anymore
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // convert json into a map
      final Map<String, dynamic> listData = json.decode(response.body);

      //
      final List<GroceryItem> loadedItems = [];

      //looping throught array
      for (final item in listData.entries) {
        //getting category info
        //

        final category = categories.entries
            .firstWhere(
                (catItem) => catItem.value.title == item.value['category'])
            .value;

        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }

      //update the ui

      setState(() {
        //asign new items
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (err) {
      setState(() {
        _error = 'Something wrong fetchin the data. Try again later';
      });
    }
  }

  //Function to go to the other screen
  void _addItem() async {
    //grab the var element that are returning
    final newItem = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newItem == null) {
      return;
    }

    //update the ui with the new item
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  //function to delete
  void _onRemoveItem(GroceryItem item) async {
    //get the indesx from the item if the delete fails
    final index = _groceryItems.indexOf(item);

    //because we have to update de ui
    setState(() {
      _groceryItems.remove(item);
    });

    //setting the url
    final url = Uri.https(
        'flutter-shopping-list-dbb5b-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');
    //sending the delete the response from firebase
    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      // if it fail the delete method

      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('No item yet!'),
    );

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      content = Center(
        //remeber !tells dart that this var on text is going to have  a value sooner on the future
        child: Text(_error!),
      );
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        //Dismissible helps to the delete swipe function
        itemBuilder: (ctx, index) => Dismissible(
          onDismissed: (direction) {
            _onRemoveItem(_groceryItems[index]);
          },
          key: ValueKey(_groceryItems[index].id),
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(_groceryItems[index].quantity.toString()),
          ),
        ),
      );
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text('Your Groceries'),
          actions: [
            IconButton(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: content);
  }
}
