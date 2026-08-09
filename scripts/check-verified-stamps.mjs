#!/usr/bin/env node
// check-verified-stamps.mjs — keep dated pages honest.
//
// Some pages document behaviour that lives outside a stable, documented
// contract (third-party endpoints, client internals, provider quirks). Those
// carry a frontmatter stamp:
//
//   verified:
//     claudeCode: '2.1.226'
//     date: '2026-08-09'
//
// A stamp nobody checks is decoration, so this reports when a page is old
// enough that its claims can no longer be trusted. The point is not to punish
// age — it is to force a re-read, or a deletion. A page that cannot be
// re-verified should be removed, not left to mislead.
//
// Usage: node scripts/check-verified-stamps.mjs [--warn-days N] [--fail-days N]
//                                               [--min-stamped N]
import { readdir, readFile } from 'node:fs/promises'
import { fileURLToPath } from 'node:url'
import { join, relative } from 'node:path'

// fileURLToPath, not .pathname: the latter is percent-encoded, so a checkout in
// a directory with a space resolves to a path that does not exist.
const ROOT = fileURLToPath(new URL('..', import.meta.url))
const DOCS = join(ROOT, 'docs')

const arg = (name, fallback) => {
  const i = process.argv.indexOf(name)
  if (i === -1) return fallback
  const n = Number(process.argv[i + 1])
  return Number.isFinite(n) ? n : fallback
}
const WARN_DAYS = arg('--warn-days', 30)
const FAIL_DAYS = arg('--fail-days', 90)
// A checker whose "nothing to check" and "all clear" outputs are identical is
// not a checker. Every fail-open path in the parser converges on zero stamps.
const MIN_STAMPED = arg('--min-stamped', 1)

async function* markdownFiles(dir) {
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    if (entry.name.startsWith('.')) continue
    const full = join(dir, entry.name)
    if (entry.isDirectory()) yield* markdownFiles(full)
    else if (entry.name.endsWith('.md')) yield full
  }
}

// Minimal frontmatter read: enough for `verified.date`, no YAML dependency.
// Blank lines inside the block are tolerated, and the child keys must sit at
// the block's own indent — otherwise a `date:` nested one level deeper wins
// over the real one.
function verifiedStamp(source) {
  const fm = source.match(/^---\r?\n([\s\S]*?)\r?\n---/)
  if (!fm) return null
  const block = fm[1].match(/^verified:[ \t]*\r?\n((?:(?:[ \t]+.*)?(?:\r?\n|$))*)/m)
  if (!block) return null

  const lines = block[1].split(/\r?\n/).filter((l) => l.trim() !== '')
  if (!lines.length) return null
  const indent = lines[0].match(/^[ \t]*/)[0]
  const own = lines.filter((l) => l.startsWith(indent) && !/^[ \t]/.test(l.slice(indent.length)))

  const find = (key) => {
    for (const line of own) {
      const m = line.slice(indent.length).match(new RegExp(`^${key}:[ \\t]*['"]?([^'"\\s]+)['"]?`))
      if (m) return m[1]
    }
    return null
  }
  const date = find('date')
  return date ? { date, version: find('claudeCode') ?? 'unspecified' } : null
}

// Compare calendar days in UTC on both sides. Mixing a local `new Date()`
// against a UTC-midnight parse makes a contributor east of UTC fail for
// stamping today's date.
const t = new Date()
const todayUTC = Date.UTC(t.getUTCFullYear(), t.getUTCMonth(), t.getUTCDate())

let warnings = 0
let failures = 0
let stamped = 0

for await (const file of markdownFiles(DOCS)) {
  const stamp = verifiedStamp(await readFile(file, 'utf8'))
  if (!stamp) continue
  stamped++

  const rel = relative(ROOT, file)
  const parsed = new Date(`${stamp.date}T00:00:00Z`)

  if (Number.isNaN(parsed.getTime())) {
    console.error(`FAIL  ${rel} — verified.date is not a YYYY-MM-DD date: ${stamp.date}`)
    failures++
    continue
  }

  const ageDays = Math.floor((todayUTC - parsed.getTime()) / 86_400_000)
  if (ageDays < 0) {
    console.error(`FAIL  ${rel} — verified.date is in the future (${stamp.date})`)
    failures++
  } else if (ageDays >= FAIL_DAYS) {
    console.error(
      `FAIL  ${rel} — last verified ${ageDays} days ago against Claude Code ${stamp.version}. ` +
        `Re-verify and update the stamp, or delete the page.`
    )
    failures++
  } else if (ageDays >= WARN_DAYS) {
    console.error(`WARN  ${rel} — last verified ${ageDays} days ago (stale at ${FAIL_DAYS})`)
    warnings++
  } else {
    console.log(`ok    ${rel} — verified ${ageDays} days ago against Claude Code ${stamp.version}`)
  }
}

if (stamped < MIN_STAMPED) {
  console.error(
    `FAIL  found ${stamped} stamped page(s), expected at least ${MIN_STAMPED} — ` +
      `the frontmatter format probably drifted and this check is silently passing.`
  )
  failures++
}

console.log(
  `\n${stamped} stamped page(s): ${failures} failing, ${warnings} warning, ` +
    `thresholds ${WARN_DAYS}/${FAIL_DAYS} days.`
)
process.exit(failures > 0 ? 1 : 0)
