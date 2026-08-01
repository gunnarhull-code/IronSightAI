import 'package:ironsight_ai/domain/repositories/auth_session_reader.dart';

class FakeAuthSessionReader implements AuthSessionReader {
  FakeAuthSessionReader({this.currentUserId = 'user-1'});

  @override
  String? currentUserId;
}
