import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:image_cropper/image_cropper.dart';

class RoundedImageField extends StatefulWidget {
  final Function(File?) onImageSelected;

  RoundedImageField({
    Key? key,
    required this.onImageSelected,
  }) : super(key: key);

  @override
  State<RoundedImageField> createState() => _RoundedImageField();
}

class _RoundedImageField extends State<RoundedImageField> {
  File? _image;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      padding: const EdgeInsets.only(left: 10,right: 10),
      child: TextButton(
        onPressed: () async {
          final picker = ImagePicker();
          final pickedFile =
          await picker.pickImage(source: ImageSource.gallery);

          CroppedFile? croppedFile = await ImageCropper().cropImage(
            sourcePath: pickedFile!.path,
            aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1), // Set desired aspect ratio
            compressQuality: 70, // Set desired quality (0 - 100)
            maxWidth: 1000, // Set maximum width
            maxHeight: 750, // Set maximum height
          );

          if (croppedFile != null) {
            File newFile = File(croppedFile.path);
            setState(() {
              _image = newFile;
              widget.onImageSelected(_image);
            });
          }
        },
        child: _image != null
            ? Image.file(
          _image!,
          height: size.height*0.3,
          width: size.width,
          fit: BoxFit.cover,
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 36,
              color: softTextColor,
            ),
            SizedBox(height: 8),
            Text(
              'Add a photo',
              style: TextStyle(
                color: softTextColor,
                fontFamily: "SourceSansPro",
              ),
            ),
          ],
        ),
      ),
    );
  }
}

