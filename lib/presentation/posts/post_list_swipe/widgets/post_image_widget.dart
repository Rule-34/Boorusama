import 'dart:ui';

import 'package:boorusama/application/posts/post_translate_note/bloc/post_translate_note_bloc.dart';
import 'package:boorusama/domain/posts/note.dart';
import 'package:boorusama/domain/posts/post.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:super_tooltip/super_tooltip.dart';

class PostImage extends StatefulWidget {
  PostImage({@required this.post, this.onTapped});

  final VoidCallback onTapped;
  final Post post;

  @override
  _PostImageState createState() => _PostImageState();
}

class _PostImageState extends State<PostImage> {
  bool _notesVisible = false;
  List<Note> notes;
  PostTranslateNoteBloc _postTranslateNoteBloc;
  double screenWidth;
  double screenHeight;
  double screenAspectRatio;

  @override
  void initState() {
    super.initState();
    _postTranslateNoteBloc = BlocProvider.of<PostTranslateNoteBloc>(context);
    notes = List<Note>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<PostTranslateNoteBloc, PostTranslateNoteState>(
          listener: (context, state) {
            if (state is PostTranslateNoteFetched) {
              setState(() {
                notes = state.notes;
              });
            } else if (state is PostTranslateNoteInProgress) {
              Scaffold.of(context).showSnackBar(SnackBar(
                  duration: Duration(milliseconds: 1000),
                  content:
                      Text("Fetching translation notes, plese hold on...")));
            } else {
              Scaffold.of(context).showSnackBar(
                  SnackBar(content: Text("Oopsie something went wrong")));
            }
          },
          child: GestureDetector(
            child: _notesVisible
                ? buildNotesAndImage()
                : buildCachedNetworkImage(context),
            onTap: _handleTap,
          )),
    );
  }

  Widget buildCachedNetworkImage(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: widget.post.normalImageUri.toString(),
      imageBuilder: (context, imageProvider) =>
          PhotoView(imageProvider: imageProvider),
      progressIndicatorBuilder: (context, url, progress) => Center(
        child: CircularProgressIndicator(
          value: progress.progress,
        ),
      ),
      errorWidget: (context, url, error) => Icon(Icons.error),
    );
  }

  Widget buildNotesAndImage() {
    final widgets = List<Widget>();

    screenWidth ??= MediaQuery.of(context).size.width;
    screenHeight ??= MediaQuery.of(context).size.height;
    screenAspectRatio ??= MediaQuery.of(context).size.aspectRatio;

    widgets.add(CachedNetworkImage(
      imageUrl: widget.post.normalImageUri.toString(),
      imageBuilder: (context, imageProvider) =>
          PhotoView(imageProvider: imageProvider),
      progressIndicatorBuilder: (context, url, progress) => Center(
        child: CircularProgressIndicator(
          value: progress.progress,
        ),
      ),
      errorWidget: (context, url, error) => Icon(Icons.error),
    ));

    for (var note in notes) {
      final coordinate = note.coordinate.calibrate(
          screenHeight,
          screenWidth,
          screenAspectRatio,
          widget.post.height,
          widget.post.width,
          widget.post.aspectRatio);

      var tooltip = SuperTooltip(
          arrowTipDistance: 0,
          arrowBaseWidth: 0,
          arrowLength: 0,
          popupDirection: TooltipDirection.left,
          content: Material(child: Html(data: note.content)));

      widgets.add(
        GestureDetector(
          onTap: () => tooltip.show(context),
          child: Container(
            margin: EdgeInsets.only(left: coordinate.x, top: coordinate.y),
            width: coordinate.width,
            height: coordinate.height,
            decoration: BoxDecoration(
                color: Colors.white54,
                border: Border.all(color: Colors.red, width: 1)),
          ),
        ),
      );
    }

    return Stack(children: widgets);
  }

  void _handleTap() {
    if (notes.isEmpty) {
      _postTranslateNoteBloc.add(GetTranslatedNotes(postId: widget.post.id));
    }

    setState(() {
      _notesVisible = !_notesVisible;
    });

    widget.onTapped();
  }
}
