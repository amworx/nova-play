import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../state/providers.dart';

/// Simple functional queue: now playing + up next, reorder/remove/clear.
class QueueSheet extends ConsumerWidget {
  const QueueSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Text('Queue',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                ),
                const Spacer(),
                TextButton(
                  onPressed: player.queue.isEmpty
                      ? null
                      : () => player.clearQueue(keepCurrent: true),
                  child: const Text('Clear'),
                ),
              ],
            ),
            if (player.queue.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Queue is empty.\nAdd videos from any list.',
                    textAlign: TextAlign.center),
              )
            else
              Flexible(
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  itemCount: player.queue.length,
                  onReorder: (o, n) =>
                      player.reorderQueue(o, n),
                  itemBuilder: (_, i) {
                    final v = player.queue[i];
                    final isCur =
                        player.current?.id == v.id;
                    return ListTile(
                      key: ValueKey('q_${v.id}_$i'),
                      leading: isCur
                          ? const HugeIcon(
                              icon: HugeIcons
                                  .strokeRoundedAudioWave01,
                              color: Color(0xFFFF5A36))
                          : Text('${i + 1}',
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5))),
                      title: Text(v.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: isCur
                                  ? FontWeight.w700
                                  : FontWeight.w500)),
                      subtitle: isCur
                          ? const Text('Now playing')
                          : null,
                      trailing: IconButton(
                        tooltip: 'Remove',
                        icon: const HugeIcon(
                            icon:
                                HugeIcons.strokeRoundedCancel01,
                            size: 20),
                        onPressed: () =>
                            player.removeFromQueue(i),
                      ),
                      onTap: () {
                        player.open(v,
                            contextQueue: player.queue);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
