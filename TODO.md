- [ ] Inspect current file selection + upload flow (ApplicationFormView -> ApplicationViewModel)
- [ ] Update ApplicationFormView to store PlatformFile (not dart:io File)
- [ ] Update ApplicationViewModel to accept PlatformFile and upload using uploadBytes(file.bytes)
- [ ] Ensure validation (extensions + size) works when file.path is null (web)
- [ ] Run flutter analyze
- [ ] Run app / web test: verify upload works when path is null

