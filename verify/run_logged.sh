# Sourced by the workflow: logged <title> <command…> runs the command with its output in a log, and on
# failure turns the log's tail into an annotation, which anyone can read without signing in.
logged() {
  title=$1; shift
  log=$(mktemp)
  if "$@" > "$log" 2>&1; then tail -n 30 "$log"; return 0; fi
  tail -n 60 "$log"
  echo "::error title=$title::$(grep -v -E '^(warning:|\s*$)' "$log" | tail -c 2500 | tr '\n' ' ' | sed 's/%/%25/g')"
  return 1
}
