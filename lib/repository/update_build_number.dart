const int _androidSplitVersionCodeMultiplier = 10;
const int _minimumSplitReleaseBuild = 41;
const int _minimumSplitVersionCode =
    _minimumSplitReleaseBuild * _androidSplitVersionCodeMultiplier + 1;
const Set<int> _androidSplitAbiSuffixes = {1, 2, 3};

int normalizeBuildNumberForUpdateComparison({
  required int rawBuild,
  required bool isAndroid,
}) {
  if (!isAndroid) {
    return rawBuild;
  }
  if (!_looksLikeSplitVersionCode(rawBuild)) {
    return rawBuild;
  }
  return rawBuild ~/ _androidSplitVersionCodeMultiplier;
}

bool _looksLikeSplitVersionCode(int rawBuild) {
  if (rawBuild < _minimumSplitVersionCode) {
    return false;
  }
  final abiSuffix = rawBuild % _androidSplitVersionCodeMultiplier;
  return _androidSplitAbiSuffixes.contains(abiSuffix);
}
