import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_router.dart';
import '../../models/service_request_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/request_card.dart';
import '../../widgets/request_widgets.dart';

class ProviderJobsScreen extends StatefulWidget {
  const ProviderJobsScreen({super.key});

  @override
  State<ProviderJobsScreen> createState() => _ProviderJobsScreenState();
}

class _ProviderJobsScreenState extends State<ProviderJobsScreen>
    with SingleTickerProviderStateMixin {
  final _service = FirestoreService();
  late final TabController _tabs;
  Stream<List<ServiceRequestModel>>? _requests;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  void _load() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _requests = uid == null ? null : _service.watchProviderRequests(uid);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jobs',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: AppColors.providerCard,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TabBar(
                controller: _tabs,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(30),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Finished'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _requests == null
                  ? const RequestStateView(
                      title: 'Sign in to view jobs',
                      message: 'Please sign in with your provider account.',
                      icon: Icons.person_outline,
                    )
                  : StreamBuilder<List<ServiceRequestModel>>(
                      key: ObjectKey(_requests),
                      stream: _requests,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return RequestStateView(
                            title: 'Unable to load jobs',
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
                        final active = snapshot.data!
                            .where((request) => request.isActiveJob)
                            .toList();
                        final finished =
                            snapshot.data!
                                .where((request) => request.isFinishedJob)
                                .toList()
                              ..sort(
                                (a, b) => b.updatedAt.compareTo(a.updatedAt),
                              );
                        return TabBarView(
                          controller: _tabs,
                          children: [
                            _jobList(active, finished: false),
                            _jobList(finished, finished: true),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _jobList(List<ServiceRequestModel> jobs, {required bool finished}) {
    if (jobs.isEmpty) {
      return RequestStateView(
        title: finished ? 'No finished jobs yet' : 'No active jobs',
        icon: finished ? Icons.task_alt : Icons.work_outline,
      );
    }
    return ListView.builder(
      key: PageStorageKey(finished ? 'finished_jobs' : 'active_jobs'),
      itemCount: jobs.length,
      itemBuilder: (context, index) => RequestCard(
        key: ValueKey(jobs[index].requestId),
        request: jobs[index],
        statusLabel: requestStatusLabel(jobs[index].requestStatus),
        onTap: () =>
            AppRouter.goToProviderJobDetails(context, jobs[index].requestId),
      ),
    );
  }
}
