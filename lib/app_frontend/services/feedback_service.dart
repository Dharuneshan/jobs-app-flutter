import 'dart:io';
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http_parser/http_parser.dart';
import '../models/feedback.dart';

class FeedbackService {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/employer-feedback/';
    } else if (Platform.isIOS) {
      return 'http://localhost:8000/api/employer-feedback/';
    } else {
      return 'http://localhost:8000/api/employer-feedback/';
    }
  }

  Future<http.Response> submitFeedback({
    required FeedbackModel feedback,
    List<File?> images = const [null, null, null],
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
    request.fields['employer'] = feedback.employerId.toString();
    request.fields['rating'] = feedback.rating.toString();
    if (feedback.experience != null) {
      request.fields['experience'] = feedback.experience!;
    }
    if (feedback.about != null) {
      for (var v in feedback.about!) {
        request.fields.addAll({'about[]': v});
      }
    }
    if (feedback.include != null) {
      for (var v in feedback.include!) {
        request.fields.addAll({'include[]': v});
      }
    }
    if (feedback.email != null) request.fields['email'] = feedback.email!;
    for (int i = 0; i < images.length; i++) {
      if (images[i] != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'image_${i + 1}',
          images[i]!.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }
    }
    var streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }
}
