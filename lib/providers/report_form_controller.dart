import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/incident.dart';
import '../models/incident_enums.dart';

class ReportFormController extends ChangeNotifier {
  ReportFormController({this.initial, ImagePicker? picker})
    : _picker = picker ?? ImagePicker(),
      _category = initial?.category,
      _priority = initial?.priority ?? IncidentPriority.medium,
      _location = initial?.location,
      _isAnonymous = initial?.isAnonymous ?? false,
      _existingImageUrl = initial?.imageUrl;

  final Incident? initial;
  final ImagePicker _picker;

  IncidentCategory? _category;
  IncidentPriority _priority;
  String? _location;
  bool _isAnonymous;
  File? _photo;
  String? _existingImageUrl;
  bool _removedExistingPhoto = false;
  bool _isSubmitting = false;
  bool _showCategoryError = false;

  bool get isEditing => initial != null;
  IncidentCategory? get category => _category;
  IncidentPriority get priority => _priority;
  String? get location => _location;
  bool get isAnonymous => _isAnonymous;
  File? get photo => _photo;
  String? get existingImageUrl => _existingImageUrl;
  bool get removedExistingPhoto => _removedExistingPhoto;
  bool get isSubmitting => _isSubmitting;
  bool get showCategoryError => _showCategoryError;
  bool get hasPhoto => _photo != null || _existingImageUrl != null;

  void selectCategory(IncidentCategory category) {
    _category = category;
    _showCategoryError = false;
    notifyListeners();
  }

  void selectPriority(IncidentPriority priority) {
    _priority = priority;
    notifyListeners();
  }

  void selectLocation(String? location) {
    _location = location;
    notifyListeners();
  }

  void setAnonymous(bool value) {
    _isAnonymous = value;
    notifyListeners();
  }

  Future<void> pickPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 75,
    );
    if (picked == null) return;
    _photo = File(picked.path);
    notifyListeners();
  }

  void removePhoto() {
    if (_photo != null) {
      _photo = null;
    } else if (_existingImageUrl != null) {
      _existingImageUrl = null;
      _removedExistingPhoto = true;
    }
    notifyListeners();
  }

  bool validateSelections() {
    _showCategoryError = _category == null;
    notifyListeners();
    return !_showCategoryError;
  }

  void setSubmitting(bool value) {
    _isSubmitting = value;
    notifyListeners();
  }
}
