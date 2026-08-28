#!/usr/bin/env bash

set -euo pipefail

export LC_ALL=C
export COPYFILE_DISABLE=1

program_name="test-macos-distribution"

usage() {
  cat <<'USAGE'
Usage:
  tooling/test-macos-distribution.sh OUTPUT_DIRECTORY TARGET_IDENTIFIER

Test one transferred unpublished macOS archive on clean native hardware with
no Racket installation or source checkout. TARGET_IDENTIFIER must be
macos-x86_64 or macos-arm64.
USAGE
}

die() {
  printf '%s: %s\n' "$program_name" "$1" >&2
  exit 2
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command is unavailable: $1"
}

sha256_file() {
  shasum -a 256 "$1" | awk '{print $1}'
}

dotenv_component() {
  local lower_path
  lower_path="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  [[ "/$lower_path/" =~ /([^/]*\.)?env(\.[^/]*)?/ ]]
}

milliseconds_now() {
  perl -MTime::HiRes=time -e 'printf "%.0f\n", time() * 1000'
}

if [[ "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi
[[ "$#" -eq 2 ]] || {
  usage >&2
  exit 2
}

output_argument="$1"
target_identifier="$2"
case "$target_identifier" in
  macos-x86_64)
    expected_uname_architecture="x86_64"
    expected_macho_architecture="x86_64"
    ;;
  macos-arm64)
    expected_uname_architecture="arm64"
    expected_macho_architecture="arm64"
    ;;
  *) die "TARGET_IDENTIFIER must be macos-x86_64 or macos-arm64" ;;
esac

for command_name in awk basename cat cmp env file find grep lipo mkdir mktemp mv otool perl rm sed shasum sleep sort stat sw_vers tar tr uname; do
  require_command "$command_name"
done

[[ "$(uname -s)" == "Darwin" ]] || die "consumer requires macOS"
[[ "$(uname -m)" == "$expected_uname_architecture" ]] ||
  die "consumer requires native $expected_uname_architecture hardware"
command -v racket >/dev/null 2>&1 && die "consumer unexpectedly has a racket command"
command -v raco >/dev/null 2>&1 && die "consumer unexpectedly has a raco command"

if [[ -n "${GITHUB_WORKSPACE:-}" ]]; then
  [[ ! -e "$GITHUB_WORKSPACE/.git" && ! -L "$GITHUB_WORKSPACE/.git" ]] ||
    die "consumer unexpectedly has a source checkout"
fi

[[ -d "$output_argument" && ! -L "$output_argument" ]] ||
  die "OUTPUT_DIRECTORY must be a nonsymlink directory"
output_directory="$(cd "$output_argument" && pwd -P)"
checksum_path="$output_directory/SHA256SUMS"
[[ -f "$checksum_path" && ! -L "$checksum_path" ]] ||
  die "checksum manifest is unavailable: $checksum_path"

archive_path=""
archive_count=0
for archive_candidate in "$output_directory"/alone-the-lambdas-*-$target_identifier.tar.gz; do
  if [[ -f "$archive_candidate" && ! -L "$archive_candidate" ]]; then
    archive_path="$archive_candidate"
    archive_count=$((archive_count + 1))
  fi
done
[[ "$archive_count" -eq 1 ]] ||
  die "OUTPUT_DIRECTORY must contain exactly one $target_identifier archive"

archive_name="$(basename "$archive_path")"
artifact_root_name="${archive_name%.tar.gz}"
product_version="${artifact_root_name#alone-the-lambdas-}"
product_version="${product_version%-$target_identifier}"
case "$product_version" in
  0.2.0-dev|0.2.0-rc.1|0.2.0) ;;
  *) die "archive filename contains an unapproved product version" ;;
esac
[[ "$artifact_root_name" == "alone-the-lambdas-$product_version-$target_identifier" ]] ||
  die "archive filename does not follow the target contract"

[[ "$(stat -f '%Lp' "$archive_path")" == "644" ]] || die "archive mode must be 0644"
[[ "$(stat -f '%Lp' "$checksum_path")" == "644" ]] || die "checksum manifest mode must be 0644"
expected_checksum_line="$(<"$checksum_path")"
[[ "$expected_checksum_line" =~ ^[0-9a-f]{64}[[:space:]][[:space:]]${archive_name//./\.}$ ]] ||
  die "SHA256SUMS must contain exactly the versioned macOS archive"
[[ "${expected_checksum_line%% *}" == "$(sha256_file "$archive_path")" ]] ||
  die "transferred archive checksum mismatch"
(cd "$output_directory" && shasum -a 256 -c SHA256SUMS >/dev/null)

scratch_parent="${TMPDIR:-/tmp}"
[[ -d "$scratch_parent" && ! -L "$scratch_parent" ]] ||
  die "consumer temporary directory parent is unavailable or symlinked"
scratch_parent="$(cd "$scratch_parent" && pwd -P)"
scratch_root="$(mktemp -d "$scratch_parent/alone-the-lambdas-macos-consumer-XXXXXX")"
server_pid=""

cleanup() {
  if [[ -n "${server_pid:-}" ]] && kill -0 "$server_pid" 2>/dev/null; then
    kill "$server_pid" 2>/dev/null || true
    wait "$server_pid" 2>/dev/null || true
  fi
  if [[ -n "${scratch_root:-}" &&
        "$scratch_root" == "$scratch_parent/alone-the-lambdas-macos-consumer-"* &&
        -d "$scratch_root" ]]; then
    rm -rf "$scratch_root"
  fi
}
trap cleanup EXIT

first_parent="$scratch_root/first path with spaces"
first_root="$first_parent/$artifact_root_name"
second_parent="$scratch_root/second relocated path"
second_root="$second_parent/$artifact_root_name"

while IFS= read -r archive_entry; do
  [[ "$archive_entry" == "$artifact_root_name" ||
     "$archive_entry" == "$artifact_root_name/"* ]] ||
    die "archive contains an entry outside its one root directory"
  [[ "$archive_entry" != /* &&
     "/$archive_entry/" != *'/../'* ]] ||
    die "archive contains an unsafe path"
  dotenv_component "$archive_entry" && die "archive contains a dotenv path"
done < <(tar -tzf "$archive_path")

mkdir -p "$first_parent"
tar -xzf "$archive_path" -C "$first_parent"
[[ -d "$first_root" && ! -L "$first_root" ]] || die "archive root is unavailable"

while IFS= read -r -d '' linked_path; do
  die "extracted artifact contains a symlink: ${linked_path#"$first_root/"}"
done < <(
  find "$first_root" \
    \( -iname '.env' -o -iname '*.env' -o -iname '.env.*' -o -iname '*.env.*' \) -prune -o \
    -type l -print0
)

for required_path in \
  bin/atl \
  examples/hello.atl \
  examples/stdout.atl \
  examples/file-round-trip.atl \
  examples/http-server.atl \
  GETTING_STARTED.md \
  BUILD-MANIFEST.txt \
  UNPUBLISHED-DEVELOPMENT-ARTIFACT.txt \
  THIRD_PARTY_NOTICES.md; do
  [[ -f "$first_root/$required_path" && ! -L "$first_root/$required_path" ]] ||
    die "artifact is missing required file: $required_path"
done
[[ -d "$first_root/lib" && ! -L "$first_root/lib" ]] || die "artifact is missing lib/"
[[ -x "$first_root/bin/atl" ]] || die "bin/atl is not executable"
[[ ! -e "$first_root/LICENSE" && ! -L "$first_root/LICENSE" ]] ||
  die "development artifact must not contain an unapproved repository license"

actual_top_level="$scratch_root/actual-top-level.txt"
expected_top_level="$scratch_root/expected-top-level.txt"
find "$first_root" -mindepth 1 -maxdepth 1 \
  \( -iname '.env' -o -iname '*.env' -o -iname '.env.*' -o -iname '*.env.*' \) -prune -o \
  -exec basename {} \; |
  sort > "$actual_top_level"
printf '%s\n' \
  BUILD-MANIFEST.txt \
  GETTING_STARTED.md \
  THIRD_PARTY_NOTICES.md \
  UNPUBLISHED-DEVELOPMENT-ARTIFACT.txt \
  bin \
  examples \
  lib |
  sort > "$expected_top_level"
cmp -s "$actual_top_level" "$expected_top_level" ||
  die "artifact top-level layout differs from the contract"

actual_bin="$scratch_root/actual-bin.txt"
actual_examples="$scratch_root/actual-examples.txt"
find "$first_root/bin" -mindepth 1 -maxdepth 1 \
  \( -iname '.env' -o -iname '*.env' -o -iname '.env.*' -o -iname '*.env.*' \) -prune -o \
  -exec basename {} \; |
  sort > "$actual_bin"
printf '%s\n' atl > "$scratch_root/expected-bin.txt"
cmp -s "$actual_bin" "$scratch_root/expected-bin.txt" ||
  die "artifact bin/ inventory differs from the contract"
find "$first_root/examples" -mindepth 1 -maxdepth 1 \
  \( -iname '.env' -o -iname '*.env' -o -iname '.env.*' -o -iname '*.env.*' \) -prune -o \
  -exec basename {} \; |
  sort > "$actual_examples"
printf '%s\n' file-round-trip.atl hello.atl http-server.atl stdout.atl \
  > "$scratch_root/expected-examples.txt"
cmp -s "$actual_examples" "$scratch_root/expected-examples.txt" ||
  die "artifact examples/ inventory differs from the contract"

actual_inventory="$scratch_root/actual-inventory.txt"
manifest_inventory="$scratch_root/manifest-inventory.txt"
while IFS= read -r -d '' artifact_file; do
  printf '%s\n' "${artifact_file#"$first_root/"}"
done < <(
  find "$first_root" \
    \( -iname '.env' -o -iname '*.env' -o -iname '.env.*' -o -iname '*.env.*' \) -prune -o \
    -type f -print0
) | sort > "$actual_inventory"
awk '
  /^Artifact file inventory:$/ { inventory=1; next }
  inventory && /^  / { sub(/^  /, ""); print; next }
  inventory { inventory=0 }
' "$first_root/BUILD-MANIFEST.txt" > "$manifest_inventory"
cmp -s "$actual_inventory" "$manifest_inventory" ||
  die "BUILD-MANIFEST.txt file inventory differs from the artifact"

grep -Fxq "Product version: $product_version" "$first_root/BUILD-MANIFEST.txt" ||
  die "build manifest version mismatch"
grep -Fxq "Target identifier: $target_identifier" "$first_root/BUILD-MANIFEST.txt" ||
  die "build manifest target mismatch"
grep -Fxq 'Racket version: 9.3' "$first_root/BUILD-MANIFEST.txt" ||
  die "build manifest Racket version mismatch"
grep -Fxq 'Racket variant: CS' "$first_root/BUILD-MANIFEST.txt" ||
  die "build manifest Racket variant mismatch"
grep -Eq '^Source commit: [0-9a-f]{40}$' "$first_root/BUILD-MANIFEST.txt" ||
  die "build manifest source commit is invalid"
grep -Fxq 'Archive checksum: external sibling SHA256SUMS' "$first_root/BUILD-MANIFEST.txt" ||
  die "build manifest checksum contract mismatch"
grep -Fq 'UNPUBLISHED DEVELOPMENT ARTIFACT' "$first_root/UNPUBLISHED-DEVELOPMENT-ARTIFACT.txt" ||
  die "development warning is absent"
grep -Fq 'LICENSE-APACHE.txt' "$first_root/THIRD_PARTY_NOTICES.md" ||
  die "provisional Racket notice is incomplete"
grep -Eq '/Users/|/private/var/folders/|/Volumes/' "$first_root/BUILD-MANIFEST.txt" &&
  die "build manifest contains a private macOS path"

manifest_mach_o="$scratch_root/manifest-mach-o.txt"
actual_mach_o="$scratch_root/actual-mach-o.txt"
manifest_dynamic="$scratch_root/manifest-dynamic.txt"
actual_dynamic="$scratch_root/actual-dynamic.txt"
awk '
  /^Mach-O architecture inventory:$/ { inventory=1; next }
  inventory && /^  / { sub(/^  /, ""); print; next }
  inventory { inventory=0 }
' "$first_root/BUILD-MANIFEST.txt" > "$manifest_mach_o"
awk '
  /^Observed dynamic system-library assumptions:$/ { inventory=1; next }
  inventory && /^  / { sub(/^  /, ""); print; next }
  inventory { inventory=0 }
' "$first_root/BUILD-MANIFEST.txt" > "$manifest_dynamic"

: > "$actual_mach_o"
: > "$actual_dynamic"
while IFS= read -r -d '' runtime_path; do
  if file -b "$runtime_path" | grep -Fq 'Mach-O'; then
    runtime_relative_path="${runtime_path#"$first_root/"}"
    runtime_architectures="$(lipo -archs "$runtime_path")"
    [[ "$runtime_architectures" == "$expected_macho_architecture" ]] ||
      die "Mach-O file has unexpected architecture: $runtime_relative_path"
    printf '%s: %s\n' "$runtime_relative_path" "$runtime_architectures" \
      >> "$actual_mach_o"
    while IFS= read -r dependency_path; do
      [[ -n "$dependency_path" ]] || continue
      case "$dependency_path" in
        @executable_path/*|@loader_path/*|@rpath/*)
          ;;
        /usr/lib/*|/System/Library/*)
          printf '%s\n' "$dependency_path" >> "$actual_dynamic"
          ;;
        /*) die "Mach-O file retains a non-system absolute dependency" ;;
        *) die "Mach-O file has an unclassified dependency" ;;
      esac
    done < <(otool -L "$runtime_path" | sed -n '2,$p' | awk '{print $1}')
  fi
done < <(
  find "$first_root/bin" "$first_root/lib" \
    \( -iname '.env' -o -iname '*.env' -o -iname '.env.*' -o -iname '*.env.*' \) -prune -o \
    -type f -print0
)
sort -u "$actual_mach_o" > "$actual_mach_o.sorted"
mv "$actual_mach_o.sorted" "$actual_mach_o"
sort -u "$actual_dynamic" > "$actual_dynamic.sorted"
mv "$actual_dynamic.sorted" "$actual_dynamic"
[[ -s "$actual_mach_o" && -s "$actual_dynamic" ]] ||
  die "consumer found no native runtime dependency inventory"
cmp -s "$actual_mach_o" "$manifest_mach_o" ||
  die "Mach-O architecture inventory differs from the artifact"
cmp -s "$actual_dynamic" "$manifest_dynamic" ||
  die "dynamic system-library inventory differs from the artifact"

while IFS= read -r -d '' artifact_file; do
  if grep -aEq '/Users/runner/work/|alone-the-lambdas-macos-build-|/racket-user/' "$artifact_file"; then
    die "artifact retains a checkout, package-registry, or build-runner path"
  fi
done < <(
  find "$first_root" \
    \( -iname '.env' -o -iname '*.env' -o -iname '.env.*' -o -iname '*.env.*' \) -prune -o \
    -type f -print0
)

atl="$first_root/bin/atl"
stdout_file="$scratch_root/stdout.txt"
stderr_file="$scratch_root/stderr.txt"
expected_file="$scratch_root/expected-output.txt"

check_captured_output() {
  local expected_output="$1"
  local failure_label="$2"
  printf '%s' "$expected_output" > "$expected_file"
  cmp -s "$stdout_file" "$expected_file" || die "$failure_label output mismatch"
  [[ ! -s "$stderr_file" ]] || die "$failure_label wrote stderr"
}

run_atl() {
  env -u PLTCOLLECTS -u PLTADDONDIR -u PLTCONFIGDIR "$atl" "$@"
}

first_startup_begin="$(milliseconds_now)"
run_atl --version >"$stdout_file" 2>"$stderr_file"
first_startup_end="$(milliseconds_now)"
first_startup_milliseconds=$((first_startup_end - first_startup_begin))
check_captured_output "Alone the Lambdas $product_version"$'\n' "packaged version"

run_atl --help >"$stdout_file" 2>"$stderr_file"
check_captured_output \
  $'Usage:\n  atl run FILE.atl\n  atl --help\n  atl --version\n' \
  "packaged help"

generated_directory="$scratch_root/generated source path with spaces"
mkdir -p "$generated_directory"
generated_source="$generated_directory/generated-after-packaging.atl"
printf '%s\n' \
  '#lang alone_the_lambdas' \
  '' \
  '(stdout "Generated after packaging.\n")' \
  > "$generated_source"
run_atl run "$generated_source" >"$stdout_file" 2>"$stderr_file"
check_captured_output $'Generated after packaging.\n' "generated source"

decoy_root="$scratch_root/decoy-collections"
mkdir -p "$decoy_root/alone_the_lambdas/lang"
printf '%s\n' 'this external reader must never be loaded' \
  > "$decoy_root/alone_the_lambdas/lang/reader.rkt"
PLTCOLLECTS="$decoy_root" "$atl" run "$generated_source" \
  >"$stdout_file" 2>"$stderr_file"
check_captured_output $'Generated after packaging.\n' "embedded-language precedence run"

stdout_work="$scratch_root/stdout-work"
mkdir -p "$stdout_work"
(cd "$stdout_work" && run_atl run "$first_root/examples/stdout.atl" \
  >"$stdout_file" 2>"$stderr_file")
check_captured_output $'Hello from Alone the Lambdas.\n' "stdout example"

file_work="$scratch_root/file-work"
mkdir -p "$file_work"
(cd "$file_work" && run_atl run "$first_root/examples/file-round-trip.atl" \
  >"$stdout_file" 2>"$stderr_file")
check_captured_output $'Alone the Lambdas file round trip.\n' "file round trip"
printf '%s' $'Alone the Lambdas file round trip.\n' > "$expected_file"
cmp -s "$file_work/alone-the-lambdas-round-trip.txt" "$expected_file" ||
  die "packaged file round trip wrote the wrong bytes"

http_work="$scratch_root/http-work"
announcement_file="$scratch_root/http-announcement.txt"
http_error_file="$scratch_root/http-stderr.txt"
response_file="$scratch_root/http-response.txt"
mkdir -p "$http_work"
(cd "$http_work" && run_atl run "$first_root/examples/http-server.atl" \
  > "$announcement_file" 2> "$http_error_file") &
server_pid="$!"
attempt=0
while [[ "$attempt" -lt 400 ]]; do
  [[ -s "$announcement_file" ]] && break
  kill -0 "$server_pid" 2>/dev/null || break
  attempt=$((attempt + 1))
  sleep 0.05
done
announcement="$(<"$announcement_file")"
[[ "$announcement" =~ ^Listening[[:space:]]on[[:space:]]http://127\.0\.0\.1:([0-9]+)/lambda$ ]] ||
  die "packaged HTTP example did not announce an ephemeral loopback URL"
bound_port="${BASH_REMATCH[1]}"
exec 3<>"/dev/tcp/127.0.0.1/$bound_port"
printf 'GET /lambda HTTP/1.1\r\nHost: 127.0.0.1\r\nConnection: close\r\n\r\n' >&3
cat <&3 > "$response_file"
exec 3<&-
exec 3>&-
attempt=0
while kill -0 "$server_pid" 2>/dev/null; do
  if [[ "$attempt" -ge 400 ]]; then
    die "packaged HTTP example did not stop after one request"
  fi
  attempt=$((attempt + 1))
  sleep 0.05
done
if ! wait "$server_pid"; then
  die "packaged HTTP example exited unsuccessfully"
fi
server_pid=""
[[ ! -s "$http_error_file" ]] || die "HTTP example wrote stderr"
grep -Fq $'HTTP/1.1 200 OK\r' "$response_file" || die "HTTP response status mismatch"
sed -n '/^\r$/,$p' "$response_file" | sed '1d' > "$scratch_root/http-body.txt"
printf '%s' $'Hello from Alone the Lambdas.\n' > "$expected_file"
cmp -s "$scratch_root/http-body.txt" "$expected_file" ||
  die "HTTP response body mismatch"

mkdir -p "$second_parent"
mv "$first_root" "$second_root"
atl="$second_root/bin/atl"
relocated_startup_begin="$(milliseconds_now)"
run_atl --version >"$stdout_file" 2>"$stderr_file"
relocated_startup_end="$(milliseconds_now)"
relocated_startup_milliseconds=$((relocated_startup_end - relocated_startup_begin))
check_captured_output "Alone the Lambdas $product_version"$'\n' "relocated version"
run_atl run "$generated_source" >"$stdout_file" 2>"$stderr_file"
check_captured_output $'Generated after packaging.\n' "relocated source"

printf 'consumer_macos_version=%s\n' "$(sw_vers -productVersion)"
printf 'consumer_architecture=%s\n' "$(uname -m)"
printf 'consumer_racket_command=absent\n'
printf 'consumer_raco_command=absent\n'
printf 'consumer_checkout=absent\n'
printf 'relocation=passed\n'
printf 'first_startup_milliseconds=%s\n' "$first_startup_milliseconds"
printf 'relocated_startup_milliseconds=%s\n' "$relocated_startup_milliseconds"
printf 'consumer_acceptance=passed\n'
