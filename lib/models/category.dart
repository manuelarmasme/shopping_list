import 'package:flutter/material.dart';

enum Categories {
  vegetables,
  fruit,
  meat,
  dairy,
  carbs,
  sweets,
  spices,
  convenience,
  hygiene,
  other
}


class Category {
  //these are positional arguments and not by name because the order matters
  const Category(
    this.title,
    this.color
  );

  final String title;
  final Color color;
}