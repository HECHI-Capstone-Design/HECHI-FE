# mobile_ocr_flutter

Reusable Flutter OCR package for phone-camera capture and text-line extraction.

## Public API

- `MobileOcr.captureAndRecognize()`
- `MobileOcr.pickAndRecognize()`
- `MobileOcr.recognizeFilePath()`

The package uses `image_picker` for image capture/selection and `google_mlkit_text_recognition`
for on-device OCR.
