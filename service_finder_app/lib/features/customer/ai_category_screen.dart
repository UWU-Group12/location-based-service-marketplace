
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/app_router.dart';
import '../../models/category_suggestion_model.dart';
import '../../services/ai_service.dart';

class AiCategoryScreen extends StatefulWidget {
  const AiCategoryScreen({super.key});

  @override
  State<AiCategoryScreen> createState() => _AiCategoryScreenState();
}

class _AiCategoryScreenState extends State<AiCategoryScreen> {
  final TextEditingController _problemController = TextEditingController();

  final int _maxCharacters = 500;

  final AIService _aiService = AIService();

  CategorySuggestion? _categorySuggestion;

  bool _isLoading = false;

  Future<void> _requestSuggestion() async {
    if (_isLoading || _problemController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    final result = await _aiService.suggestCategory(_problemController.text);
    if (!mounted) return;

    setState(() {
      _categorySuggestion = result;
      _isLoading = false;
    });
  }

  void _openSuggestedCategory() {
    final suggestion = _categorySuggestion;
    if (suggestion == null) return;

    final categoryId = suggestion.categoryId;
    if (categoryId == null || categoryId.isEmpty) {
      AppRouter.goToServiceCategoryScreen(context);
      return;
    }

    AppRouter.goToProviderListScreen(
      context,
      categoryId: categoryId,
      categoryName: suggestion.category,
    );
  }

  @override
  void dispose() {
    _problemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final suggestion = _categorySuggestion;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _AiHeroPainter())),
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: _BackButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Describe your problem',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.8,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tell us what is wrong and we will help you find the right service.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.64),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 34),
                _GlassCard(
                  borderRadius: 24,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      TextField(
                        controller: _problemController,
                        maxLines: 7,
                        maxLength: _maxCharacters,
                        keyboardType: TextInputType.multiline,
                        onChanged: (value) => setState(() {}),
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 15,
                          height: 1.45,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type your problem here...',
                          hintStyle: textTheme.bodyMedium?.copyWith(
                            color: const Color(
                              0xFF5F6D7E,
                            ).withValues(alpha: 0.68),
                            fontSize: 14,
                          ),
                          contentPadding: const EdgeInsets.fromLTRB(
                            20,
                            18,
                            20,
                            10,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          counterText: '',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 2, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_problemController.text.length}/$_maxCharacters',
                                style: textTheme.bodySmall?.copyWith(
                                  color: const Color(
                                    0xFF475569,
                                  ).withValues(alpha: 0.72),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            _AskAiButton(
                              isLoading: _isLoading,
                              onPressed: _isLoading ? null : _requestSuggestion,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (suggestion != null) ...[
                  const SizedBox(height: 28),
                  _sectionTitle('AI suggestion'),
                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: Color(0xFF0F172A),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                suggestion.category,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          suggestion.reason,
                          style: textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF334155),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _openSuggestedCategory,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F172A),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.42,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: const StadiumBorder(),
                            ),
                            icon: Icon(
                              suggestion.categoryId == null
                                  ? Icons.grid_view_outlined
                                  : Icons.people_outline,
                            ),
                            label: Text(
                              suggestion.categoryId == null
                                  ? 'Browse Service Categories'
                                  : 'View Available Providers',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(left: 6, bottom: 10),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.74),
      ),
    ),
  );
}

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.white.withValues(alpha: 0.12),
          shape: CircleBorder(
            side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            tooltip: 'Back',
          ),
        ),
      ),
    );
  }
}

class _AskAiButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _AskAiButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.black,
        disabledBackgroundColor: Colors.black.withValues(alpha: 0.72),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.auto_awesome, size: 17),
      label: Text(isLoading ? 'Thinking...' : 'Ask AI'),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 22,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.58)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B56F4).withValues(alpha: 0.12),
                blurRadius: 36,
                offset: const Offset(0, 22),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _AiHeroPainter extends CustomPainter {
  const _AiHeroPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFF010101),
            Color(0xFF02040C),
            Color(0xFF0D48C8),
            Color(0xFF68BFFF),
            Color(0xFFEAFBFF),
          ],
          stops: const [0, 0.28, 0.58, 0.78, 1],
        ).createShader(rect),
    );

    _drawGlow(
      canvas,
      size,
      Offset(size.width * 0.86, size.height * 0.42),
      size.width * 0.74,
      const Color(0xFF1D6CFF),
      0.5,
    );
    _drawGlow(
      canvas,
      size,
      Offset(size.width * 0.16, size.height * 0.56),
      size.width * 0.56,
      const Color(0xFF254CFF),
      0.42,
    );
    _drawGlow(
      canvas,
      size,
      Offset(size.width * 0.5, size.height * 0.98),
      size.width * 0.92,
      Colors.white,
      0.88,
    );

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    const step = 58.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

  }

  void _drawGlow(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
    Color color,
    double opacity,
  ) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(covariant _AiHeroPainter oldDelegate) => false;
}
