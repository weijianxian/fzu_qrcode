<p align="center">
<img src="https://socialify.git.ci/weijianxian/fzu_qrcode/image?description=1&descriptionEditable=%E5%9B%A0%E4%B8%BA%E6%87%92%E5%BE%97%E4%BD%BF%E7%94%A8%E8%8E%8E%E5%AE%9D%E5%B0%8F%E7%A8%8B%E5%BA%8F%EF%BC%8C%E6%89%80%E4%BB%A5%E6%88%91%E5%86%99%E4%BA%86%E4%B8%AAAPP&font=Jost&forks=1&issues=1&language=1&logo=https%3A%2F%2Favatars.githubusercontent.com%2Fu%2F33548986%3Fv%3D4%26size%3D256&name=1&owner=1&pattern=Diagonal%20Stripes&pulls=1&stargazers=1&theme=Light" alt="fzu_qrcode" width="640" height="320" />
</p>

<h1 align="center">fzu_qrcode</h1>
<div align="center">因为懒得使用福大一码通小程序，所以写了个app</div>

## 使用方法

### 直接下载

请前往 [Action](https://github.com/weijianxian/fzu_qrcode/actions) 下载最新构建
或前往 [Release](https://github.com/weijianxian/fzu_qrcode/releases/latest) 下载最新稳定版本

### 手动构建

```sh
$ flutter --version
Flutter 3.27.0 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 8495dee1fd • 2024-12-10 14:23:39 -0800
Engine • revision 83bacfc525
Tools • Dart 3.6.0 • DevTools 2.40.2
```

1. 确保你已经安装了 Flutter SDK，并且配置了 Flutter 环境。
2. 在项目根目录下运行以下命令以获取项目依赖： `flutter pub get`
3. 1. build APK

```sh
# 配置签名
export KEYSTORE_PATH=path/to/your/keystore.jks
export KEYSTORE_PASSWORD=your_keystore_password
export KEY_ALIAS=your_key_alias
export KEY_PASSWORD=your_key_password
flutter build apk --release
```

3. 2. build exe

```sh
flutter build windows --release
```
