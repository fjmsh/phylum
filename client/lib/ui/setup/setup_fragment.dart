import 'package:flutter/material.dart';

abstract class SetupFragment<E extends SetupFragment<E>> extends StatefulWidget {
  const SetupFragment({super.key});

  @override
  SetupFragmentState<E> createState();
}

abstract class SetupFragmentState<E extends SetupFragment<E>> extends State<E> {
  bool handleNextPress();
}
