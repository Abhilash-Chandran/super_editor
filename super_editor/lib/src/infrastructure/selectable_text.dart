import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Queries and calculates text position and offset details
/// for a text display.
abstract class TextLayout {
  /// Returns the `TextPosition` within this `TextLayout` that
  /// is closest to the given `localOffset`, or -1 if the text
  /// is not laid out yet.
  TextPosition getPositionAtOffset(Offset localOffset);

  /// Returns the (x, y) `Offset` closest to the given `position`, or
  /// `null` if the text is not laid out yet.
  Offset? getOffsetForPosition(TextPosition position);

  /// Returns the `TextPosition` at the start of the line that
  /// contains the given `currentPosition`, or -1 if the text
  /// is not laid out yet.
  TextPosition getPositionAtStartOfLine({
    required TextPosition currentPosition,
  });

  /// Returns the `TextPosition` at the end of the line that
  /// contains the given `currentPosition`, or -1 if the text
  /// is not laid out yet.
  TextPosition getPositionAtEndOfLine({
    required TextPosition currentPosition,
  });

  /// Returns the `TextPosition` that's one line above the
  /// given `currentPosition`, or `null` if there is no line
  /// above `currentPosition` or the text is not laid out yet.
  TextPosition? getPositionOneLineUp({
    required TextPosition currentPosition,
  });

  /// Returns the `TextPosition` that's one line below the
  /// given `currentPosition`, or `null` if there is no line
  /// below `currentPosition` or the text is not laid out yet.
  TextPosition? getPositionOneLineDown({
    required TextPosition currentPosition,
  });

  /// Returns the `TextPosition` in the first line within this
  /// `TextLayout` that is closest to the given `x`-value, or
  /// -1 if the text is not laid out yet.
  TextPosition getPositionInFirstLineAtX(double x);

  /// Returns the `TextPosition` in the last line within this
  /// `TextLayout` that is closest to the given `x`-value, or
  /// -1 if the text is not laid out yet.
  TextPosition getPositionInLastLineAtX(double x);

  /// Returns `true` if the given `localOffset` intersects any
  /// text within this `TextLayout`, otherwise returns `false`.
  bool isTextAtOffset(Offset localOffset);

  /// Returns the local `Rect` that is formed by intersecting
  /// the given `region` in the `ancestorCoordinateSpace` with
  /// this `TextLayout`, or `Rect.zero` if the text is not laid
  /// out yet.
  Rect calculateLocalOverlap({
    required Rect region,
    required RenderObject ancestorCoordinateSpace,
  });

  /// Returns the `TextSelection` that corresponds to a selection
  /// rectangle formed by the span from `baseOffset` to `extentOffset`, or
  /// a collapsed selection at -1 if the text is not laid out yet.
  ///
  /// The `baseOffset` determines where the selection begins. The
  /// `extentOffset` determines where the selection ends.
  TextSelection getSelectionInRect(Offset baseOffset, Offset extentOffset);
}

/// Displays text with a selection highlight and a caret.
///
/// `SelectableText` does not recognize any user interaction. It's the
/// responsibility of ancestor widgets to recognize interactions that
/// should alter this widget's text selection and/or caret position.
///
/// `textSelection` determines the span of text to be painted
/// with a selection highlight.
///
/// `showCaret` and `textSelection` together determine whether or not the
/// caret is painted in this `SelectableText`. If `textSelection` is collapsed
/// with an offset less than 0 then no caret is displayed. If `showCaret` is
/// false then no caret is displayed. If `textSelection` has a `baseOffset`
/// or `extentOffset` that is >= zero and `showCaret` is true then a caret is
/// displayed. An explicit `showCaret` control is offered because multiple
/// `SelectableText` widgets might be displayed together with a selection
/// spanning multiple `SelectableText` widgets, but only one of the
/// `SelectableText` widgets displays a caret.
///
/// If `text` is empty, and a `textSelection` with an extent >= 0 is provided, and
/// `highlightWhenEmpty` is `true`, then `SelectableText` will paint a small
/// highlight, despite having no content. This is useful when showing that
/// one or more empty text areas are selected.
class SelectableText extends StatefulWidget {
  /// `SelectableText` that displays plain text (only one text style).
  SelectableText.plain({
    Key? key,
    required String text,
    required TextStyle style,
    this.textAlign = TextAlign.left,
    this.textSelection = const TextSelection.collapsed(offset: -1),
    this.textSelectionDecoration = const TextSelectionDecoration(
      selectionColor: Color(0xFFACCEF7),
    ),
    this.showCaret = false,
    this.textCaretFactory = const TextCaretFactory(
      color: Colors.black,
      width: 1,
      borderRadius: BorderRadius.zero,
    ),
    this.highlightWhenEmpty = false,
  })  : richText = TextSpan(text: text, style: style),
        super(key: key);

  /// `SelectableText` that displays styled text.
  SelectableText({
    Key? key,
    required TextSpan textSpan,
    this.textAlign = TextAlign.left,
    this.textSelection = const TextSelection.collapsed(offset: -1),
    this.textSelectionDecoration = const TextSelectionDecoration(
      selectionColor: Color(0xFFACCEF7),
    ),
    this.highlightWhenEmpty = false,
    this.showCaret = false,
    this.textCaretFactory = const TextCaretFactory(
      color: Colors.black,
      width: 1,
      borderRadius: BorderRadius.zero,
    ),
  })  : richText = textSpan,
        super(key: key);

  /// The text to display in this `SelectableText` widget.
  final TextSpan richText;

  /// The alignment to use for `richText` display.
  final TextAlign textAlign;

  /// The portion of `richText` to display with the
  /// `textSelectionDecoration`.
  final TextSelection textSelection;

  /// The visual decoration to apply to the `textSelection`.
  final TextSelectionDecoration textSelectionDecoration;

  /// Builds the visual representation of the caret in this
  /// `SelectableText` widget.
  final TextCaretFactory textCaretFactory;

  /// True to show a thin selection highlight when `richText`
  /// is empty, or false to avoid showing a selection highlight
  /// when `richText` is empty.
  ///
  /// This is useful when multiple `SelectableText` widgets
  /// are selected and some of the selected `SelectableText`
  /// widgets are empty.
  final bool highlightWhenEmpty;

  /// True to display a caret in this `SelectableText` at
  /// the `extent` of `textSelection`, or false to avoid
  /// displaying a caret.
  final bool showCaret;

  @override
  SelectableTextState createState() => SelectableTextState();
}

class SelectableTextState extends State<SelectableText> implements TextLayout {
  // `GlobalKey` that provides access to the `RenderParagraph` associated
  // with the text that this `SelectableText` widget displays.
  final GlobalKey _textKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _updateTextLength();
  }

  @override
  void didUpdateWidget(SelectableText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.richText != oldWidget.richText) {
      _updateTextLength();
    }
  }

  // The current length of the text displayed by this widget. The value
  // is cached because computing the length of rich text may have
  // non-trivial performance implications.
  late int _cachedTextLength;
  int get _textLength => _cachedTextLength;
  void _updateTextLength() {
    _cachedTextLength = widget.richText.toPlainText().length;
  }

  RenderParagraph? get _renderParagraph => _textKey.currentContext?.findRenderObject() as RenderParagraph;

  // TODO: use TextPainter line height when Flutter makes the info available. (#46)
  double get _lineHeight {
    final fontSize = widget.richText.style?.fontSize;
    final lineHeight = widget.richText.style?.height;
    if (fontSize != null && lineHeight != null) {
      return fontSize * lineHeight;
    } else {
      return 16;
    }
  }

  @override
  TextPosition getPositionAtOffset(Offset localOffset) {
    if (_renderParagraph == null) {
      return TextPosition(offset: -1);
    }

    return _renderParagraph!.getPositionForOffset(localOffset);
  }

  @override
  Offset getOffsetForPosition(TextPosition position) {
    if (_renderParagraph == null) {
      throw Exception('SelectableText does not yet have a RenderParagraph. Can\'t getOffsetForPosition().');
    }

    return _renderParagraph!.getOffsetForCaret(position, Rect.zero);
  }

  @override
  TextPosition getPositionAtStartOfLine({
    required TextPosition currentPosition,
  }) {
    if (_renderParagraph == null) {
      return TextPosition(offset: -1);
    }

    final renderParagraph = _renderParagraph!;
    final positionOffset = renderParagraph.getOffsetForCaret(currentPosition, Rect.zero);
    final endOfLineOffset = Offset(0, positionOffset.dy);
    return renderParagraph.getPositionForOffset(endOfLineOffset);
  }

  @override
  TextPosition getPositionAtEndOfLine({
    required TextPosition currentPosition,
  }) {
    if (_renderParagraph == null) {
      return TextPosition(offset: -1);
    }

    final renderParagraph = _renderParagraph!;
    final positionOffset = renderParagraph.getOffsetForCaret(currentPosition, Rect.zero);
    final endOfLineOffset = Offset(renderParagraph.size.width, positionOffset.dy);
    return renderParagraph.getPositionForOffset(endOfLineOffset);
  }

  @override
  TextPosition? getPositionOneLineUp({
    required TextPosition currentPosition,
  }) {
    if (_renderParagraph == null) {
      return null;
    }

    final renderParagraph = _renderParagraph!;
    final lineHeight = _lineHeight;
    // Note: add half the line height to the current offset to help deal with
    //       line heights that aren't accurate.
    final currentSelectionOffset =
        renderParagraph.getOffsetForCaret(currentPosition, Rect.zero) + Offset(0, lineHeight / 2);
    final oneLineUpOffset = currentSelectionOffset - Offset(0, lineHeight);

    if (oneLineUpOffset.dy < 0) {
      // The first line is selected. There is no line above this.
      return null;
    }

    return renderParagraph.getPositionForOffset(oneLineUpOffset);
  }

  @override
  TextPosition? getPositionOneLineDown({
    required TextPosition currentPosition,
  }) {
    if (_renderParagraph == null) {
      return null;
    }

    final renderParagraph = _renderParagraph!;
    final lineHeight = _lineHeight;
    // Note: add half the line height to the current offset to help deal with
    //       line heights that aren't accurate.
    final currentSelectionOffset =
        renderParagraph.getOffsetForCaret(currentPosition, Rect.zero) + Offset(0, lineHeight / 2);
    final oneLineDownOffset = currentSelectionOffset + Offset(0, lineHeight);

    if (oneLineDownOffset.dy > renderParagraph.size.height) {
      // The last line is selected. There is no line below that.
      return null;
    }

    return renderParagraph.getPositionForOffset(oneLineDownOffset);
  }

  @override
  TextPosition getPositionInFirstLineAtX(double x) {
    return getPositionAtOffset(
      Offset(x, 0),
    );
  }

  @override
  TextPosition getPositionInLastLineAtX(double x) {
    if (_renderParagraph == null) {
      return TextPosition(offset: -1);
    }

    return getPositionAtOffset(
      Offset(x, _renderParagraph!.size.height),
    );
  }

  TextSelection getWordSelectionAt(TextPosition position) {
    if (_renderParagraph == null) {
      return TextSelection.collapsed(offset: -1);
    }

    final wordRange = _renderParagraph!.getWordBoundary(position);
    return TextSelection(
      baseOffset: wordRange.start,
      extentOffset: wordRange.end,
    );
  }

  bool isTextAtOffset(Offset localOffset) {
    if (_renderParagraph == null) {
      return false;
    }

    List<TextBox> boxes = _renderParagraph!.getBoxesForSelection(
      TextSelection(
        baseOffset: 0,
        extentOffset: _textLength,
      ),
    );

    for (final box in boxes) {
      if (box.toRect().contains(localOffset)) {
        return true;
      }
    }

    return false;
  }

  @override
  Rect calculateLocalOverlap({
    required Rect region,
    required RenderObject ancestorCoordinateSpace,
  }) {
    if (_renderParagraph == null) {
      return Rect.zero;
    }

    final renderParagraph = _renderParagraph!;
    final contentOffset = renderParagraph.localToGlobal(Offset.zero, ancestor: ancestorCoordinateSpace);
    final textRect = contentOffset & renderParagraph.size;

    if (region.overlaps(textRect)) {
      // Report the overlap in our local coordinate space.
      return region.translate(-contentOffset.dx, -contentOffset.dy);
    } else {
      return Rect.zero;
    }
  }

  @override
  TextSelection getSelectionInRect(Offset baseOffset, Offset extentOffset) {
    if (_renderParagraph == null) {
      return TextSelection.collapsed(offset: -1);
    }

    final renderParagraph = _renderParagraph!;
    final contentHeight = renderParagraph.size.height;
    final textLength = _textLength;

    // We don't know whether the base offset is higher or lower than the
    // extent offset. Regardless, if either offset is above the top of
    // the text then that text position should be 0. If either offset
    // is below the bottom of the text then that offset should be the
    // total length of the text.
    final basePosition = baseOffset.dy < 0
        ? 0
        : baseOffset.dy > contentHeight
            ? textLength
            : renderParagraph.getPositionForOffset(baseOffset).offset;
    final extentPosition = extentOffset.dy < 0
        ? 0
        : extentOffset.dy > contentHeight
            ? textLength
            : renderParagraph.getPositionForOffset(extentOffset).offset;

    final selection = TextSelection(
      baseOffset: basePosition,
      extentOffset: extentPosition,
    );

    return selection;
  }

  @override
  Widget build(BuildContext context) {
    if (_renderParagraph == null) {
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
        setState(() {
          // Force another frame so that we can use the renderParagraph.
        });
      });
    }

    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          child: _buildTextSelection(),
        ),
        SizedBox(
          width: double.infinity,
          child: _buildText(),
        ),
        SizedBox(
          width: double.infinity,
          child: _buildTextCaret(),
        ),
      ],
    );
  }

  Widget _buildTextSelection() {
    if (_renderParagraph == null) {
      return SizedBox();
    }

    return widget.textSelectionDecoration.build(
      context: context,
      renderParagraph: _renderParagraph!,
      selection: widget.textSelection,
      isTextEmpty: _textLength == 0,
      highlightWhenEmpty: widget.highlightWhenEmpty,
      emptyLineHeight: _lineHeight,
    );
  }

  Widget _buildText() {
    return RichText(
      key: _textKey,
      text: widget.richText,
      textAlign: widget.textAlign,
    );
  }

  Widget _buildTextCaret() {
    if (_renderParagraph == null) {
      return SizedBox();
    }

    return RepaintBoundary(
      child: widget.textCaretFactory.build(
        context: context,
        renderParagraph: _renderParagraph!,
        position: widget.textSelection.extent,
        lineHeight: _lineHeight,
        isTextEmpty: _textLength == 0,
        showCaret: widget.showCaret,
      ),
    );
  }
}

class TextSelectionDecoration {
  const TextSelectionDecoration({
    required this.selectionColor,
  });

  final Color selectionColor;

  Widget build({
    required BuildContext context,
    required RenderParagraph renderParagraph,
    required TextSelection selection,
    required bool isTextEmpty,
    required bool highlightWhenEmpty,
    required double emptyLineHeight,
  }) {
    return CustomPaint(
      painter: _TextSelectionPainter(
        renderParagraph: renderParagraph,
        selection: selection,
        selectionColor: selectionColor,
        isTextEmpty: isTextEmpty,
        highlightWhenEmpty: highlightWhenEmpty,
        emptySelectionHeight: emptyLineHeight,
      ),
    );
  }
}

class _TextSelectionPainter extends CustomPainter {
  _TextSelectionPainter({
    required this.isTextEmpty,
    required this.renderParagraph,
    required this.selection,
    required this.emptySelectionHeight,
    required this.selectionColor,
    this.highlightWhenEmpty = false,
  }) : selectionPaint = Paint()..color = selectionColor;

  final bool isTextEmpty;
  final RenderParagraph renderParagraph;
  final TextSelection selection;
  final emptySelectionHeight;
  // When true, an empty, collapsed selection will be highlighted
  // for the purpose of showing a highlighted empty line.
  final bool highlightWhenEmpty;
  final Color selectionColor;
  final Paint selectionPaint;

  @override
  void paint(Canvas canvas, Size size) {
    if (isTextEmpty && highlightWhenEmpty && selection.isCollapsed && selection.extentOffset == 0) {
      //&& highlightWhenEmpty) {
      // This is an empty paragraph, which is selected. Paint a small selection.
      canvas.drawRect(
        Rect.fromLTWH(0, 0, 5, 20),
        selectionPaint,
      );
    }

    final selectionBoxes = renderParagraph.getBoxesForSelection(selection);

    for (final box in selectionBoxes) {
      final rawRect = box.toRect();
      final rect = Rect.fromLTWH(rawRect.left, rawRect.top - 2, rawRect.width, rawRect.height + 4);

      canvas.drawRect(
        // Note: If the rect has no width then we've selected an empty line. Give
        //       that line a slight width for visibility.
        rect.width > 0 ? rect : Rect.fromLTWH(rect.left, rect.top, 5, rect.height),
        selectionPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_TextSelectionPainter oldDelegate) {
    return renderParagraph != oldDelegate.renderParagraph || selection != oldDelegate.selection;
  }
}

class TextCaretFactory {
  const TextCaretFactory({
    required this.color,
    this.width = 1.0,
    this.borderRadius = BorderRadius.zero,
  });

  final Color color;
  final double width;
  final BorderRadius borderRadius;

  Widget build({
    required BuildContext context,
    required RenderParagraph renderParagraph,
    required TextPosition position,
    required double lineHeight,
    required bool isTextEmpty,
    required bool showCaret,
  }) {
    return _BlinkingCaret(
      renderParagraph: renderParagraph,
      color: color,
      width: width,
      borderRadius: borderRadius,
      textPosition: position,
      lineHeight: lineHeight,
      isTextEmpty: isTextEmpty,
      showCaret: showCaret,
    );
  }
}

class _BlinkingCaret extends StatefulWidget {
  const _BlinkingCaret({
    Key? key,
    required this.renderParagraph,
    required this.color,
    required this.width,
    required this.borderRadius,
    required this.textPosition,
    required this.lineHeight,
    required this.isTextEmpty,
    required this.showCaret,
  }) : super(key: key);

  final RenderParagraph renderParagraph;
  final Color color;
  final double width;
  final BorderRadius borderRadius;
  final TextPosition textPosition;
  final double lineHeight;
  final bool isTextEmpty;
  final bool showCaret;

  @override
  _BlinkingCaretState createState() => _BlinkingCaretState();
}

class _BlinkingCaretState extends State<_BlinkingCaret> with SingleTickerProviderStateMixin {
  // Controls the blinking caret animation.
  late _CaretBlinkController _caretBlinkController;

  @override
  void initState() {
    super.initState();

    _caretBlinkController = _CaretBlinkController(
      tickerProvider: this,
    );
    _caretBlinkController.caretPosition = widget.textPosition;
  }

  @override
  void didUpdateWidget(_BlinkingCaret oldWidget) {
    super.didUpdateWidget(oldWidget);

    _caretBlinkController.caretPosition = widget.textPosition;
  }

  @override
  void dispose() {
    _caretBlinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CursorPainter(
        blinkController: _caretBlinkController,
        paragraph: widget.renderParagraph,
        width: widget.width,
        borderRadius: widget.borderRadius,
        caretTextPosition: widget.textPosition.offset,
        lineHeight: widget.lineHeight,
        caretColor: widget.color,
        isTextEmpty: widget.isTextEmpty,
        showCaret: widget.showCaret,
      ),
    );
  }
}

class _CursorPainter extends CustomPainter {
  _CursorPainter({
    required this.blinkController,
    required this.paragraph,
    required this.width,
    required this.borderRadius,
    required this.caretTextPosition,
    required this.lineHeight,
    required this.caretColor,
    required this.isTextEmpty,
    required this.showCaret,
  })  : caretPaint = Paint()..color = caretColor,
        super(repaint: blinkController);

  final _CaretBlinkController blinkController;
  final RenderParagraph paragraph;
  final int caretTextPosition;
  final double width;
  final BorderRadius borderRadius;
  final double lineHeight; // TODO: this should probably also come from the TextPainter (#46).
  final bool isTextEmpty;
  final bool showCaret;
  final Color caretColor;
  final Paint caretPaint;

  @override
  void paint(Canvas canvas, Size size) {
    if (!showCaret) {
      return;
    }

    if (caretTextPosition < 0) {
      return;
    }

    caretPaint..color = caretColor.withOpacity(blinkController.opacity);

    final caretHeight = paragraph.getFullHeightForCaret(TextPosition(offset: caretTextPosition)) ?? lineHeight;

    Offset caretOffset = isTextEmpty
        ? Offset(0, (lineHeight - caretHeight) / 2)
        : paragraph.getOffsetForCaret(TextPosition(offset: caretTextPosition), Rect.zero);

    if (borderRadius == BorderRadius.zero) {
      canvas.drawRect(
        Rect.fromLTWH(
          caretOffset.dx.roundToDouble(),
          caretOffset.dy.roundToDouble(),
          width,
          caretHeight.roundToDouble(),
        ),
        caretPaint,
      );
    } else {
      canvas.drawRRect(
        RRect.fromLTRBAndCorners(
          caretOffset.dx.roundToDouble(),
          caretOffset.dy.roundToDouble(),
          caretOffset.dx.roundToDouble() + width,
          caretOffset.dy.roundToDouble() + caretHeight.roundToDouble(),
          topLeft: borderRadius.topLeft,
          topRight: borderRadius.topRight,
          bottomLeft: borderRadius.bottomLeft,
          bottomRight: borderRadius.bottomRight,
        ),
        caretPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CursorPainter oldDelegate) {
    return paragraph != oldDelegate.paragraph ||
        caretTextPosition != oldDelegate.caretTextPosition ||
        isTextEmpty != oldDelegate.isTextEmpty ||
        showCaret != oldDelegate.showCaret;
  }
}

class _CaretBlinkController with ChangeNotifier {
  _CaretBlinkController({
    required TickerProvider tickerProvider,
    Duration flashPeriod = const Duration(milliseconds: 500),
  }) : _animationController = AnimationController(
          vsync: tickerProvider,
          duration: flashPeriod,
        ) {
    _animationController
      ..addListener(() {
        notifyListeners();
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animationController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _animationController.forward();
        }
      });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  AnimationController _animationController;
  double get opacity => 1.0 - _animationController.value.roundToDouble();

  TextPosition? _caretPosition;
  set caretPosition(TextPosition? newPosition) {
    if (newPosition != _caretPosition) {
      _caretPosition = newPosition;

      if (newPosition == null || newPosition.offset < 0) {
        _animationController.stop();
      } else {
        _animationController.forward(from: 0.0);
      }
    }
  }
}

/// Wraps a given `SelectableText` and paints extra decoration
/// to visualize text boundaries.
class DebugSelectableTextDecorator extends StatefulWidget {
  const DebugSelectableTextDecorator({
    Key? key,
    required this.selectableTextKey,
    required this.textLength,
    required this.child,
    this.showDebugPaint = false,
  }) : super(key: key);

  final GlobalKey selectableTextKey;
  final int textLength;
  final SelectableText child;
  final bool showDebugPaint;

  @override
  _DebugSelectableTextDecoratorState createState() => _DebugSelectableTextDecoratorState();
}

class _DebugSelectableTextDecoratorState extends State<DebugSelectableTextDecorator> {
  SelectableTextState? get _selectableTextState => widget.selectableTextKey.currentState as SelectableTextState;

  RenderParagraph? get _renderParagraph => _selectableTextState?._renderParagraph;

  List<Rect> _computeTextRectangles(RenderParagraph renderParagraph) {
    return renderParagraph
        .getBoxesForSelection(TextSelection(
          baseOffset: 0,
          extentOffset: widget.textLength,
        ))
        .map((box) => box.toRect())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.showDebugPaint) _buildDebugPaint(),
        widget.child,
      ],
    );
  }

  Widget _buildDebugPaint() {
    if (_selectableTextState == null) {
      // Schedule another frame so we can compute the debug paint.
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
        setState(() {});
      });
      return SizedBox();
    }
    if (_renderParagraph == null) {
      // Schedule another frame so we can compute the debug paint.
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
        setState(() {});
      });
      return SizedBox();
    }
    if (_renderParagraph!.debugNeedsLayout) {
      // Schedule another frame so we can compute the debug paint.
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
        setState(() {});
      });
      return SizedBox();
    }

    return Positioned.fill(
      child: CustomPaint(
        painter: _DebugTextPainter(
          textRectangles: _computeTextRectangles(_renderParagraph!),
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _DebugTextPainter extends CustomPainter {
  _DebugTextPainter({
    required this.textRectangles,
  });

  final List<Rect> textRectangles;
  final Paint leftBoundaryPaint = Paint()..color = const Color(0xFFCCCCCC);
  final Paint textBoxesPaint = Paint()
    ..color = const Color(0xFFCCCCCC)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  @override
  void paint(Canvas canvas, Size size) {
    for (final rect in textRectangles) {
      canvas.drawRect(
        rect,
        textBoxesPaint,
      );
    }

    // Paint left boundary.
    canvas.drawRect(
      Rect.fromLTWH(-6, 0, 2, size.height),
      leftBoundaryPaint,
    );
  }

  @override
  bool shouldRepaint(_DebugTextPainter oldDelegate) {
    return textRectangles != oldDelegate.textRectangles;
  }
}
