/// Enable only after the Firebase Storage bucket, rules, and cross-service
/// permissions have been deployed. Text posts and comments do not need Storage.
const communityPhotoUploadsEnabled = bool.fromEnvironment(
  'COMMUNITY_PHOTO_UPLOADS_ENABLED',
  defaultValue: false,
);
