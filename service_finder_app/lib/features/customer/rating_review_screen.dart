import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../services/review_service.dart';

class RatingReviewScreen extends StatefulWidget {
  final String requestId;

  const RatingReviewScreen({super.key, required this.requestId});

  @override
  State<RatingReviewScreen> createState() => _RatingReviewScreenState();
}

class _RatingReviewScreenState extends State<RatingReviewScreen> {
  final ReviewService _reviewService = ReviewService();

  final TextEditingController _commentController = TextEditingController();

  int _selectedRating = 0;
  bool _isSubmitting = false;
  bool _isAlreadyReviewed = false;

  @override
  void initState() {
    super.initState();
    _checkExistingReview();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingReview() async {
    final hasReviewed = await _reviewService.hasReviewed(widget.requestId);

    if (!mounted) return;

    setState(() {
      _isAlreadyReviewed = hasReviewed;
    });
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      _showMessage('Please select a rating first.');
      return;
    }

    final customerId = FirebaseAuth.instance.currentUser?.uid;

    if (customerId == null) {
      _showMessage('You must sign in before leaving a review.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final request = await _reviewService.getRequestById(widget.requestId);

      if (!mounted) return;

      if (request == null) {
        _showMessage('This request could not be found.');
        return;
      }

      if (!request.isFinishedJob) {
        _showMessage('You can only review a completed job.');
        return;
      }

      await _reviewService.submitReview(
        requestId: request.requestId,
        customerId: customerId,
        providerId: request.providerId,
        rating: _selectedRating.toDouble(),
        comment: _commentController.text,
      );

      if (!mounted) return;

      _showMessage('Thanks for your review.');

      Navigator.of(context).pop(true);
    } on FirebaseException catch (error) {
      debugPrint('Review submission error: ${error.code}');
      _showMessage('Unable to submit your review. Please try again.');
    } catch (error) {
      debugPrint('Review submission error: $error');
      _showMessage('Unable to submit your review. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rate this service'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isAlreadyReviewed
            ? _buildAlreadyReviewed(textTheme)
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How did the work go?', style: textTheme.titleLarge),
                    const SizedBox(height: 20),
                    Row(
                      children: List.generate(5, (index) {
                        final starValue = index + 1;

                        return IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedRating = starValue;
                            });
                          },
                          iconSize: 40,
                          color: AppColors.rating,
                          icon: Icon(
                            starValue <= _selectedRating
                                ? Icons.star
                                : Icons.star_border,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _ratingLabel(_selectedRating),
                      style: textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 30),
                    Text('Add a comment', style: textTheme.titleMedium),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _commentController,
                      maxLines: 5,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        hintText: 'Tell others about your experience.',
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: AppColors.primary,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Submit review'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAlreadyReviewed(TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 56,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text('You already reviewed this job', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Each completed job can only be reviewed once.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Very poor';
      case 2:
        return 'Poor';
      case 3:
        return 'Average';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent';
      default:
        return 'Tap a star to rate';
    }
  }
}
