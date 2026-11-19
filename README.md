# GSI / Custom ROM Emulator (Flutter + C++ FFI)

## Ishga tushirish bo'yicha ko'rsatma:
1. Ushbu fayllarni GitHub'dagi yangi repository ichiga yuklang.
2. `android/app/build.gradle` faylining `android { ... }` bloki ichiga CMake sozlamasini qo'shing:
   ```gradle
   externalNativeBuild {
       cmake {
           path "src/main/cpp/CMakeLists.txt"
       }
   }
   ```
3. GitHub'dagi **Actions** bo'limiga o'tib, tayyor APK yig'ilishini kuting va yuklab oling.
