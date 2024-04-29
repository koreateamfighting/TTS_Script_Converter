import 'package:sticky_az_list/sticky_az_list.dart';

class Contents extends TaggedItem {
  final String contents;

  Contents({required this.contents});

  @override
  String sortName() => contents;
}