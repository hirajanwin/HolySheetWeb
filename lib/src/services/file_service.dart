import 'dart:async';

import 'package:HolySheetWeb/src/services/auth_service.dart';
import 'package:HolySheetWeb/src/file_list/file_list_component.dart';
import 'package:HolySheetWeb/src/request_objects.dart';
import 'package:HolySheetWeb/src/request_utils.dart';
import 'package:angular/core.dart';
import 'package:HolySheetWeb/src/utility.dart';

@Injectable()
class FileService {
  final AuthService authService;
  final RequestService requestService;

  final updates = <void Function()>[];

  final files = <FetchedFile>[];
  final folders = <FetchedFile>[];

  final List<FetchedFile> selected = [];

  FileService(this.authService, this.requestService);

  Future<List<FetchedFile>> fetchFiles(
      [ListType type = ListType.Default, bool update = true]) async {
    if (!authService.checkSignedIn) {
      print('User not logged in');
      return [];
    }

    print('Fetching starred: $type');

    return requestService
        .listFiles(
            path: '',
            starred: type == ListType.Starred,
            trashed: type == ListType.Trash)
        .then((files) {
      if (update) {
        folders.clear();
        this.files.clear();
        files.forEach((file) => (file.folder ? folders : this.files).add(file));
        _triggerUpdate();
      }

      return files;
    });
  }

  Future<void> deleteSelected() async => deleteFiles(selected);

  Future<void> deleteFiles(List<FetchedFile> files) async =>
      requestService.deleteFiles(files).then((_) {
        folders.removeAll(files);
        this.files.removeAll(files);
        selected.removeAll(files);
        _triggerUpdate();
      });

  Future<void> restoreSelected() async => restoreFiles(selected);

  Future<void> restoreFiles(List<FetchedFile> files) async =>
      requestService.restoreFiles(files).then((_) {
        folders.removeAll(files);
        this.files.removeAll(files);
        selected.removeAll(files);
        _triggerUpdate();
      });

  Future<void> starSelected(bool starred) async => starFiles(starred, selected);

  Future<void> starFiles(bool starred, List<FetchedFile> files) async =>
      requestService
          .starFiles(files, starred)
          .then((_) => files.forEach((file) => file.starred = starred));

  void downloadSelected() =>
    downloadFile(selected.start());

  void downloadFile(FetchedFile file) =>
      requestService.downloadFile(file);

  void _triggerUpdate() {
    for (var callback in updates) {
      callback();
    }
  }
}
