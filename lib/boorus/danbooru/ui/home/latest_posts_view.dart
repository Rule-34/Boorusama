// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/application/posts.dart';
import 'package:boorusama/boorus/danbooru/application/tags.dart';
import 'package:boorusama/boorus/danbooru/domain/posts.dart';
import 'package:boorusama/boorus/danbooru/domain/tags.dart';
import 'package:boorusama/boorus/danbooru/router.dart';
import 'package:boorusama/boorus/danbooru/ui/posts/danbooru_infinite_post_list2.dart';
import 'package:boorusama/core/application/common.dart';
import 'package:boorusama/core/ui/post_grid_controller.dart';
import 'package:boorusama/core/ui/search_bar.dart';
import 'package:boorusama/core/ui/tags.dart';
import 'most_search_tag_list.dart';

class LatestView extends StatefulWidget {
  const LatestView({
    super.key,
    this.onMenuTap,
    this.useAppBarPadding,
  });

  final VoidCallback? onMenuTap;
  final bool? useAppBarPadding;

  @override
  State<LatestView> createState() => _LatestViewState();
}

class _LatestViewState extends State<LatestView> with DanbooruPostCubitMixin {
  final AutoScrollController _autoScrollController = AutoScrollController();
  final ValueNotifier<String> _selectedTag = ValueNotifier('');
  final BehaviorSubject<String> _selectedTagStream = BehaviorSubject();
  final CompositeSubscription _compositeSubscription = CompositeSubscription();
  late final _postGridController = PostGridController<DanbooruPost>(
      fetcher: (page) => fetchPost(
            page,
            DanbooruPostExtra(
              tag: () => _selectedTag.value,
            ),
          ),
      refresher: () => refreshPost(
            DanbooruPostExtra(
              tag: () => _selectedTag.value,
            ),
          ));

  void _sendRefresh(String tag) {
    _autoScrollController.jumpTo(0);
    _postGridController.refresh();
  }

  @override
  void initState() {
    super.initState();
    _selectedTag.addListener(() => _selectedTagStream.add(_selectedTag.value));

    _selectedTagStream
        .debounceTime(const Duration(milliseconds: 250))
        .distinct()
        .listen((tag) {
      _sendRefresh(tag);
    }).addTo(_compositeSubscription);
  }

  @override
  void dispose() {
    _autoScrollController.dispose();
    _compositeSubscription.dispose();
    _selectedTagStream.close();
    _selectedTag.dispose();
    _postGridController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DanbooruInfinitePostList2(
      controller: _postGridController,
      scrollController: _autoScrollController,
      sliverHeaderBuilder: (context) => [
        _AppBar(
          onMenuTap: widget.onMenuTap,
          primary: widget.useAppBarPadding,
        ),
        SliverToBoxAdapter(
          child: ValueListenableBuilder<String>(
            valueListenable: _selectedTag,
            builder: (context, value, child) => _MostSearchTagSection(
              selected: value,
              onSelected: (search) {
                _selectedTag.value =
                    search.keyword == value ? '' : search.keyword;
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _MostSearchTagSection extends StatelessWidget {
  const _MostSearchTagSection({
    required this.onSelected,
    required this.selected,
  });

  final void Function(Search search) onSelected;
  final String selected;

  @override
  Widget build(BuildContext context) {
    final status =
        context.select((TrendingTagCubit cubit) => cubit.state.status);

    switch (status) {
      case LoadStatus.success:
        return MostSearchTagList(
          onSelected: onSelected,
          selected: selected,
        );
      case LoadStatus.failure:
        return const SizedBox.shrink();
      case LoadStatus.initial:
      case LoadStatus.loading:
        return const TagChipsPlaceholder();
    }
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({
    required this.onMenuTap,
    this.primary,
  });

  final VoidCallback? onMenuTap;
  final bool? primary;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      toolbarHeight: kToolbarHeight * 1.2,
      primary: primary ?? true,
      title: SearchBar(
        enabled: false,
        leading: onMenuTap != null
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => onMenuTap!(),
              )
            : null,
        onTap: () => goToSearchPage(context),
      ),
      floating: true,
      snap: true,
      automaticallyImplyLeading: false,
    );
  }
}
