// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart' hide LoadStatus;
import 'package:scroll_to_index/scroll_to_index.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/application/explore/explore.dart';
import 'package:boorusama/boorus/danbooru/application/post/post.dart';
import 'package:boorusama/boorus/danbooru/domain/posts/posts.dart';
import 'datetime_selector.dart';
import 'explore_post_grid.dart';
import 'time_scale_toggle_switch.dart';

class _ExploreDetail extends StatefulWidget {
  const _ExploreDetail({
    required this.title,
    required this.builder,
  });

  final Widget title;
  final Widget Function(
    BuildContext context,
    RefreshController refreshController,
    AutoScrollController scrollController,
  ) builder;

  @override
  State<_ExploreDetail> createState() => _ExploreDetailState();
}

class _ExploreDetailState extends State<_ExploreDetail> {
  final RefreshController _refreshController = RefreshController();
  final AutoScrollController _scrollController = AutoScrollController();

  @override
  void dispose() {
    _refreshController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.title,
      ),
      body: BlocConsumer<ExploreDetailBloc, ExploreDetailState>(
        listener: (context, state) {
          _scrollController.jumpTo(0);
          _refreshController.requestRefresh();
        },
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child: widget.builder(
                  context,
                  _refreshController,
                  _scrollController,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

PostFetcher _categoryToFetcher(
  ExploreCategory category,
  DateTime date,
  TimeScale scale,
) {
  if (category == ExploreCategory.curated) {
    return CuratedPostFetcher(date: date, scale: scale);
  } else if (category == ExploreCategory.popular) {
    return PopularPostFetcher(date: date, scale: scale);
  } else if (category == ExploreCategory.hot) {
    return const HotPostFetcher();
  } else {
    return MostViewedPostFetcher(date: date);
  }
}

List<Widget> _categoryToListHeader(
  BuildContext context,
  ExploreCategory category,
  DateTime date,
  TimeScale scale,
) {
  if (category == ExploreCategory.curated ||
      category == ExploreCategory.popular) {
    return [
      DateTimeSelector(
        onDateChanged: (date) => context
            .read<ExploreDetailBloc>()
            .add(ExploreDetailDateChanged(date)),
        date: date,
        scale: scale,
      ),
      TimeScaleToggleSwitch(
        onToggle: (scale) => {
          context
              .read<ExploreDetailBloc>()
              .add(ExploreDetailTimeScaleChanged(scale)),
        },
      ),
      const SizedBox(height: 20),
    ];
  } else if (category == ExploreCategory.hot) {
    return [];
  } else {
    return [
      DateTimeSelector(
        onDateChanged: (date) => context
            .read<ExploreDetailBloc>()
            .add(ExploreDetailDateChanged(date)),
        date: date,
        scale: scale,
      ),
    ];
  }
}

class ExploreDetailPage extends StatelessWidget {
  const ExploreDetailPage({
    super.key,
    required this.title,
    required this.category,
  });

  final Widget title;
  final ExploreCategory category;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExploreDetailBloc, ExploreDetailState>(
      builder: (context, state) {
        return _ExploreDetail(
          title: title,
          builder: (context, refreshController, scrollController) {
            return BlocProvider(
              create: (context) => PostBloc.of(context)
                ..add(
                  PostRefreshed(
                    fetcher:
                        _categoryToFetcher(category, state.date, state.scale),
                  ),
                ),
              child: BlocBuilder<PostBloc, PostState>(
                builder: (context, ppstate) => ExplorePostGrid(
                  headers: _categoryToListHeader(
                    context,
                    category,
                    state.date,
                    state.scale,
                  ),
                  hasMore: ppstate.hasMore,
                  isLoading: ppstate.loading,
                  scrollController: scrollController,
                  controller: refreshController,
                  date: state.date,
                  scale: state.scale,
                  status: ppstate.status,
                  posts: ppstate.posts,
                  onLoadMore: (date, scale) =>
                      context.read<PostBloc>().add(PostFetched(
                            tags: '',
                            fetcher: _categoryToFetcher(category, date, scale),
                          )),
                  onRefresh: (date, scale) => context.read<PostBloc>().add(
                        PostRefreshed(
                          fetcher: _categoryToFetcher(category, date, scale),
                        ),
                      ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
