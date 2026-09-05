#!/usr/bin/env bash
# Repo consistency check. Run before committing.
set -uo pipefail
cd "$(dirname "$0")/.."
fail=0

echo "== compose files validate =="
for d in stacks/*/; do
  n=$(basename "$d")
  if [ -f "$d/.env.example" ]; then
    ( cd "$d" && cp .env.example .env && docker compose config -q ) \
      && echo "  ok   $n" || { echo "  FAIL $n"; fail=1; }
    rm -f "$d/.env"
  else
    # No .env by design (values come from Dockhand's environment editor).
    # Validate with throwaway values for the required ${VAR:?} placeholders.
    ( cd "$d" && DDNS_HOST=x.example.com GLUETUN_STACK_DIR_HOST=/tmp \
        DOCKHAND_STACK=gluetun DOCKHAND_NETWORK=net DOCKHAND_ENV_NAME=env \
        docker compose config -q ) \
      && echo "  ok   $n (no .env by design)" || { echo "  FAIL $n"; fail=1; }
  fi
done

echo "== inlined compose matches stacks/ =="
for n in aiostreams aiometadata jikan aiomanager gluetun gluetun-ddns wireguard beszel; do
  awk '/^```yaml$/{f=1;next} /^```$/{if(f)exit} f' "docs/$n.md" > /tmp/_inline.yaml
  diff -q /tmp/_inline.yaml "stacks/$n/compose.yaml" >/dev/null \
    && echo "  ok   $n" || { echo "  DRIFT $n"; diff "/tmp/_inline.yaml" "stacks/$n/compose.yaml"; fail=1; }
done

echo "== inlined .env matches stacks/ =="
for n in aiostreams aiometadata jikan aiomanager gluetun wireguard beszel; do
  awk '/^```dotenv$/{f=1;next} /^```$/{if(f)exit} f' "docs/$n.md" > /tmp/_inline.env
  diff -q /tmp/_inline.env "stacks/$n/.env.example" >/dev/null \
    && echo "  ok   $n" || { echo "  DRIFT $n"; diff "/tmp/_inline.env" "stacks/$n/.env.example"; fail=1; }
done
rm -f /tmp/_inline.yaml /tmp/_inline.env

echo "== no banned sections =="
if grep -rlnE '^## (Gotchas|Managing the stack|Troubleshooting|Requirements|What you)' docs/ 2>/dev/null; then
  echo "  FAIL: banned section above"; fail=1
else
  echo "  ok   none"
fi

echo "== no manual network creation =="
if grep -rn "docker network create" docs/ 2>/dev/null; then
  echo "  FAIL: stacks create their own networks now"; fail=1
else
  echo "  ok   none"
fi

echo "== no real secrets =="
if grep -rnEi '(api[_-]?key|secret|password|token)\s*[=:]\s*[A-Za-z0-9/+_-]{20,}' \
     --include='*.yaml' --include='*.example' --include='*.md' . \
     | grep -viE 'CHANGEME|CHANGE_ME|example\.com|openssl|<|\$\{|paste the|your-'; then
  echo "  FAIL: possible secret above"; fail=1
else
  echo "  ok   none found"
fi

echo "== internal links resolve =="
while IFS= read -r line; do
  f="${line%%:*}"; rest="${line#*:}"
  for t in $(grep -oE '\]\([^)#][^)]*\.md[^)]*\)' <<<"$rest" | sed 's/](\(.*\))/\1/' | cut -d'#' -f1); do
    p="$(cd "$(dirname "$f")" && cd "$(dirname "$t")" 2>/dev/null && pwd)/$(basename "$t")"
    [ -f "$p" ] || { echo "  MISSING $f -> $t"; fail=1; }
  done
done < <(grep -rn '](.*\.md' --include='*.md' . 2>/dev/null)
[ $fail -eq 0 ] && echo "  ok   all resolve"

exit $fail
