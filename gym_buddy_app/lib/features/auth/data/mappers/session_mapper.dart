import 'package:gym_buddy_app/features/auth/data/dto/session_dto.dart';
import 'package:gym_buddy_app/features/auth/domain/entities/auth_session_ui_model.dart';

class SessionMapper {
  const SessionMapper();

  List<AuthSessionUiModel> fromDtos(
    List<SessionDto> sessions, {
    required String? currentSessionId,
  }) {
    return sessions
        .map(
          (session) => AuthSessionUiModel(
            id: session.id,
            deviceName: session.deviceName,
            platform: session.platform,
            lastUsedAt: session.lastUsedAt,
            createdAt: session.createdAt,
            isCurrentDevice: session.id == currentSessionId,
          ),
        )
        .toList();
  }
}
