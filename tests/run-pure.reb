Rebol [
	Title: "Pure tests for TOC diagram engine"
	File: %run-pure.reb
]

root: first split-path system/options/script
change-dir first split-path root

do %dsl.reb
do %layout.reb
do %render.reb

pass: 0
fail: 0

assert-true: func [label [string!] cond] [
	either cond [
		pass: pass + 1
		print rejoin ["  PASS " label]
	][
		fail: fail + 1
		print rejoin ["  FAIL " label]
	]
]

assert-eq: func [label [string!] expected actual] [
	either expected = actual [
		pass: pass + 1
		print rejoin ["  PASS " label]
	][
		fail: fail + 1
		print rejoin ["  FAIL " label " expected=" mold expected " actual=" mold actual]
	]
]

print "== cloud golden =="
doc: dsl/parse-file %examples/cloud-only.toc
assert-true "cloud no errors" empty? doc/errors
assert-true "cloud reconstructed" not none? doc/trees/cloud/cloud
assert-eq "cloud edges" 4 length? doc/trees/cloud/edges
lay: layout/of doc 'cloud
assert-true "cloud layout" not none? lay
assert-eq "cloud 5+ boxes" true (length? lay/nodes) >= 5
svg: render/svg lay
assert-true "cloud svg has Evaporating" to-logic find svg "Evaporating"
assert-true "cloud svg has A label" to-logic find svg ">A<"

print "== reject wrong arrow on CRT =="
doc: dsl/parse-file %examples/bad-mix.toc
assert-true "bad-mix has errors" not empty? doc/errors

print "== AND group =="
doc: dsl/parse-file %examples/and-group.toc
assert-true "and no errors" empty? doc/errors
assert-eq "and group count" 1 length? doc/trees/crt/and-groups
assert-eq "and edges" 2 length? doc/trees/crt/edges
lay: layout/of doc 'crt
svg: render/svg lay
assert-true "and mark in svg" to-logic find svg "AND"

print "== firefighting six trees =="
doc: dsl/parse-file %examples/firefighting.toc
assert-true "ff no errors" empty? doc/errors
foreach k [crt cloud frt nbr prt trt] [
	assert-true rejoin ["has " k] not none? select doc/trees k
	lay: layout/of doc k
	assert-true rejoin ["layout " k] not none? lay
	svg: render/svg lay
	assert-true rejoin ["svg " k] (length? svg) > 100
]

print "== char == quirk guard =="
assert-true "period strict" #"^(3002)" == toc-kw/period
assert-true "non-ascii not soft-equal for logic" not (#"覘" == toc-kw/period)

print "== layout invariants =="
doc: dsl/parse-file %examples/firefighting.toc
lay: layout/of doc 'prt
top-io: none
bot-io: none
foreach n lay/nodes [
	if n/role = 'io [
		if any [none? top-io n/y < top-io/y] [top-io: n]
		if any [none? bot-io n/y > bot-io/y] [bot-io: n]
	]
]
assert-true "prt has io nodes" not none? top-io
assert-true "prt goal above first need" top-io/y < bot-io/y
lay: layout/of doc 'trt
assert-true "trt chains reality" (length? lay/edges) > 3
lay: layout/of doc 'cloud
max-x: 0
foreach n lay/nodes [if (n/x + n/w) > max-x [max-x: n/x + n/w]]
assert-true "cloud canvas fits nodes" lay/width >= max-x
lay: layout/of doc 'crt
assert-true "crt has and marks" not empty? lay/and-marks

print rejoin ["^/Result: " pass " passed, " fail " failed"]
either fail = 0 [quit/return 0] [quit/return 1]
