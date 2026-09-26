#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
find apps packages -type f -name '*_test.dart' -print0 |
  xargs -0 fvm flutter test
