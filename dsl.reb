Rebol [
	Title: "TOC Chinese causal-sentence DSL parser"
	File: %dsl.reb
	Purpose: "Parse .toc UTF-8 text into model document."
]

do %model.reb
do %keywords.reb

dsl: context [

	tree-headers: none

	init: does [
		tree-headers: make map! reduce [
			toc-kw/hdr-crt 'crt
			toc-kw/hdr-cloud 'cloud
			toc-kw/hdr-frt 'frt
			toc-kw/hdr-nbr 'nbr
			toc-kw/hdr-nbr-alt 'nbr
			toc-kw/hdr-prt 'prt
			toc-kw/hdr-trt 'trt
		]
	]

	starts-with?: func [s [string!] prefix [string!]] [
		all [
			(length? s) >= length? prefix
			prefix = copy/part s length? prefix
		]
	]

	contains?: func [s [string!] frag [string!]] [
		to-logic find s frag
	]

	extract-quoted: func [
		s [string!]
		/local out p a b
	][
		out: copy []
		p: s
		while [p: find p toc-kw/quote-open] [
			p: next p
			a: p
			b: find p toc-kw/quote-close
			unless b [break]
			append out trim copy/part a b
			p: next b
		]
		out
	]

	split-sections: func [
		text [string!]
		/local lines line sections cur-kind buf kind
	][
		unless tree-headers [init]
		lines: split text #"^/"
		sections: copy []
		cur-kind: none
		buf: copy ""
		foreach line lines [
			line: trim copy line
			if any [empty? line starts-with? line ";;" starts-with? line "#"] [
				continue
			]
			kind: select tree-headers line
			either kind [
				if cur-kind [
					append/only sections reduce [cur-kind trim buf]
				]
				cur-kind: kind
				buf: copy ""
			][
				if cur-kind [
					append buf line
					append buf #" "
				]
			]
		]
		if cur-kind [
			append/only sections reduce [cur-kind trim buf]
		]
		sections
	]

	split-units: func [
		body [string!]
		/local out i ch start n unit
	][
		out: copy []
		body: trim copy body
		if empty? body [return out]
		start: 1
		n: length? body
		i: 1
		while [i <= n] [
			ch: body/:i
			;; Oldes r3: char! "=" is unreliable for non-ASCII; use "=="
			if ch == toc-kw/period [
				unit: trim copy/part at body start (i - start + 1)
				if not empty? unit [append out unit]
				start: i + 1
			]
			i: i + 1
		]
		if start <= n [
			unit: trim copy at body start
			if not empty? unit [append out unit]
		]
		out
	]

	parse-unit: func [
		doc [map!]
		tree [map!]
		unit [string!]
		/local qs
	][
		unit: trim copy unit
		if empty? unit [return true]
		if toc-kw/period == last unit [
			unit: copy/part unit ((length? unit) - 1)
		]
		unit: trim unit
		if empty? unit [return true]

		qs: extract-quoted unit

		case [
			starts-with? unit toc-kw/ude [
				unless 1 = length? qs [
					model/add-error doc rejoin ["ude needs 1 quote: " unit]
					return false
				]
				model/set-role doc tree qs/1 'ude
				return true
			]
			starts-with? unit toc-kw/core [
				unless 1 = length? qs [
					model/add-error doc rejoin ["core needs 1 quote: " unit]
					return false
				]
				model/set-role doc tree qs/1 'core
				return true
			]
			starts-with? unit toc-kw/de [
				unless 1 = length? qs [
					model/add-error doc rejoin ["de needs 1 quote: " unit]
					return false
				]
				model/set-role doc tree qs/1 'de
				return true
			]
			starts-with? unit toc-kw/action [
				unless 1 = length? qs [
					model/add-error doc rejoin ["action needs 1 quote: " unit]
					return false
				]
				model/set-role doc tree qs/1 'action
				append tree/actions qs/1
				return true
			]
			starts-with? unit toc-kw/reality [
				unless 1 = length? qs [
					model/add-error doc rejoin ["reality needs 1 quote: " unit]
					return false
				]
				model/set-role doc tree qs/1 'reality
				append tree/realities qs/1
				return true
			]
			starts-with? unit toc-kw/effect [
				unless 1 = length? qs [
					model/add-error doc rejoin ["effect needs 1 quote: " unit]
					return false
				]
				model/set-role doc tree qs/1 'effect
				append tree/effects qs/1
				return true
			]
			all [starts-with? unit toc-kw/obstacle contains? unit toc-kw/flip-to] [
				unless 2 = length? qs [
					model/add-error doc rejoin ["obstacle/io needs 2 quotes: " unit]
					return false
				]
				model/set-role doc tree qs/1 'obstacle
				model/set-role doc tree qs/2 'io
				append tree/obstacles make map! reduce [
					'obstacle qs/1
					'io qs/2
				]
				return true
			]
			all [starts-with? unit toc-kw/injection contains? unit toc-kw/break-assump] [
				unless 2 = length? qs [
					model/add-error doc rejoin ["injection/break needs 2 quotes: " unit]
					return false
				]
				model/set-role doc tree qs/1 'injection
				append tree/injections make map! reduce [
					'text qs/1
					'breaks qs/2
				]
				return true
			]
			all [starts-with? unit toc-kw/injection contains? unit toc-kw/trim] [
				unless 3 = length? qs [
					model/add-error doc rejoin ["trim needs 3 quotes: " unit]
					return false
				]
				model/set-role doc tree qs/1 'injection
				append tree/trims make map! reduce [
					'injection qs/1
					'from qs/2
					'to qs/3
				]
				return true
			]
			starts-with? unit toc-kw/injection [
				unless 1 = length? qs [
					model/add-error doc rejoin ["injection needs 1 quote: " unit]
					return false
				]
				model/set-role doc tree qs/1 'injection
				append tree/injections make map! reduce [
					'text qs/1
					'breaks none
				]
				return true
			]
		]

		if all [
			contains? unit toc-kw/conflict
			contains? unit toc-kw/and-conj
			2 <= length? qs
		] [
			append tree/conflicts make map! reduce [
				'left qs/1
				'right qs/2
				'assumptions either 3 <= length? qs [
					copy next next qs
				] [copy []]
			]
			model/ensure-entity doc qs/1
			model/ensure-entity doc qs/2
			return true
		]

		if starts-with? unit toc-kw/if-kw [
			parse-sufficient doc tree unit qs
			return true
		]

		if starts-with? unit toc-kw/want [
			parse-necessary doc tree unit qs
			return true
		]

		model/add-error doc rejoin ["unrecognized: " unit]
		false
	]

	has-connector?: func [
		"True if frag appears outside ?? quotes."
		s [string!]
		frag [string!]
		/local i n depth ch p
	][
		;; Scan: when depth=0, search for frag
		i: 1
		n: length? s
		depth: 0
		while [i <= n] [
			ch: s/:i
			case [
				ch == toc-kw/quote-open [depth: depth + 1]
				ch == toc-kw/quote-close [depth: depth - 1]
				depth = 0 [
					if all [
						(i + (length? frag) - 1) <= n
						frag = copy/part at s i length? frag
					] [return true]
				]
			]
			i: i + 1
		]
		false
	]

	parse-sufficient: func [
		doc [map!]
		tree [map!]
		unit [string!]
		qs [block!]
		/local causes effect assumptions e
	][
		unless contains? unit toc-kw/then-kw [
			model/add-error doc rejoin ["if without then: " unit]
			exit
		]
		if has-connector? unit toc-kw/and-kw [
			either has-connector? unit toc-kw/because [
				unless (length? qs) >= 3 [
					model/add-error doc rejoin ["and/because quotes short: " unit]
					exit
				]
				effect: qs/(length? qs - 1)
				assumptions: reduce [last qs]
				causes: copy/part qs ((length? qs) - 2)
			][
				unless (length? qs) >= 3 [
					model/add-error doc rejoin ["if-and-then needs 3+ quotes: " unit]
					exit
				]
				effect: last qs
				assumptions: copy []
				causes: copy/part qs ((length? qs) - 1)
			]
			model/add-and-group doc tree causes effect
			if not empty? assumptions [
				foreach e tree/edges [
					if all [e/to = effect find causes e/from] [
						append e/assumptions assumptions/1
					]
				]
			]
			exit
		]
		either has-connector? unit toc-kw/because [
			unless (length? qs) >= 3 [
				model/add-error doc rejoin ["if-then-because needs 3 quotes: " unit]
				exit
			]
			model/add-edge/assumptions doc tree qs/1 qs/2 'sufficient reduce [qs/3]
		][
			unless (length? qs) >= 2 [
				model/add-error doc rejoin ["if-then needs 2 quotes: " unit]
				exit
			]
			model/add-edge doc tree qs/1 qs/2 'sufficient
		]
	]

	parse-necessary: func [
		doc [map!]
		tree [map!]
		unit [string!]
		qs [block!]
		/local want need
	][
		unless contains? unit toc-kw/must [
			model/add-error doc rejoin ["want without must: " unit]
			exit
		]
		either has-connector? unit toc-kw/because [
			unless (length? qs) >= 3 [
				model/add-error doc rejoin ["want-must-because needs 3 quotes: " unit]
				exit
			]
			want: qs/1
			need: qs/2
			model/add-edge/assumptions doc tree need want 'necessary reduce [qs/3]
		][
			unless (length? qs) >= 2 [
				model/add-error doc rejoin ["want-must needs 2 quotes: " unit]
				exit
			]
			want: qs/1
			need: qs/2
			model/add-edge doc tree need want 'necessary
		]
	]

	parse-text: func [
		text [string!]
		/local doc sections sec kind body units u tree
	][
		unless tree-headers [init]
		doc: model/make-doc
		sections: split-sections text
		if empty? sections [
			model/add-error doc "no tree sections found"
			return doc
		]
		foreach sec sections [
			kind: sec/1
			body: sec/2
			tree: model/tree-of doc kind
			units: split-units body
			foreach u units [
				parse-unit doc tree u
			]
		]
		model/validate-doc doc
		doc
	]

	parse-file: func [path [file! string!] /local p root] [
		p: either file? path [path] [to-rebol-file path]
		parse-text to-string read/binary p
	]
]

dsl/init
