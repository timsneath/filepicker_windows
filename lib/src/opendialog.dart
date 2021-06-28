import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'filedialog.dart';
import 'place.dart';

class OpenFilePicker extends FileDialog {
  /// Indicates to the Open dialog box that the preview pane should always be
  /// displayed.
  bool? forcePreviewPaneOn;

  OpenFilePicker() : super() {
    fileMustExist = true;
  }

  /// Returns a `File` object from the selected file path.
  File? getFile() {
    var didUserCancel = false;
    late String filePath;

    var hr = CoInitializeEx(
        nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
    if (FAILED(hr)) throw WindowsException(hr);

    final fileDialog = FileOpenDialog.createInstance();

    final pfos = calloc<Uint32>();
    hr = fileDialog.GetOptions(pfos);
    if (FAILED(hr)) throw WindowsException(hr);

    var options = pfos.value;
    if (hidePinnedPlaces) {
      options |= FILEOPENDIALOGOPTIONS.FOS_HIDEPINNEDPLACES;
    }
    if (forcePreviewPaneOn ?? false) {
      options |= FILEOPENDIALOGOPTIONS.FOS_FORCEPREVIEWPANEON;
    }
    if (forceFileSystemItems) {
      options |= FILEOPENDIALOGOPTIONS.FOS_FORCEFILESYSTEM;
    }
    if (fileMustExist) {
      options |= FILEOPENDIALOGOPTIONS.FOS_FILEMUSTEXIST;
    }
    if (isDirectoryFixed) {
      options |= FILEOPENDIALOGOPTIONS.FOS_NOCHANGEDIR;
    }
    hr = fileDialog.SetOptions(options);
    if (FAILED(hr)) throw WindowsException(hr);

    if (defaultExtension != null && defaultExtension!.isNotEmpty) {
      hr = fileDialog.SetDefaultExtension(TEXT(defaultExtension!));
      if (FAILED(hr)) throw WindowsException(hr);
    }

    if (fileName.isNotEmpty) {
      hr = fileDialog.SetFileName(TEXT(fileName));
      if (FAILED(hr)) throw WindowsException(hr);
    }

    if (fileNameLabel.isNotEmpty) {
      hr = fileDialog.SetFileNameLabel(TEXT(fileNameLabel));
      if (FAILED(hr)) throw WindowsException(hr);
    }

    if (title.isNotEmpty) {
      hr = fileDialog.SetTitle(TEXT(title));
      if (FAILED(hr)) throw WindowsException(hr);
    }

    if (filterSpecification.isNotEmpty) {
      final rgSpec = calloc<COMDLG_FILTERSPEC>(filterSpecification.length);

      var index = 0;
      for (final key in filterSpecification.keys) {
        rgSpec[index]
          ..pszName = TEXT(key)
          ..pszSpec = TEXT(filterSpecification[key]!);
        index++;
      }
      hr = fileDialog.SetFileTypes(filterSpecification.length, rgSpec);
      if (FAILED(hr)) throw WindowsException(hr);
    }

    if (defaultFilterIndex != null) {
      if (defaultFilterIndex! > 0 &&
          defaultFilterIndex! < filterSpecification.length) {
        // SetFileTypeIndex is one-based, not zero-based
        hr = fileDialog.SetFileTypeIndex(defaultFilterIndex! + 1);
        if (FAILED(hr)) throw WindowsException(hr);
      }
    }

    for (final place in customPlaces) {
      final shellItem =
          Pointer.fromAddress(place.item.ptr.cast<IntPtr>().value);
      if (place.place == Place.bottom) {
        hr = fileDialog.AddPlace(shellItem.cast(), FDAP.FDAP_BOTTOM);
      } else {
        hr = fileDialog.AddPlace(shellItem.cast(), FDAP.FDAP_TOP);
      }
      if (FAILED(hr)) throw WindowsException(hr);
    }

    hr = fileDialog.Show(NULL);
    if (FAILED(hr)) {
      if (hr == HRESULT_FROM_WIN32(ERROR_CANCELLED)) {
        didUserCancel = true;
      } else {
        throw WindowsException(hr);
      }
    } else {
      final ppsi = calloc<Pointer>();
      hr = fileDialog.GetResult(ppsi);
      if (FAILED(hr)) throw WindowsException(hr);

      final item = IShellItem(ppsi.cast());
      final pathPtrPtr = calloc<Pointer<Utf16>>();
      hr = item.GetDisplayName(SIGDN.SIGDN_FILESYSPATH, pathPtrPtr);
      if (FAILED(hr)) throw WindowsException(hr);

      filePath = pathPtrPtr.value.toDartString();

      hr = item.Release();
      if (FAILED(hr)) throw WindowsException(hr);
    }

    hr = fileDialog.Release();
    if (FAILED(hr)) throw WindowsException(hr);

    CoUninitialize();
    if (didUserCancel) {
      return null;
    } else {
      return File(filePath);
    }
  }

  List<File>? getFiles() {
    var didUserCancel = false;
    late String filePath;
    final List<String> filePaths = [];

    ///
    ///Allow MultiSelect Files
    ///
    isMultiSelect = true;
    var hr = CoInitializeEx(
        nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
    if (FAILED(hr)) throw WindowsException(hr);

    final fileDialog = FileOpenDialog.createInstance();

    final pfos = calloc<Uint32>();
    hr = fileDialog.GetOptions(pfos);
    if (FAILED(hr)) throw WindowsException(hr);

    var options = pfos.value;
    if (hidePinnedPlaces) {
      options |= FILEOPENDIALOGOPTIONS.FOS_HIDEPINNEDPLACES;
    }
    if (forceFileSystemItems) {
      options |= FILEOPENDIALOGOPTIONS.FOS_FORCEFILESYSTEM;
    }
    if (fileMustExist) {
      options |= FILEOPENDIALOGOPTIONS.FOS_FILEMUSTEXIST;
    }
    if (isDirectoryFixed) {
      options |= FILEOPENDIALOGOPTIONS.FOS_NOCHANGEDIR;
    }
    if (isMultiSelect) {
      options |= FILEOPENDIALOGOPTIONS.FOS_ALLOWMULTISELECT;
    }

    hr = fileDialog.SetOptions(options);
    if (FAILED(hr)) throw WindowsException(hr);

    if (defaultExtension != null && defaultExtension!.isNotEmpty) {
      hr = fileDialog.SetDefaultExtension(TEXT(defaultExtension!));
      if (FAILED(hr)) throw WindowsException(hr);
    }

    if (fileName.isNotEmpty) {
      hr = fileDialog.SetFileName(TEXT(fileName));
      if (FAILED(hr)) throw WindowsException(hr);
    }

    if (fileNameLabel.isNotEmpty) {
      hr = fileDialog.SetFileNameLabel(TEXT(fileNameLabel));
      if (FAILED(hr)) throw WindowsException(hr);
    }

    if (title.isNotEmpty) {
      hr = fileDialog.SetTitle(TEXT(title));
      if (FAILED(hr)) throw WindowsException(hr);
    }

    if (filterSpecification.isNotEmpty) {
      final rgSpec = calloc<COMDLG_FILTERSPEC>(filterSpecification.length);

      var index = 0;
      for (final key in filterSpecification.keys) {
        rgSpec[index]
          ..pszName = TEXT(key)
          ..pszSpec = TEXT(filterSpecification[key]!);
        index++;
      }
      hr = fileDialog.SetFileTypes(filterSpecification.length, rgSpec);
      if (FAILED(hr)) throw WindowsException(hr);
    }

    if (defaultFilterIndex != null) {
      if (defaultFilterIndex! > 0 &&
          defaultFilterIndex! < filterSpecification.length) {
        // SetFileTypeIndex is one-based, not zero-based
        hr = fileDialog.SetFileTypeIndex(defaultFilterIndex! + 1);
        if (FAILED(hr)) throw WindowsException(hr);
      }
    }

    for (final place in customPlaces) {
      final shellItem =
          Pointer.fromAddress(place.item.ptr.cast<IntPtr>().value);
      if (place.place == Place.bottom) {
        hr = fileDialog.AddPlace(shellItem.cast(), FDAP.FDAP_BOTTOM);
      } else {
        hr = fileDialog.AddPlace(shellItem.cast(), FDAP.FDAP_TOP);
      }
      if (FAILED(hr)) throw WindowsException(hr);
    }

    hr = fileDialog.Show(NULL);
    if (FAILED(hr)) {
      if (hr == HRESULT_FROM_WIN32(ERROR_CANCELLED)) {
        didUserCancel = true;
      } else {
        throw WindowsException(hr);
      }
    } else {
      final ppsi = calloc<Pointer>();
      hr = fileDialog.GetResults(ppsi);
      if (FAILED(hr)) throw WindowsException(hr);

      if (isMultiSelect) {
        final itemArray = IShellItemArray(ppsi.cast());
        final countpointer = calloc<Uint32>();
        itemArray.GetCount(countpointer);
        print(countpointer.value);
        for (var i = 0; i < countpointer.value; i++) {
          final iShellPointer = calloc<Pointer>();

          itemArray.GetItemAt(i, iShellPointer);

          final item = IShellItem(iShellPointer.cast());
          final pathPtrPtr = calloc<Pointer<Utf16>>();

          hr = item.GetDisplayName(SIGDN.SIGDN_FILESYSPATH, pathPtrPtr);
          if (FAILED(hr)) throw WindowsException(hr);

          filePath = pathPtrPtr.value.toDartString();
          filePaths.add(filePath);
          hr = item.Release();
        }
        print(filePaths);
        itemArray.Release();

        //  return filePaths
      } else {
        final item = IShellItem(ppsi.cast());
        final pathPtrPtr = calloc<Pointer<Utf16>>();
        hr = item.GetDisplayName(SIGDN.SIGDN_FILESYSPATH, pathPtrPtr);
        if (FAILED(hr)) throw WindowsException(hr);

        filePath = pathPtrPtr.value.toDartString();
        filePaths.add(filePath);
        hr = item.Release();
        if (FAILED(hr)) throw WindowsException(hr);
      }
    }

    hr = fileDialog.Release();
    if (FAILED(hr)) throw WindowsException(hr);

    CoUninitialize();
    if (didUserCancel) {
      return null;
    } else {
      return List<File>.from(filePaths.map<File>((e) => File(e)));
    }
  }
}
