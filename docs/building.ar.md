# بناء نزّل

[English](building.md) · **العربية**

## المتطلبات

| الأداة | الإصدار |
|---|---|
| Flutter | 3.44 (المستقر) |
| JDK | 21، نسخة كاملة فيها `javac` |
| Android SDK | المنصة 36 وأدوات البناء 36 |
| Python | 3.13 على جهاز البناء باسم `python3.13` أو محددًا في `NAZZEL_BUILD_PYTHON` |

يترجم Chaquopy شيفرة Python الخاصة بالتطبيق باستخدام Python على جهاز البناء من الإصدار الفرعي نفسه، ولهذا يلزم الإصدار 3.13. ويثبّت Gradle حزم Python الخاصة بأندرويد تلقائيًا.

يحتاج بناء الإصدار إلى نحو 2 جيجابايت من الذاكرة لـGradle.

## بناء التطوير

```bash
tools/fetch-qjs.sh                 # downloads QuickJS-NG and checks its SHA-256
flutter build apk --debug --target-platform android-arm64
```

## بناء الإصدار

تُوقَّع ملفات APK الرسمية بمفتاح لا يغادر جهاز المشرف. لتوقيع نسختك الخاصة أنشئ الملف `.secrets/key.properties`:

```properties
storeFile=nazzel.jks
storePassword=change-me
keyAlias=nazzel
keyPassword=change-me
```

وضع ملف المفاتيح بجانبه (`.secrets/nazzel.jks`)، ثم:

```bash
tools/fetch-qjs.sh
flutter build apk --release --target-platform android-arm64
```

لا يمكن لملف APK موقّع بمفتاح مختلف أن يحدّث نسخة مثبتة من التطبيق الرسمي، وسيطلب أندرويد إزالتها أولًا.

## نشر إصدار

1. ارفع قيمة `version` في `pubspec.yaml`، وقيمة `ENGINE_VERSION` في `engine.py` إن تغيّر
2. أضف التغييرات إلى `CHANGELOG.md`
3. ابنِ ملف الإصدار في `dist/nazzel.apk`
4. شغّل `tools/release.sh "الملاحظات" --publish`

ينشئ السكربت الملف `update.json` للتحديث داخل التطبيق، ويوقّع `engine.json` بالمفتاح `.secrets/engine-signing.pem`، وينشئ الإصدار على GitHub بكل ملفاته.
