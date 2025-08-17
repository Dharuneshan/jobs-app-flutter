// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'models/feedback.dart';
import 'services/feedback_service.dart';

class FeedbackPage extends StatefulWidget {
  final int employerId;
  const FeedbackPage({Key? key, required this.employerId}) : super(key: key);

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  int _rating = 0;
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final List<String> _aboutOptions = [
    'App Performance',
    'User Interface',
    'Features',
    'Bug Report',
    'Others',
  ];
  final List<String> _includeOptions = [
    'Screenshots',
    'App diagnostics',
    'Contact information',
  ];
  final List<String> _selectedAbout = [];
  final List<String> _selectedInclude = [];
  final List<File> _images = [];
  bool _isSubmitting = false;

  final Color green = const Color(0xFF33CC33);
  final Color blue = const Color(0xFF0044CC);
  final Color lightBlue = const Color(0xFFCFDFFE);
  final Color bgColor = const Color(0xFFF3F7FF);

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 80);
    if (pickedFiles.length + _images.length <= 3) {
      setState(() {
        _images.addAll(pickedFiles.map((e) => File(e.path)));
      });
    } else if (pickedFiles.length + _images.length > 3) {
      // ignore: duplicate_ignore
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can upload up to 3 images.')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please provide a rating before submitting')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final feedback = FeedbackModel(
        employerId: widget.employerId,
        rating: _rating,
        experience: _experienceController.text.isEmpty
            ? null
            : _experienceController.text,
        about: _selectedAbout.isEmpty ? null : _selectedAbout,
        include: _selectedInclude.isEmpty ? null : _selectedInclude,
        email: _emailController.text.isEmpty ? null : _emailController.text,
      );
      final service = FeedbackService();
      final response = await service.submitFeedback(
        feedback: feedback,
        images: List<File?>.generate(
            3, (i) => i < _images.length ? _images[i] : null),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Feedback submitted successfully!')),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to submit feedback: ${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting feedback: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
          5,
          (index) => IconButton(
                icon: Icon(
                  Icons.star,
                  color: _rating > index
                      ? Colors.amber
                      : const Color.fromARGB(255, 167, 167, 167),
                  size: 32,
                ),
                onPressed: () {
                  setState(() {
                    _rating = index + 1;
                  });
                },
              )),
    );
  }

  Widget _buildMultiSelectChips(List<String> options, List<String> selected,
      void Function(String) onTap) {
    return Wrap(
      spacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return ChoiceChip(
          label: Text(option),
          avatarBorder: Border.all(color: Colors.red),
          selected: isSelected,
          selectedColor: blue,
          backgroundColor: lightBlue,
          labelStyle: TextStyle(
              color: isSelected
                  ? Colors.white
                  : const Color.fromARGB(255, 0, 0, 0)),
          onSelected: (_) => onTap(option),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Share Your Feedback',
          style: TextStyle(color: Colors.white), // Text color set to white
        ),
        backgroundColor: blue,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white, // Icon color set to white
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Help us improve your experience',
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            const Text('Overall Experience',
                style: TextStyle(fontWeight: FontWeight.bold)),
            _buildStarRating(),
            const SizedBox(height: 4),
            const Text('Tap to rate',
                style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 16),
            const Text('Tell us about your experience (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _experienceController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'What did you like or what can we improve?',
                filled: true,
                fillColor: Colors.white,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            const Text("What's this about?",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildMultiSelectChips(_aboutOptions, _selectedAbout, (option) {
              setState(() {
                if (_selectedAbout.contains(option)) {
                  _selectedAbout.remove(option);
                } else {
                  _selectedAbout.add(option);
                }
              });
            }),
            const SizedBox(height: 16),
            const Text('Include:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildMultiSelectChips(_includeOptions, _selectedInclude, (option) {
              setState(() {
                if (_selectedInclude.contains(option)) {
                  _selectedInclude.remove(option);
                } else {
                  _selectedInclude.add(option);
                }
              });
            }),
            const SizedBox(height: 16),
            const Text('Add Screenshots (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.camera_alt,
                        size: 32, color: Color(0xFF0044CC)),
                    onPressed: _images.length < 3 ? _pickImages : null,
                  ),
                  const SizedBox(height: 4),
                  Text('Add up to 3 images', style: TextStyle(color: blue)),
                  const SizedBox(height: 8),
                  if (_images.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: List.generate(
                          _images.length,
                          (i) => Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(_images[i],
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover),
                                  ),
                                  GestureDetector(
                                    onTap: () => _removeImage(i),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.close,
                                          color: Colors.red, size: 20),
                                    ),
                                  ),
                                ],
                              )),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Your email (optional)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Enter your email address',
                filled: true,
                fillColor: Colors.white,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed:
                    _isSubmitting || _rating == 0 ? null : _submitFeedback,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Feedback',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
