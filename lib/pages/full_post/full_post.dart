import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lemmy_api_client/v3.dart';
import 'package:provider/provider.dart';

import '../../hooks/logged_in_action.dart';
import '../../util/async_store.dart';
import '../../util/async_store_listener.dart';
import '../../util/extensions/api.dart';
import '../../util/icons.dart';
import '../../util/observer_consumers.dart';
import '../../util/share.dart';
import '../../util/unawaited.dart';
import '../../widgets/comment_section.dart';
import '../../widgets/post/full_post_store.dart';
import '../../widgets/post/post.dart';
import '../../widgets/post/post_more_menu.dart';
import '../../widgets/post/post_store.dart';
import '../../widgets/reveal_after_scroll.dart';
import '../../widgets/write_comment.dart';

class FullPostPage extends StatelessWidget {
  final FullPostStore fullPostStore;

  FullPostPage({required int id, required String instanceHost})
      : fullPostStore = FullPostStore(instanceHost: instanceHost, postId: id);
  FullPostPage.fromPostView(PostView postView)
      : fullPostStore = FullPostStore.fromPostView(postView);
  FullPostPage.fromPostStore(PostStore postStore)
      : fullPostStore = FullPostStore.fromPostStore(postStore);

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (context) => fullPostStore,
      builder: (context, store) => AsyncStoreListener(
        asyncStore: context.read<FullPostStore>().fullPostState,
        child: const _FullPostPage(),
      ),
    );
  }
}

/// Displays a post with its comment section
class _FullPostPage extends HookWidget {
  const _FullPostPage();

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();

    useMemoized(() => context.read<FullPostStore>().refresh(), []);

    final loggedInAction = useLoggedInAction(
        context.select<FullPostStore, String>((store) => store.instanceHost));
    final newComments = useState(const <CommentView>[]);

    return ObserverBuilder<FullPostStore>(
      builder: (context, store) {
        // FALLBACK VIEW
        if (store.postView == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
                child: (store.fullPostState.isLoading)
                    ? const CircularProgressIndicator.adaptive()
                    : Column(
                        children: [
                          const Text('Post failed to load'),
                          ElevatedButton.icon(
                              onPressed: store.refresh,
                              icon: const Icon(Icons.refresh),
                              label: const Text('try again'))
                        ],
                      )),
          );
        }

        // VARIABLES

        final post = store.postView!;

        // FUNCTIONS
        Future<void> refresh() async {
          unawaited(HapticFeedback.mediumImpact());
          await store.refresh();
        }

        sharePost() => share(post.post.apId, context: context);

        comment() async {
          final newComment = await showCupertinoModalPopup<CommentView>(
            context: context,
            builder: (_) => WriteComment.toPost(post.post),
          );
          if (newComment != null) {
            newComments.value = [...newComments.value, newComment];
          }
        }

        return Scaffold(
            appBar: AppBar(
              centerTitle: false,
              title: RevealAfterScroll(
                scrollController: scrollController,
                after: 65,
                child: Text(
                  post.community.originPreferredName,
                  overflow: TextOverflow.fade,
                ),
              ),
              actions: [
                IconButton(icon: const Icon(Icons.share), onPressed: sharePost),
                // const SavePostButton(),
                IconButton(
                  icon: Icon(moreIcon),
                  onPressed: () => showPostMoreMenu(
                    context: context,
                    store: store.postStore!,
                    fullPost: true,
                  ),
                ),
              ],
            ),
            floatingActionButton: post.post.locked
                ? null
                : FloatingActionButton(
                    onPressed: loggedInAction((_) => comment()),
                    child: const Icon(Icons.comment),
                  ),
            body: RefreshIndicator(
              onRefresh: refresh,
              child: ListView(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 15),
                  PostTile.fromPostStore(store.postStore!),
                  const _Comments(),
                ],
              ),
            ));
      },
    );
  }
}

class _Comments extends StatelessWidget {
  const _Comments();

  @override
  Widget build(BuildContext context) {
    return ObserverBuilder<FullPostStore>(
      builder: (context, store) {
        final fullPost = store.fullPostView;
        if (fullPost != null) {
          return CommentSection(store.comments!,
              postCreatorId: fullPost.postView.creator.id);
        } else if (store.fullPostState is AsyncStateError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
            child: Column(
              children: [
                const Icon(Icons.error),
                Text('Error: ${store.fullPostState.errorTerm}')
              ],
            ),
          );
        } else {
          return const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
