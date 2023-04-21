// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/application/posts.dart';
import 'package:boorusama/boorus/danbooru/ui/posts.dart';

class ParentChildPostPage extends StatelessWidget
    with DanbooruPostCubitStatelessMixin {
  const ParentChildPostPage({
    super.key,
    required this.parentPostId,
  });

  final int parentPostId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DanbooruPostCubit, DanbooruPostState>(
      builder: (context, state) {
        return DanbooruInfinitePostList(
          refreshing: state.refreshing,
          loading: state.loading,
          hasMore: state.hasMore,
          error: state.error,
          data: state.data,
          onLoadMore: () => fetch(context),
          sliverHeaderBuilder: (context) => [
            SliverAppBar(
              title: Text(
                '${'post.parent_child.children_of'.tr()} $parentPostId',
              ),
              floating: true,
              elevation: 0,
              shadowColor: Colors.transparent,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
          ],
        );
      },
    );
  }
}
