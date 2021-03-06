// Package imports:
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/domain/accounts/i_account_repository.dart';
import 'package:boorusama/boorus/danbooru/domain/comments/comment_dto.dart';
import 'package:boorusama/boorus/danbooru/domain/comments/i_comment_repository.dart';
import 'package:boorusama/boorus/danbooru/infrastructure/apis/danbooru/danbooru_api.dart';
import 'package:boorusama/boorus/danbooru/infrastructure/apis/i_api.dart';
import 'package:boorusama/boorus/danbooru/infrastructure/repositories/accounts/account_repository.dart';

final commentProvider = Provider<CommentRepository>((ref) =>
    CommentRepository(ref.watch(apiProvider), ref.watch(accountProvider)));

class CommentRepository implements ICommentRepository {
  final IApi _api;
  final IAccountRepository _accountRepository;

  CommentRepository(this._api, this._accountRepository);

  @override
  Future<List<CommentDto>> getCommentsFromPostId(
    int postId, {
    CancelToken cancelToken,
  }) async {
    try {
      final value =
          await _api.getComments(postId, 1000, cancelToken: cancelToken);
      final data = value.response.data;
      var comments = <CommentDto>[];

      for (var item in data) {
        try {
          comments.add(CommentDto.fromJson(item));
        } catch (e) {
          print("Cant parse ${item['id']}");
        }
      }

      return comments;
    } on DioError catch (e) {
      if (e.type == DioErrorType.CANCEL) {
        // Cancel token triggered, skip this request
        return [];
      } else {
        throw Exception("Failed to get comments for $postId");
      }
    }
  }

  @override
  Future<bool> postComment(int postId, String content) async {
    final account = await _accountRepository.get();
    return _api
        .postComment(account.username, account.apiKey, postId, content, true)
        .then((value) {
      print("Add comment to post $postId success");
      return true;
    }).catchError((Object obj) {
      switch (obj.runtimeType) {
        case DioError:
        default:
          print("Failed to add comment to post $postId");
      }
      return false;
    });
  }

  @override
  Future<bool> updateComment(int commentId, String content) async {
    final account = await _accountRepository.get();
    return _api
        .updateComment(account.username, account.apiKey, commentId, content)
        .then((value) {
      print("Update comment $commentId success");
      return true;
    }).catchError((Object obj) {
      switch (obj.runtimeType) {
        case DioError:
        default:
          print("Failed to update comment $commentId");
      }
      return false;
    });
  }
}
