import 'package:boorusama/application/posts/post_list/bloc/post_list_bloc.dart';
import 'package:boorusama/presentation/posts/post_download_gallery/post_download_gallery_page.dart';
import 'package:boorusama/presentation/posts/post_list/post_list_page.dart';
import 'package:boorusama/presentation/posts/bottom_bar_widget.dart';
import 'package:boorusama/presentation/posts/post_list/widgets/post_list_widget.dart';
import 'package:boorusama/presentation/posts/post_list/widgets/post_search_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:widget_view/widget_view.dart';

class PostListPageView
    extends StatefulWidgetView<PostListPage, PostListPageState> {
  PostListPageView(PostListPageState controller, {Key key})
      : super(controller, key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.downloadAllPosts(),
        child: const Icon(Icons.download_rounded),
      ),
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: _getPage(controller.currentTab),
      bottomNavigationBar: BottomBar(
        onTabChanged: (value) => controller.handleTabChanged(value),
      ),
    );
  }

  //TODO: refactor
  Widget _getPage(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return Stack(fit: StackFit.expand, children: [
          buildList(),
          PostListSearchBar(
            controller: controller.searchBarController,
            onSearched: controller.handleSearched,
          ),
        ]);
      case 1:
        return PostDownloadGalleryPage();
    }
  }

  Widget buildList() {
    return BlocConsumer<PostListBloc, PostListState>(
      listener: (context, state) {
        if (state is PostListLoaded) {
          controller.posts.addAll(state.posts);
        }
      },
      builder: (context, state) {
        // if (state is PostListInitial) {
        //   return buildInitial();
        // } else
        if (state is PostListLoading) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (state is PostListLoaded) {
          return buildListWithData();
          // } else if (state is PostListAdditionalLoading) {
          //   return buildBottomLoading();
        } else {
          return Center(child: Text("Nothing's here"));
        }
      },
    );
  }

  Widget buildListWithData() {
    return PostList(
      posts: controller.posts,
      onScrollDirectionChanged: (value) => value == ScrollDirection.forward
          ? controller.searchBarController.show()
          : controller.searchBarController.hide(),
      onMaxItemReached: controller.loadMorePosts,
      scrollThreshold: 0.8,
      scrollController: controller.scrollController,
    );
  }

  Widget buildError() {
    return Center(
      child: Text("OOPS something went wrong"),
    );
  }
}
