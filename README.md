# spx_cold_wallet

## Getting Started

编译C语言SPX接口为.so共享库(已编译)
```bash
cd clib
ndk-build
```
生成的文件在 clib\libs，将其拷贝到 android\app\src\main\jniLibs 即可


编译flutter项目成apk
```bash
flutter build apk
```
结果所在目录
build/app/outputs/flutter-apk/
