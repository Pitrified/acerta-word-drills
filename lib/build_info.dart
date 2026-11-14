/// The version name of the build, set with `--dart-define=APP_VERSION`.
const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: 'dev');

/// The commit of the build, set with `--dart-define=GIT_COMMIT`.
const appCommit = String.fromEnvironment('GIT_COMMIT', defaultValue: 'local');

/// The version and commit, such as `0.1.0+1a2b3c4d`.
const appVersionLabel = '$appVersion+$appCommit';

/// Where the source code lives.
const sourceRepoUrl = 'https://github.com/Pitrified/acerta-word-drills';
