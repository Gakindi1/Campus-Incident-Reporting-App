import 'package:flutter/material.dart';

import '../../models/incident_enums.dart';
import 'app_colors.dart';

extension IncidentStatusStyle on IncidentStatus {
  Color get color => switch (this) {
    IncidentStatus.submitted => AppColors.submitted,
    IncidentStatus.underReview => AppColors.review,
    IncidentStatus.inProgress => AppColors.progress,
    IncidentStatus.resolved => AppColors.resolved,
    IncidentStatus.rejected => AppColors.rejected,
  };

  Color get background => switch (this) {
    IncidentStatus.submitted => AppColors.submittedBg,
    IncidentStatus.underReview => AppColors.reviewBg,
    IncidentStatus.inProgress => AppColors.progressBg,
    IncidentStatus.resolved => AppColors.resolvedBg,
    IncidentStatus.rejected => AppColors.rejectedBg,
  };
}

extension IncidentPriorityStyle on IncidentPriority {
  Color get color => switch (this) {
    IncidentPriority.low => AppColors.resolved,
    IncidentPriority.medium => AppColors.submitted,
    IncidentPriority.high => AppColors.rejected,
  };
}

extension IncidentCategoryStyle on IncidentCategory {
  Color get color => switch (this) {
    IncidentCategory.facilities => const Color(0xFF2F5BEA),
    IncidentCategory.water => const Color(0xFF0EA5E9),
    IncidentCategory.electricity => const Color(0xFFF59E0B),
    IncidentCategory.safety => const Color(0xFFF04438),
    IncidentCategory.sanitation => const Color(0xFF12B76A),
    IncidentCategory.internet => const Color(0xFF8B5CF6),
    IncidentCategory.furniture => const Color(0xFFB45309),
    IncidentCategory.other => AppColors.textSecondary,
  };
}
