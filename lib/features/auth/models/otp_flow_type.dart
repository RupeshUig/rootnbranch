/// Distinguishes between OTP verification destinations.
enum OtpFlowType {
  /// Sign up verification -> leads to Account Created screen.
  signup,

  /// Password recovery verification -> leads to Create New Password screen.
  passwordRecovery,
}
