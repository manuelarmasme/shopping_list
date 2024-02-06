import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/category.dart';
import 'package:shopping_list/models/grocery_item.dart';

import 'package:http/http.dart' as http;

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() {
    return _NewItemState();
  }
}

class _NewItemState extends State<NewItem> {
  //form key
  final _formKey = GlobalKey<FormState>();

  //forms values
  var _enteredName = '';
  var _enteredQuantity = 1;

  //this var hels to have an initial value into the dropdown
  var _selectedCategory = categories[Categories.vegetables]!;

  //var to show spinner and disable buttons
  var _isSending = false;

  //function to save an item
  void _saveItem() async {
    //! this tells flutter that it won't be null
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      //update the ui to show the button
      setState(() {
        _isSending = true;
      });

      //setting the url
      final url = Uri.https(
          'flutter-shopping-list-dbb5b-default-rtdb.firebaseio.com',
          'shopping-list.json');

      //sending to firebase
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        //we need to convert into json because on the header we are telling that this data is json
        body: json.encode({
          'name': _enteredName,
          'quantity': _enteredQuantity,
          'category': _selectedCategory.title,
        }),
      );

      final Map<String, dynamic> resData = json.decode(response.body);

      //if this context is not part anymore of this
      //we finish this app
      if (!context.mounted) {
        return;
      }

      Navigator.of(context).pop(GroceryItem(
        id: resData['name'],
        name: _enteredName,
        quantity: _enteredQuantity,
        category: _selectedCategory,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create a new Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                maxLength: 50,
                decoration: const InputDecoration(label: Text('name')),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      value.trim().length <= 1 ||
                      value.trim().length > 50) {
                    return 'Must be between 1 and 50 characteres';
                  }

                  return null;
                },
                onSaved: (value) {
                  // ! telling flutter it won't be null
                  _enteredName = value!;
                },
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration:
                          const InputDecoration(label: Text('quantity')),
                      keyboardType: TextInputType.number,
                      initialValue: _enteredQuantity.toString(),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            int.tryParse(value) == null ||
                            //we are using ! to tell dart that in this case the value is not null
                            //because if it null the upper validation will be active
                            int.tryParse(value)! <= 0) {
                          return 'Must be a positive number';
                        }

                        return null;
                      },
                      onSaved: (value) {
                        //we use parse because it shows error and not null like tryparse
                        _enteredQuantity = int.parse(value!);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  //We have to wrap into an expanded because it cause problem with the row
                  Expanded(
                    child: DropdownButtonFormField(
                        value: _selectedCategory,
                        items: [
                          for (final category in categories.entries)
                            DropdownMenuItem(
                              value: category.value,
                              child: Row(
                                children: [
                                  Container(
                                    height: 16,
                                    width: 16,
                                    color: category.value.color,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(category.value.title)
                                ],
                              ),
                            )
                        ],
                        onChanged: (value) {
                          //we use set state because depending on the selected option we have to update de UI
                          setState(() {
                            _selectedCategory = value!;
                          });
                        }),
                  )
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSending
                        ? null
                        : () {
                            _formKey.currentState!.reset();
                          },
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                    onPressed: _isSending ? null : _saveItem,
                    child: _isSending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(),
                          )
                        : const Text('Add Item'),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
