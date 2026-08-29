import 'package:flutter/material.dart';
import '../../../../core/movie_repository.dart';
import '../../../../theme/everforest_colors.dart';

class MovieReviewEditor extends StatefulWidget {
  const MovieReviewEditor({
    super.key,
    required this.movie,
  });

  final Movie movie;

  static Future<void> show(BuildContext context, Movie movie) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MovieReviewEditor(movie: movie),
    );
  }

  @override
  State<MovieReviewEditor> createState() => _MovieReviewEditorState();
}

class _MovieReviewEditorState extends State<MovieReviewEditor> {
  final TextEditingController _commentController = TextEditingController();
  double _rating = 4.0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.movie.rating > 0) {
      _rating = widget.movie.rating;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _saveReview() async {
    setState(() => _isSaving = true);
    await MovieRepository.instance.saveReview(
      widget.movie.id,
      _rating,
      _commentController.text.trim(),
    );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Review saved for "${widget.movie.title}" (+5 Points)'),
          backgroundColor: EverforestColors.bg1,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: EverforestColors.bg0,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Review: ${widget.movie.title}',
            style: const TextStyle(
              color: EverforestColors.fg,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1.0;
              final isFilled = _rating >= starValue;
              return IconButton(
                icon: Icon(
                  isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                  color: EverforestColors.yellow,
                  size: 38,
                ),
                onPressed: () => setState(() => _rating = starValue),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLines: 3,
            style: const TextStyle(color: EverforestColors.fg),
            decoration: InputDecoration(
              hintText: 'What did you think about this movie?',
              hintStyle: const TextStyle(color: EverforestColors.grey),
              filled: true,
              fillColor: EverforestColors.bg1,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: EverforestColors.green,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _isSaving ? null : _saveReview,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: EverforestColors.bg0,
                    ),
                  )
                : const Text(
                    'Save Review (+5 Points)',
                    style: TextStyle(
                      color: EverforestColors.bg0,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
