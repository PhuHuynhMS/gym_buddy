import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';

class CookieStoreFactory {
  const CookieStoreFactory();

  Future<PersistCookieJar> create() async {
    final directory = await getApplicationSupportDirectory();
    return PersistCookieJar(storage: FileStorage('${directory.path}/.cookies'));
  }
}
