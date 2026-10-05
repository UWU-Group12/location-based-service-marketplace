import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_router.dart';
import '../../services/notification_service.dart';
import '../../widgets/request_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService();
  Stream<List<ProviderNotificationItem>>? _notifications;
  String? _providerId;
  _NotificationTab _selectedFilter = _NotificationTab.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _providerId = uid;
    _notifications = uid == null
        ? null
        : _service.watchProviderNotifications(uid);
  }

  Future<void> _markAllAsRead(
    List<ProviderNotificationItem> notifications,
  ) async {
    final providerId = _providerId;
    if (providerId == null || notifications.every((item) => !item.unread)) {
      return;
    }
    await _service.markProviderNotificationsRead(providerId, notifications);
    if (!mounted) return;
    setState(_load);
  }

  Future<void> _openNotification(ProviderNotificationItem item) async {
    switch (item.type) {
      case ProviderNotificationType.receivedRequest:
      case ProviderNotificationType.sentRequest:
        if (item.requestId != null) {
          await AppRouter.goToProviderRequestDetails(
            context,
            requestId: item.requestId!,
            quotationId: item.quotationId,
          );
        }
        return;
      case ProviderNotificationType.activeJob:
      case ProviderNotificationType.finishedJob:
        if (item.requestId != null && item.requestId!.isNotEmpty) {
          await AppRouter.goToProviderJobDetails(context, item.requestId!);
        } else {
          _showSystemMessage(item);
        }
        return;
      case ProviderNotificationType.rating:
        await AppRouter.goToProviderProfileReviews(context);
        return;
      case ProviderNotificationType.system:
        if (item.requestId != null && item.requestId!.isNotEmpty) {
          await AppRouter.goToProviderRequestDetails(
            context,
            requestId: item.requestId!,
          );
        } else {
          _showSystemMessage(item);
        }
        return;
    }
  }

  void _showSystemMessage(ProviderNotificationItem item) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: Text(item.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(centerTitle: true, title: const Text('Notifications')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: _notifications == null
              ? const RequestStateView(
                  title: 'Sign in to view notifications',
                  message: 'Please sign in with your provider account.',
                  icon: Icons.person_outline,
                )
              : StreamBuilder<List<ProviderNotificationItem>>(
                  key: ObjectKey(_notifications),
                  stream: _notifications,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return RequestStateView(
                        title: 'Unable to load notifications',
                        message: 'Check your connection and try again.',
                        icon: Icons.error_outline,
                        onRetry: () => setState(_load),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final notifications = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _NotificationToolbar(
                          selectedFilter: _selectedFilter,
                          onFilterSelected: (tab) =>
                              setState(() => _selectedFilter = tab),
                          notifications: notifications,
                          onMarkAllAsRead: _markAllAsRead,
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: _NotificationList(
                            notifications: _filter(
                              notifications,
                              _selectedFilter,
                            ),
                            tab: _selectedFilter,
                            onTap: _openNotification,
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }

  List<ProviderNotificationItem> _filter(
    List<ProviderNotificationItem> notifications,
    _NotificationTab tab,
  ) {
    if (tab == _NotificationTab.all) return notifications;
    return notifications.where((item) => item.type == tab.type).toList();
  }
}

enum _NotificationTab {
  all(
    null,
    'All notifications',
    'No notifications yet',
    Icons.notifications_none,
  ),
  received(
    ProviderNotificationType.receivedRequest,
    'Received requests',
    'No received request notifications',
    Icons.inbox_outlined,
  ),
  sent(
    ProviderNotificationType.sentRequest,
    'Sent requests',
    'No sent request notifications',
    Icons.send_outlined,
  ),
  active(
    ProviderNotificationType.activeJob,
    'Active jobs',
    'No active job notifications',
    Icons.work_outline,
  ),
  finished(
    ProviderNotificationType.finishedJob,
    'Finished jobs',
    'No finished job notifications',
    Icons.task_alt,
  ),
  ratings(
    ProviderNotificationType.rating,
    'Ratings',
    'No rating notifications',
    Icons.star_border,
  ),
  system(
    ProviderNotificationType.system,
    'System',
    'No system notifications',
    Icons.campaign_outlined,
  );

  final ProviderNotificationType? type;
  final String label;
  final String emptyTitle;
  final IconData emptyIcon;

  const _NotificationTab(
    this.type,
    this.label,
    this.emptyTitle,
    this.emptyIcon,
  );
}

class _NotificationToolbar extends StatelessWidget {
  final _NotificationTab selectedFilter;
  final ValueChanged<_NotificationTab> onFilterSelected;
  final List<ProviderNotificationItem> notifications;
  final ValueChanged<List<ProviderNotificationItem>> onMarkAllAsRead;

  const _NotificationToolbar({
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.notifications,
    required this.onMarkAllAsRead,
  });

  @override
  Widget build(BuildContext context) {
    final buttonLabel = selectedFilter == _NotificationTab.all
        ? 'Filters'
        : selectedFilter.label;

    return Row(
      children: [
        Flexible(
          child: PopupMenuButton<_NotificationTab>(
            tooltip: 'Filters',
            position: PopupMenuPosition.under,
            offset: const Offset(0, 8),
            elevation: 8,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: AppColors.border),
            ),
            onSelected: onFilterSelected,
            itemBuilder: (context) => _NotificationTab.values
                .map(
                  (tab) => PopupMenuItem<_NotificationTab>(
                    value: tab,
                    child: Row(
                      children: [
                        Icon(tab.emptyIcon, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(tab.label)),
                        if (tab == selectedFilter)
                          const Icon(Icons.check, size: 18),
                      ],
                    ),
                  ),
                )
                .toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.providerCard,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _FilterGlyph(),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      buttonLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _MarkAllAsReadButton(
          notifications: notifications,
          onPressed: onMarkAllAsRead,
        ),
      ],
    );
  }
}

class _FilterGlyph extends StatelessWidget {
  const _FilterGlyph();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 23,
      height: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          _FilterGlyphLine(width: 23),
          _FilterGlyphLine(width: 16),
          _FilterGlyphLine(width: 9),
        ],
      ),
    );
  }
}

class _FilterGlyphLine extends StatelessWidget {
  final double width;

  const _FilterGlyphLine({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 2.4,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _MarkAllAsReadButton extends StatelessWidget {
  final List<ProviderNotificationItem> notifications;
  final ValueChanged<List<ProviderNotificationItem>> onPressed;

  const _MarkAllAsReadButton({
    required this.notifications,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = notifications.any((item) => item.unread);
    return TextButton(
      onPressed: hasUnread ? () => onPressed(notifications) : null,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      child: const Text('Mark all as read'),
    );
  }
}

class _NotificationList extends StatelessWidget {
  final List<ProviderNotificationItem> notifications;
  final _NotificationTab tab;
  final ValueChanged<ProviderNotificationItem> onTap;

  const _NotificationList({
    required this.notifications,
    required this.tab,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return RequestStateView(title: tab.emptyTitle, icon: tab.emptyIcon);
    }
    return ListView.separated(
      padding: const EdgeInsets.only(top: 2, bottom: 24),
      itemCount: notifications.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _NotificationCard(
        item: notifications[index],
        onTap: () => onTap(notifications[index]),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final ProviderNotificationItem item;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _color(item.type);
    final unread = item.unread;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: unread ? const Color(0xFFF6F7F9) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.045)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              if (unread)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: Container(color: color.withValues(alpha: 0.86)),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: color.withValues(alpha: 0.12),
                      child: Icon(_icon(item.type), color: color, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: unread
                                            ? FontWeight.w800
                                            : null,
                                      ),
                                ),
                              ),
                              if (unread)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: _NotificationBadge(
                              icon: Icons.schedule_outlined,
                              label: _timeLabel(item.createdAt),
                              foreground: AppColors.textSecondary,
                              background: Colors.white,
                              outlined: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _icon(ProviderNotificationType type) => switch (type) {
    ProviderNotificationType.receivedRequest => Icons.inbox_outlined,
    ProviderNotificationType.sentRequest => Icons.send_outlined,
    ProviderNotificationType.activeJob => Icons.work_outline,
    ProviderNotificationType.finishedJob => Icons.task_alt,
    ProviderNotificationType.rating => Icons.star,
    ProviderNotificationType.system => Icons.campaign_outlined,
  };

  Color _color(ProviderNotificationType type) => switch (type) {
    ProviderNotificationType.receivedRequest => AppColors.primary,
    ProviderNotificationType.sentRequest => AppColors.info,
    ProviderNotificationType.activeJob => AppColors.warning,
    ProviderNotificationType.finishedJob => AppColors.success,
    ProviderNotificationType.rating => AppColors.rating,
    ProviderNotificationType.system => AppColors.primary,
  };

  String _timeLabel(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} min ago';
    if (difference.inDays < 1) return '${difference.inHours} hr ago';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _NotificationBadge extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color foreground;
  final Color background;
  final bool outlined;

  const _NotificationBadge({
    this.icon,
    required this.label,
    required this.foreground,
    required this.background,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
        border: outlined
            ? Border.all(color: Colors.black.withValues(alpha: 0.06))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: foreground,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
