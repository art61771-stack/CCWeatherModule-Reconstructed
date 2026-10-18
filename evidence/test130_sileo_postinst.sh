#!/bin/sh
set -eu

postinst=${1:-layout/DEBIAN/postinst}
tmp=${TMPDIR:-/tmp}/ccweather-postinst-test.$$
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

run_quiet() {
	name=$1
	value=$2
	if [ "$value" = __UNSET__ ]; then
		env -u SILEO sh "$postinst" >"$tmp/$name.out" 2>"$tmp/$name.err"
	else
		SILEO=$value sh "$postinst" >"$tmp/$name.out" 2>"$tmp/$name.err"
	fi
	test ! -s "$tmp/$name.out"
	test ! -s "$tmp/$name.err"
}

SILEO='3 1' sh "$postinst" 3>"$tmp/fd3" >"$tmp/fd3.out" 2>"$tmp/fd3.err"
test "$(cat "$tmp/fd3")" = 'finish:restart'
test "$(wc -l <"$tmp/fd3" | tr -d ' ')" = 1
test ! -s "$tmp/fd3.out"
test ! -s "$tmp/fd3.err"

SILEO='4 2' sh "$postinst" 4>"$tmp/fd4" >"$tmp/fd4.out" 2>"$tmp/fd4.err"
test "$(cat "$tmp/fd4")" = 'finish:restart'
test "$(wc -l <"$tmp/fd4" | tr -d ' ')" = 1
test ! -s "$tmp/fd4.out"
test ! -s "$tmp/fd4.err"

run_quiet unset __UNSET__
run_quiet empty ''
run_quiet ver0 '3 0'
run_quiet missingver '3'
run_quiet badfd 'x 1'
run_quiet zerofd '0 1'
run_quiet negativefd '-3 1'
run_quiet badver '3 x'
run_quiet extra '3 1 extra'
run_quiet injection '3;echo_PWNED 1'
run_quiet redirection '3>/tmp/PWNED 1'
run_quiet unopened '99 1'
test ! -e /tmp/PWNED

if command -v dash >/dev/null 2>&1; then
	SILEO='5 1' dash "$postinst" 5>"$tmp/dash5" >"$tmp/dash.out" 2>"$tmp/dash.err"
	test "$(cat "$tmp/dash5")" = 'finish:restart'
	test ! -s "$tmp/dash.out"
	test ! -s "$tmp/dash.err"
fi

! grep -Eiq 'killall|launchctl|sbreload|ldrestart|(^|[[:space:]])(rm|cp|curl|wget)([[:space:]]|$)' "$postinst"

echo 'PASS130 Sileo dynamic-fd finish protocol: fd3/fd4 capture, malformed input silent, no dangerous commands.'
