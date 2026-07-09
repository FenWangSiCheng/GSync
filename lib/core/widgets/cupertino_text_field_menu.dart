import 'package:flutter/cupertino.dart';

/// Shared Cupertino text selection toolbar builder for editable text fields
/// across the app, ensuring consistent paste and context-menu behavior.
Widget cupertinoTextFieldContextMenu(
  BuildContext context,
  EditableTextState editableTextState,
) {
  return CupertinoAdaptiveTextSelectionToolbar.editableText(
    editableTextState: editableTextState,
  );
}
