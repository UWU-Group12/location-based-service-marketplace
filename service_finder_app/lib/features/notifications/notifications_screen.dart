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
  bool _markedCurrentNotificationsRead = false;
  _NotificationTab _selectedFilter = _NotificationTab.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _providerId = uid;
    _markedCurrentNotificationsRead = false;
    _notifications = uid == null
        ? null
        : _service.watchProviderNotifications(uid);
  }

  Future<void> _markCurrentNotificationsRead(
    List<ProviderNotificationItem> notifications,
  ) async {
    final providerId = _providerId;
    if (_markedCurrentNotificationsRead || providerId == null) return;
    _markedCurrentNotificationsRead = true;
    await _service.markProviderNotificationsRead(providerId, notifications);
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<_NotificationTab>(
                    value: _selectedFilter,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    borderRadius: BorderRadius.circular(18),
                    items: _NotificationTab.values
                        .map(
                          (tab) => DropdownMenuItem<_NotificationTab>(
                            value: tab,
                            child: Row(
                              children: [
                                Icon(tab.emptyIcon, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Text(tab.label),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (tab) {
                      if (tab == null) return;
                      setState(() => _selectedFilter = tab);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
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
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final notifications = snapshot.data!;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _markCurrentNotificationsRead(notifications);
                          });
                          return _NotificationList(
                            notifications: _filter(
                              notifications,
                              _selectedFilter,
                            ),
                            tab: _selectedFilter,
                            onTap: _openNotification,
                          );
                        },
                      ),
              ),
            ],
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
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: item.unread ? AppColors.primary : AppColors.border,
          width: item.unread ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(_icon(item.type), color: color),
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
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (item.unread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
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
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _timeLabel(item.createdAt),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
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
