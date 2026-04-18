flutter clean
.\gradlew --stop
Remove-Item -Recurse -Force .\build\app\intermediates\lint-cache -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .\build\app\outputs -ErrorAction SilentlyContinue
flutter pub get
flutter build apk --release
