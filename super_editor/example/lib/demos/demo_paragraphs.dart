import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

/// Example of various paragraph configurations in an editor.
class ParagraphsDemo extends StatefulWidget {
  @override
  _ParagraphsDemoState createState() => _ParagraphsDemoState();
}

class _ParagraphsDemoState extends State<ParagraphsDemo> {
  Document _doc;
  DocumentEditor _docEditor;

  @override
  void initState() {
    super.initState();
    _doc = _createInitialDocument();
    _docEditor = DocumentEditor(document: _doc);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Editor.standard(
      editor: _docEditor,
      maxWidth: 600,
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
    );
  }
}

Document _createInitialDocument() {
  return MutableDocument(
    nodes: [
      ParagraphNode(
        id: DocumentEditor.createNodeId(),
        text: AttributedText(
          text: 'Various paragraph formations',
        ),
        metadata: {
          'blockType': 'header1',
        },
      ),
      ParagraphNode(
        id: DocumentEditor.createNodeId(),
        text: AttributedText(
          text: 'This is a short\nparagraph of text\nthat is left aligned',
        ),
      ),
      ParagraphNode(
        id: DocumentEditor.createNodeId(),
        text: AttributedText(
          text: 'This is a short\nparagraph of text\nthat is center aligned',
        ),
        metadata: {
          'textAlign': 'center',
        },
      ),
      ParagraphNode(
        id: DocumentEditor.createNodeId(),
        text: AttributedText(
          text: 'This is a short\nparagraph of text\nthat is right aligned',
        ),
        metadata: {
          'textAlign': 'right',
        },
      ),
      ParagraphNode(
        id: DocumentEditor.createNodeId(),
        text: AttributedText(
          text:
              'orem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus sed sagittis urna. Aenean mattis ante justo, quis sollicitudin metus interdum id. Aenean ornare urna ac enim consequat mollis. In aliquet convallis efficitur. Phasellus convallis purus in fringilla scelerisque. Ut ac orci a turpis egestas lobortis. Morbi aliquam dapibus sem, vitae sodales arcu ultrices eu. Duis vulputate mauris quam, eleifend pulvinar quam blandit eget.',
        ),
      ),
    ],
  );
}
