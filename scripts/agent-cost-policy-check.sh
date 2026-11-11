#!/usr/bin/env bash
# Checks the allow/deny rules of scripts/agent-cost.sh (--print-policy) against commands the measured AI must or must not
# be able to run. A command may run when a deny rule matches none and an allow rule matches (Claude Code: deny wins).
# Rules are matched as shell globs, `:*` meaning "this prefix, then anything"; this approximates the CLI's matcher
# and errs on the permissive side, so a pass here means no listed bypass gets through. Spends nothing.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
policy="$("$here/agent-cost.sh" --print-policy)" || exit 1

matches() {  # $1 rule body (inside Bash(...)), $2 command
    local rule="$1" cmd="$2"
    case "$rule" in
        *:\*) [[ "$cmd" == "${rule%:\*}" || "$cmd" == "${rule%:\*} "* ]] ;;
        *) [[ "$cmd" == $rule ]] ;;
    esac
}
permitted() {
    local kind rule body denied_hit=0 allowed_hit=0
    while read -r kind rule; do
        body="${rule#Bash(}"; body="${body%)}"
        if matches "$body" "$1"; then [ "$kind" = deny ] && denied_hit=1 || allowed_hit=1; fi
    done <<< "$policy"
    [ $denied_hit -eq 0 ] && [ $allowed_hit -eq 1 ]
}

fail=0
check() {  # $1 yes|no, $2 command
    if permitted "$2"; then got=yes; else got=no; fi
    if [ "$got" != "$1" ]; then echo "FAIL: expected $1 for: $2"; fail=1; fi
}
for c in "factoria call play.auto" "factoria call scene.import_ascii @levels/level1.json" "factoria call scene.format '{}'" \
         "factoria call game.state" "factoria call script.trace '{}'" "factoria call skills.read x" "factoria call docs.search x" \
         "factoria test" "factoria run" "factoria new demo" "factoria call project.validate" \
         "factoria new demo --template 2d-platformer" "factoria new ." "factoria screenshot shots/a.png" \
         "factoria call game.screenshot '{\"path\":\"shots/a.png\"}'" "factoria call scene.import_ascii @levels/level1.json"; do check yes "$c"; done
for c in "factoria call --batch '[{\"command\":\"feedback.share\"}]'" "factoria call --json feedback.share" \
         "factoria call \"feedback.share\"" "factoria call 'feedback.share'" "factoria call -p . scene.list" \
         "factoria call --project . play.auto" "factoria call feedback.share" "factoria call ai.run '{}'" \
         "factoria call engine.update_status" "factoria call skills.new" "factoria call setup.x" \
         "factoria call scene.list --batch '[]'" "factoria call project.export" "factoria call publish.x" \
         "factoria feedback add" "factoria setup launcher" "factoria ai run" "factoria editor" "factoria export" \
         "factoria call image.generate" "factoria call fs.write" "rm -rf x" "curl http://x"; do check no "$c"; done
# Paths outside the work folder (absolute, home, parent), on the command line and inside a JSON argument or an @file.
for c in "factoria new /tmp/x" "factoria new demo /tmp/x" "factoria new ~/x" "factoria new demo ~/x" "factoria new ../x" "factoria new demo ../x" \
         "factoria new .." "factoria new demo .." "factoria screenshot /tmp/a.png" "factoria screenshot shots/a.png ../b.png" \
         "factoria call game.screenshot '{\"path\":\"/tmp/a.png\"}'" "factoria call game.screenshot '{\"path\": \"/tmp/a.png\"}'" \
         "factoria call game.screenshot '{\"path\":\"../../a.png\"}'" "factoria call game.screenshot '{\"path\":\"~/a.png\"}'" \
         "factoria call game.screenshot {\\\"path\\\":\\\"/tmp/a.png\\\"}" "factoria call scene.import_ascii @/etc/passwd" \
         "factoria call scene.import_ascii @../x.json" "factoria call game.screenshot '{\"path\":\"a\",\"x\":\"/tmp\"}'"; do check no "$c"; done
[ $fail -eq 0 ] && echo "agent-cost policy: ok"
exit $fail
