# media_cache_manager

#### helps you to cache and encrypt media (Audio, Video, Image, etc...) Permanently or for specific time.

##### With a URL the [DownloadMediaBuilder] Widget search locally for the file, if file found get it back to snapshot object, if not found then download it then give it to snapshot.

---

# What is new ??

### - Encrypt and decrypt downloaded files with AES.

### - Cancel download.

### - Retry download if failed.

### - Add Encrypting/Decrypting status.

### - Refactor DownloadMediaBuilder Widget.

### - Optimize plugin imports.

---

## Install

in pubspec.yaml file under dependencies add

```
media_cache_manager: 
```

### For Android :

Go to android -> app -> build.gradle
and add this line inside defaultConfig scope

```
multiDexEnabled true
```

and modify minSdkVersion to 20

---

## Initializing plugin ( Required )

```
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MediaCacheManager.instance.init();
  runApp(const MyApp());
}
```

## Encrypted Files ( Optional )

Encrypting files using AES Encryption with OFB mode.

Call this method once in your main function or elsewhere.

```
await MediaCacheManager.instance.setEncryptionPassword("I love flutter");
```

> Note :
> * Use this wisely it can affect on performance if you are processing multi and large files.
> * User and Other apps can not access unencrypted files due to files stored in Temporary Directory.

### OR when Initializing plugin you can call a param encryptionPassword instead.

```
await MediaCacheManager.instance.init(encryptionPassword: 'I love flutter');
```

> Note :
> * By default encryption is disabled until you call setEncryptionPassword.
> * Large files takes more time to en/decrypt.

## setExpireDate ( Optional )

before using the DownloadMediaBuilder Widget you have to call this method for once.
ex: I am calling it in main method or at my splash screen.
if you didn't call this method it will cache Permanently.

```
await MediaCacheManager.instance.setExpireDate(daysToExpire: 10);
```

### OR when Initializing plugin you can call a param daysToExpire instead.

```
await MediaCacheManager.instance.init(daysToExpire: 1);
```

---

## General Usage

```
import 'package:media_cache_manager/media_cache_manager.dart';
```

```
DownloadMediaBuilder(
  url: 'https://static.remove.bg/remove-bg-web/5c20d2ecc9ddb1b6c85540a333ec65e2c616dbbd/assets/start-1abfb4fe2980eabfbbaaa4365a0692539f7cd2725f324f904565a9a744f8e214.jpg',
  onSuccess: (snapshot) {
    return Image.file(File(snapshot.filePath!));
  },
),
```

## Handle Loading and error states

```
DownloadMediaBuilder(
  url: 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_30mb.mp4',
  onLoading: (snapshot) {
    return LinearProgressIndicator(value: snapshot.progress); 
  },
  onSuccess: (snapshot) {
    return BetterPlayer.file(snapshot.filePath!);
  }, 
  onError: (snapshot) {
    return const Text('Error!');
  },
),
```

## Handle Canceled and retry states

```
late DownloadMediaBuilderController controller;

DownloadMediaBuilder(
  url: 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_30mb.mp4',
  onInit: (controller) => this.controller = controller,
  onLoading: (snapshot) {
    /// Cancel download if the status is still loading
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          value: snapshot.progress,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: controller.cancel,
          child: const Text('Cancel Download'),
        ),
      ],
    );
  },
  onSuccess: (snapshot) {
    return BetterPlayer.file(snapshot.filePath!);
  }, 
  onError: (snapshot) {
    return const Text('Error!');
  },
  onCancel: (snapshot) {
    /// Retry to download the file if the status is canceled
    return ElevatedButton(
      onPressed: controller.retry,
      child: const Text('Retry'),
    );
  },
 ),
```

> Note: if the status is not loading you can not call cancel function
> retry function is only available if the status is loading

## Explaining of snapshot

#### DownloadMediaSnapshot has three fields :

- ##### Status, it has 6 status (Success, Loading, Error, Canceled, Encrypting, Decrypting).
- ##### FilePath, it will be available if the file had been downloaded.
- ##### Progress, it's the process progress if the file is downloading.