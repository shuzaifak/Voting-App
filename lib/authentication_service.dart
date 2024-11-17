import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );
  CameraController? _cameraController;

  Future<bool> checkBiometricSupport() async {
    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;

      if (!isDeviceSupported || !canCheckBiometrics) {
        return false;
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      print('Error checking biometric support: $e');
      return false;
    }
  }

  Future<BiometricResult> authenticateWithBiometrics() async {
    try {
      final isSupported = await checkBiometricSupport();
      if (!isSupported) {
        return BiometricResult(
          success: false,
          message: 'Biometric authentication is not supported on this device',
        );
      }

      // Add error handling for FragmentActivity
      try {
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate to cast your vote',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );

        return BiometricResult(
          success: authenticated,
          message: authenticated ? 'Authentication successful' : 'Authentication failed',
        );
      } on PlatformException catch (e) {
        if (e.code == 'no_fragment_activity') {
          return BiometricResult(
            success: false,
            message: 'Authentication not available at the moment. Please try again.',
          );
        }
        rethrow;
      }
    } catch (e) {
      return BiometricResult(
        success: false,
        message: 'Authentication error: $e',
      );
    }
  }

  Future<BiometricResult> authenticateWithFaceID() async {
    try {
      // Initialize camera
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return BiometricResult(
          success: false,
          message: 'No camera available',
        );
      }

      final frontCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      // Capture image
      final image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);

      // Detect faces
      final faces = await _faceDetector.processImage(inputImage);

      // Clean up
      await _cameraController!.dispose();
      _cameraController = null;

      if (faces.isEmpty) {
        return BiometricResult(
          success: false,
          message: 'No face detected. Please try again.',
        );
      }

      if (faces.length > 1) {
        return BiometricResult(
          success: false,
          message: 'Multiple faces detected. Please try again alone.',
        );
      }

      // Here you would typically:
      // 1. Extract face features
      // 2. Compare with stored template
      // 3. Verify liveness
      // For this example, we'll simulate success if a single face is detected

      return BiometricResult(
        success: true,
        message: 'Face verification successful',
      );
    } catch (e) {
      if (_cameraController != null) {
        await _cameraController!.dispose();
        _cameraController = null;
      }

      return BiometricResult(
        success: false,
        message: 'Face verification error: $e',
      );
    }
  }
}

class BiometricResult {
  final bool success;
  final String message;

  BiometricResult({
    required this.success,
    required this.message,
  });
}