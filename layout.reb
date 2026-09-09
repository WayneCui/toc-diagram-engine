Rebol [
	Title: "TOC diagram layout"
	File: %layout.reb
	Purpose: "Place nodes and edge anchors. No SVG."
]

layout: context [

	title-h: 48
	pad: 40
	col-gap: 48
	row-gap: 56

	char-width: func [ch [char!]] [
		either (to-integer ch) > 127 [1.0] [0.55]
	]

	text-width: func [s [string!] font-size [number!] /local w ch] [
		w: 0.0
		foreach ch s [w: w + char-width ch]
		w * font-size
	]

	wrap-text: func [
		s [string!]
		font-size [number!]
		max-w [number!]
		/local lines line w ch cw
	][
		lines: copy []
		line: copy ""
		w: 0.0
		foreach ch s [
			cw: (char-width ch) * font-size
			if all [w + cw > max-w not empty? line] [
				append lines line
				line: copy ""
				w: 0.0
			]
			append line ch
			w: w + cw
		]
		if not empty? line [append lines line]
		if empty? lines [append lines copy ""]
		lines
	]

	box-size: func [
		s [string!]
		/max-width mw [number!]
		/local fs p lines tw th max-line
	][
		fs: 13
		p: 12
		mw: any [mw 210]
		lines: wrap-text s fs mw
		max-line: 0.0
		foreach ln lines [
			tw: text-width ln fs
			if tw > max-line [max-line: tw]
		]
		th: (length? lines) * (fs + 5) + (2 * p)
		make map! reduce [
			'w max-line + (2 * p) + 8  ; badge room
			'h th
			'lines lines
			'font-size fs
			'pad p
		]
	]

	make-node: func [
		text [string!]
		role [word! none!]
		x [number!]
		y [number!]
		/badge b [string!]
		/local sz n
	][
		sz: box-size text
		h: sz/h
		if badge [h: h + 12]
		n: make map! reduce [
			'text text
			'role role
			'x x
			'y y
			'w sz/w
			'h h
			'lines sz/lines
			'font-size sz/font-size
			'cx x + (sz/w / 2.0)
			'cy y + (h / 2.0)
			'badge either badge [b] [none]
		]
		n
	]

	place: func [n [map!] x [number!] y [number!]] [
		n/x: x
		n/y: y
		n/cx: x + (n/w / 2.0)
		n/cy: y + (n/h / 2.0)
		n
	]

	find-node: func [nodes [block!] text [string!] /local n] [
		foreach n nodes [if n/text = text [return n]]
		none
	]

	role-of: func [tree [map!] text [string!]] [
		any [select tree/roles text none]
	]

	canvas: func [
		nodes [block!]
		/extra extra-w extra-h
		/local w h n
	][
		w: 200.0
		h: 200.0
		foreach n nodes [
			if (n/x + n/w + pad) > w [w: n/x + n/w + pad]
			if (n/y + n/h + pad) > h [h: n/y + n/h + pad]
		]
		if extra [
			w: w + extra-w
			h: h + extra-h
		]
		reduce [w h]
	]

	edge: func [
		from [string!] to [string!] kind [word!]
		x1 [number!] y1 [number!] x2 [number!] y2 [number!]
		/assumptions ass [block!]
		/trimmed
		/via vx [number!]
		/local m
	][
		m: make map! reduce [
			'from from 'to to 'kind kind
			'assumptions either assumptions [copy ass] [copy []]
			'trimmed to-logic trimmed
			'x1 x1 'y1 y1 'x2 x2 'y2 y2
			'via-x none
		]
		if via [m/via-x: vx]
		m
	]

	find-edge-assump: func [tree [map!] from [string!] to [string!] /local e] [
		foreach e tree/edges [
			if all [e/from = from e/to = to] [return copy e/assumptions]
		]
		copy []
	]

	and-member?: func [
		tree [map!]
		from [string!]
		to [string!]
		/local g c
	][
		foreach g tree/and-groups [
			if g/effect = to [
				foreach c g/causes [if c = from [return g]]
			]
		]
		none
	]

	find-and-mark: func [marks [block!] effect [string!] /local m] [
		foreach m marks [if m/effect = effect [return m]]
		none
	]

	;; --- cloud: A left, B/C middle, D/D' right; arrows point right ---

	of-cloud: func [
		doc [map!]
		tree [map!]
		/local c nodes edges labels inj nA nB nC nD nDp
			xA xMid xD yB yC yA mid-x mid-y assump-bd size
	][
		c: tree/cloud
		unless c [return none]
		nA: make-node/badge c/A 'goal 0 0 "A"
		nB: make-node/badge c/B 'requirement 0 0 "B"
		nC: make-node/badge c/C 'requirement 0 0 "C"
		nD: make-node/badge c/D 'action 0 0 "D"
		nDp: make-node/badge c/Dprime 'action 0 0 "D'"

		xA: pad
		xMid: xA + nA/w + 80
		xD: xMid + (max nB/w nC/w) + 130
		yB: title-h
		yC: yB + (max nB/h nD/h) + 120
		place nB xMid yB
		place nD xD yB + ((nB/h - nD/h) / 2.0)
		place nC xMid yC
		place nDp xD yC + ((nC/h - nDp/h) / 2.0)
		yA: ((nB/cy + nC/cy) / 2.0) - (nA/h / 2.0)
		place nA xA yA

		nodes: reduce [nA nB nC nD nDp]
		edges: copy []
		;; visual arrows: A ? B ? D and A ? C ? D' (necessary, read left to right)
		append/only edges edge c/A c/B 'necessary (nA/x + nA/w) nA/cy nB/x nB/cy
		append/only edges edge c/A c/C 'necessary (nA/x + nA/w) nA/cy nC/x nC/cy
		assump-bd: find-edge-assump tree c/D c/B
		append/only edges edge/assumptions c/B c/D 'necessary (nB/x + nB/w) nB/cy nD/x nD/cy assump-bd
		append/only edges edge/assumptions c/C c/Dprime 'necessary (nC/x + nC/w) nC/cy nDp/x nDp/cy find-edge-assump tree c/Dprime c/C
		append/only edges edge/assumptions c/D c/Dprime 'conflict nD/cx (nD/y + nD/h) nDp/cx nDp/y either empty? tree/conflicts [copy []] [copy tree/conflicts/1/assumptions]

		if not empty? tree/injections [
			inj: make-node tree/injections/1/text 'injection 0 0
			mid-x: (nD/cx + nDp/cx) / 2.0
			mid-y: (nD/y + nD/h + nDp/y) / 2.0
			place inj (xD + (max nD/w nDp/w) + 50) (mid-y - (inj/h / 2.0))
			append nodes inj
			append/only edges edge tree/injections/1/text c/D 'breaks inj/x inj/cy (mid-x + 24) mid-y
		]

		size: canvas nodes
		make map! reduce [
			'kind 'cloud
			'title "Evaporating Cloud"
			'nodes nodes
			'edges edges
			'labels copy []
			'and-marks copy []
			'width size/1
			'height size/2
		]
	]

	;; --- PRT: goal at top, obstacles left, IO spine ---

	of-prt: func [
		doc [map!]
		tree [map!]
		/local texts layers display nodes edges order
			x-io x-obs y n obs-node o e src dst size i layer col gutter
	][
		texts: copy []
		foreach o tree/obstacles [
			if not find texts o/io [append texts o/io]
		]
		foreach e tree/edges [
			if not find texts e/from [append texts e/from]
			if not find texts e/to [append texts e/to]
		]
		layers: layerize tree texts 'necessary
		display: reverse copy layers
		nodes: copy []
		edges: copy []
		x-io: 280
		x-obs: pad
		y: title-h
		foreach col display [
			foreach text col [
				n: make-node text any [select tree/roles text 'io] x-io y
				append nodes n
				foreach o tree/obstacles [
					if o/io = text [
						obs-node: make-node o/obstacle 'obstacle x-obs y
						place obs-node x-obs (y + ((n/h - obs-node/h) / 2.0))
						append nodes obs-node
						append/only edges edge o/obstacle text 'flip (obs-node/x + obs-node/w) obs-node/cy n/x n/cy
					]
				]
				y: y + n/h + 36
			]
		]
		gutter: 40.0
		foreach n nodes [
			unless n/role = 'obstacle [
				if (n/x + n/w + 28) > gutter [gutter: n/x + n/w + 28]
			]
		]
		foreach e tree/edges [
			if e/kind = 'necessary [
				src: find-node nodes e/from
				dst: find-node nodes e/to
				if all [src dst] [
					append/only edges edge/via e/from e/to 'spine (src/x + src/w) src/cy (dst/x + dst/w) dst/cy gutter
				]
			]
		]
		size: canvas nodes
		if (gutter + 20) > size/1 [size/1: gutter + 24]
		make map! reduce [
			'kind 'prt
			'title "Prerequisite Tree"
			'nodes nodes
			'edges edges
			'labels copy []
			'and-marks copy []
			'width size/1
			'height size/2
		]
	]

	;; --- TrT: reality | action | effect, chained ---

	of-trt: func [
		doc [map!]
		tree [map!]
		/local nodes edges y e i act eff real row-h x-r x-a x-e
			prev-eff size
	][
		nodes: copy []
		edges: copy []
		y: title-h
		x-r: pad
		x-a: 290
		x-e: 560
		i: 0
		prev-eff: none
		foreach e tree/edges [
			if e/kind = 'sufficient [
				i: i + 1
				act: make-node e/from 'action x-a y
				eff: make-node e/to 'effect x-e y
				real: none
				if all [not empty? tree/realities i <= length? tree/realities] [
					real: make-node tree/realities/:i 'reality x-r y
				]
				row-h: max act/h eff/h
				if real [row-h: max row-h real/h]
				place act x-a (y + ((row-h - act/h) / 2.0))
				place eff x-e (y + ((row-h - eff/h) / 2.0))
				append nodes act
				append nodes eff
				if real [
					place real x-r (y + ((row-h - real/h) / 2.0))
					append nodes real
					append/only edges edge real/text act/text 'context (real/x + real/w) real/cy act/x act/cy
				]
				append/only edges edge/assumptions act/text eff/text 'sufficient (act/x + act/w) act/cy eff/x eff/cy copy e/assumptions
				if prev-eff [
					append/only edges edge prev-eff/text either real [real/text] [act/text] 'seq prev-eff/cx (prev-eff/y + prev-eff/h) either real [real/cx] [act/cx] either real [real/y] [act/y]
				]
				prev-eff: eff
				y: y + row-h + 44
			]
		]
		size: canvas nodes
		make map! reduce [
			'kind 'trt
			'title "Transition Tree"
			'nodes nodes
			'edges edges
			'labels copy []
			'and-marks copy []
			'width size/1
			'height size/2
		]
	]

	;; --- CRT / FRT / NBR ---

	trim-injections: func [tree [map!] /local out t] [
		out: copy []
		foreach t tree/trims [append out t/injection]
		out
	]

	collect-texts: func [tree [map!] skip-list [block!] /local out e o t] [
		out: copy []
		foreach e tree/edges [
			if all [not find out e/from not find skip-list e/from] [append out e/from]
			if all [not find out e/to not find skip-list e/to] [append out e/to]
		]
		foreach t words-of tree/roles [
			if all [not find out t not find skip-list t] [append out t]
		]
		foreach t tree/injections [
			if all [not find out t/text not find skip-list t/text] [append out t/text]
		]
		out
	]

	layerize: func [
		tree [map!]
		texts [block!]
		edge-kind [word!]
		/local indeg e layers layer n remain next-remain min-deg
	][
		indeg: make map! []
		foreach n texts [put indeg n 0]
		foreach e tree/edges [
			if all [e/kind = edge-kind find texts e/to] [
				put indeg e/to 1 + any [select indeg e/to 0]
			]
		]
		remain: copy texts
		layers: copy []
		while [not empty? remain] [
			layer: copy []
			foreach n remain [
				if 0 = any [select indeg n 0] [append layer n]
			]
			if empty? layer [
				min-deg: 9999
				foreach n remain [
					if (select indeg n) < min-deg [min-deg: select indeg n]
				]
				foreach n remain [
					if (select indeg n) = min-deg [
						append layer n
						break
					]
				]
			]
			append/only layers layer
			next-remain: copy []
			foreach n remain [
				unless find layer n [append next-remain n]
			]
			foreach n layer [
				foreach e tree/edges [
					if all [e/kind = edge-kind e/from = n find next-remain e/to] [
						put indeg e/to (select indeg e/to) - 1
					]
				]
			]
			remain: next-remain
		]
		layers
	]

	index-of: func [blk [block!] item /local i] [
		i: 1
		foreach x blk [
			if x = item [return i]
			i: i + 1
		]
		none
	]

	bary-sort: func [
		tree [map!]
		display [block!]  ; layers top-to-bottom, each a block of texts
		/local pass li layer scores n sum cnt e other idx order
	][
		repeat pass 6 [
			li: 1
			while [li <= length? display] [
				layer: display/:li
				if (length? layer) > 1 [
					scores: copy []
					foreach n layer [
						sum: 0.0
						cnt: 0
						foreach e tree/edges [
							if e/kind = 'sufficient [
								other: none
								if e/from = n [other: e/to]
								if e/to = n [other: e/from]
								if other [
									idx: none
									if li > 1 [idx: index-of display/(li - 1) other]
									if all [none? idx li < length? display] [
										idx: index-of display/(li + 1) other
									]
									if idx [
										sum: sum + idx
										cnt: cnt + 1
									]
								]
							]
						]
						append scores either cnt > 0 [sum / cnt] [index-of layer n]
					]
					order: copy []
					repeat k length? layer [
						append order scores/:k
						append order layer/:k
					]
					sort/skip order 2
					clear layer
					j: 2
					while [j <= length? order] [
						append layer order/:j
						j: j + 2
					]
				]
				li: li + 1
			]
		]
		display
	]

	of-dag: func [
		doc [map!]
		tree [map!]
		title [string!]
		/local skip texts layers display nodes edges
			x y max-h col n e src dst is-trim trimmed
			and-marks g size row-w max-row gutter
			cut-node inj-n t m
	][
		skip: trim-injections tree
		texts: collect-texts tree skip
		if empty? texts [return none]
		layers: layerize tree texts 'sufficient
		display: bary-sort tree reverse copy layers
		nodes: copy []
		gutter: 36.0
		y: title-h
		max-row: 0.0
		foreach col display [
			row-w: 0.0
			foreach text col [
				n: make-node text role-of tree text 0 0
				row-w: row-w + n/w + col-gap
			]
			if row-w > 0 [row-w: row-w - col-gap]
			if row-w > max-row [max-row: row-w]
		]
		foreach col display [
			x: gutter + pad + ((max-row - 0) / 2.0)
			;; recompute row width then center
			row-w: 0.0
			foreach text col [
				n: box-size text
				row-w: row-w + n/w + col-gap
			]
			if row-w > 0 [row-w: row-w - col-gap]
			x: gutter + pad
			max-h: 0
			foreach text col [
				n: make-node text role-of tree text x y
				append nodes n
				x: x + n/w + col-gap
				if n/h > max-h [max-h: n/h]
			]
			y: y + max-h + row-gap
		]
		and-marks: copy []
		foreach g tree/and-groups [
			mark-and nodes and-marks g
		]
		edges: copy []
		trimmed: copy []
		foreach t tree/trims [
			append/only trimmed reduce [t/from t/to]
		]
		foreach e tree/edges [
			if e/kind = 'sufficient [
				src: find-node nodes e/from
				dst: find-node nodes e/to
				if all [src dst] [
					is-trim: to-logic find/only trimmed reduce [e/from e/to]
					m: none
					if and-member? tree e/from e/to [
						m: find-and-mark and-marks e/to
					]
					either all [m src/y > m/y] [
						either is-trim [
							append/only edges edge/trimmed/assumptions e/from e/to 'cut src/cx src/y m/x (m/y + m/ry) copy e/assumptions
						][
							append/only edges edge/assumptions e/from e/to 'sufficient src/cx src/y m/x (m/y + m/ry) copy e/assumptions
						]
					][
						either src/y > dst/y [
							either is-trim [
								append/only edges edge/trimmed/assumptions e/from e/to 'cut src/cx src/y dst/cx (dst/y + dst/h) copy e/assumptions
							][
								append/only edges edge/assumptions e/from e/to 'sufficient src/cx src/y dst/cx (dst/y + dst/h) copy e/assumptions
							]
						][
							append/only edges edge/via e/from e/to 'back src/x src/cy dst/x dst/cy gutter
						]
					]
				]
			]
		]
		foreach m and-marks [
			dst: find-node nodes m/effect
			if dst [
				append/only edges edge "*" m/effect 'sufficient m/x (m/y - m/ry) dst/cx (dst/y + dst/h)
			]
		]
		;; place trim injections beside the cut
		foreach t tree/trims [
			src: find-node nodes t/from
			dst: find-node nodes t/to
			inj-n: make-node t/injection 'injection 0 0
			either all [src dst] [
				place inj-n (max src/x + src/w dst/x + dst/w) + 40 ((src/y + dst/y) / 2.0)
			][
				place inj-n (max-row + pad + 80) y
			]
			append nodes inj-n
			if all [src dst] [
				append/only edges edge t/injection t/from 'breaks inj-n/x inj-n/cy ((src/cx + dst/cx) / 2.0) ((src/y + dst/y + dst/h) / 2.0)
			]
		]
		size: canvas nodes
		make map! reduce [
			'kind tree/kind
			'title title
			'nodes nodes
			'edges edges
			'labels copy []
			'and-marks and-marks
			'width size/1
			'height size/2
		]
	]

	mark-and: func [nodes [block!] marks [block!] g [map!] /local causes n mx my t effect min-top] [
		causes: copy []
		foreach t g/causes [
			n: find-node nodes t
			if n [append causes n]
		]
		if (length? causes) < 2 [exit]
		effect: find-node nodes g/effect
		;; sit under the effect, not at the x-midpoint of possibly distant causes
		either effect [
			mx: effect/cx
			my: effect/y + effect/h + 16
			min-top: causes/1/y
			foreach n causes [if n/y < min-top [min-top: n/y]]
			if my > (min-top - 14) [my: (effect/y + effect/h + min-top) / 2.0]
		][
			mx: 0.0
			foreach n causes [mx: mx + n/cx]
			mx: mx / length? causes
			my: causes/1/y - 18
		]
		append/only marks make map! reduce [
			'x mx
			'y my
			'rx 20
			'ry 9
			'effect g/effect
		]
	]

	of: func [
		doc [map!]
		kind [word!]
		/local tree
	][
		tree: select doc/trees kind
		unless tree [return none]
		switch/default kind [
			cloud [of-cloud doc tree]
			prt [of-prt doc tree]
			trt [of-trt doc tree]
			crt [of-dag doc tree "Current Reality Tree"]
			frt [of-dag doc tree "Future Reality Tree"]
			nbr [of-dag doc tree "Negative Branch"]
		] [none]
	]
]
