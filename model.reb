Rebol [
	Title: "TOC diagram internal model"
	File: %model.reb
	Purpose: "Entities, edges, and-groups, tree bags. No parse, no SVG."
]

model: context [

	make-doc: does [
		make map! reduce [
			'entities make map! []
			'trees make map! []
			'errors copy []
		]
	]

	make-tree: func [kind [word!]] [
		make map! reduce [
			'kind kind
			'edges copy []
			'and-groups copy []
			'roles make map! []
			'conflicts copy []
			'injections copy []
			'trims copy []
			'obstacles copy []
			'realities copy []
			'actions copy []
			'effects copy []
		]
	]

	ensure-entity: func [
		doc [map!]
		text [string!]
		/role r [word!]
		/local e id
	][
		text: trim copy text
		e: select doc/entities text
		either e [
			if all [role r none? e/role] [e/role: r]
			e
		][
			id: rejoin ["e" 1 + length? doc/entities]
			e: make map! reduce [
				'id id
				'text text
				'role either role [r] [none]
			]
			put doc/entities text e
			e
		]
	]

	set-role: func [
		doc [map!]
		tree [map!]
		text [string!]
		role [word!]
		/local e
	][
		text: trim copy text
		e: ensure-entity/role doc text role
		put tree/roles text role
		e
	]

	add-edge: func [
		doc [map!]
		tree [map!]
		from-text [string!]
		to-text [string!]
		kind [word!]
		/assumptions ass [block!]
		/local edge
	][
		from-text: trim copy from-text
		to-text: trim copy to-text
		ensure-entity doc from-text
		ensure-entity doc to-text
		edge: make map! reduce [
			'from from-text
			'to to-text
			'kind kind
			'assumptions either assumptions [copy ass] [copy []]
		]
		append tree/edges edge
		edge
	]

	add-and-group: func [
		doc [map!]
		tree [map!]
		causes [block!]
		effect [string!]
		/local c
	][
		effect: trim copy effect
		ensure-entity doc effect
		foreach c causes [
			c: trim copy c
			ensure-entity doc c
			add-edge doc tree c effect 'sufficient
		]
		append tree/and-groups make map! reduce [
			'causes map-each x causes [trim copy x]
			'effect effect
		]
	]

	add-error: func [doc [map!] msg [string!]] [
		append doc/errors msg
	]

	tree-of: func [doc [map!] kind [word!] /local t] [
		t: select doc/trees kind
		unless t [
			t: make-tree kind
			put doc/trees kind t
		]
		t
	]

	cloud-kind?: func [kind [word!]] [
		to-logic find to-string kind "cloud"
	]

	allowed-edge: func [kind [word!] edge-kind [word!]] [
		switch/default kind [
			crt frt nbr trt [edge-kind = 'sufficient]
			cloud prt [edge-kind = 'necessary]
		] [
			either cloud-kind? kind [edge-kind = 'necessary] [false]
		]
	]

	is-need?: func [pairs [block!] text [string!] /local q] [
		foreach q pairs [if q/2 = text [return true]]
		false
	]

	validate-cloud: func [
		doc [map!]
		tree [map!]
		/local pairs goal reqs mid-up mid-dn act-up act-dn e conf ok w q p
	][
		;; "xiang yao X jiu bi xu Y" => edge from Y to X
		pairs: copy []
		foreach e tree/edges [
			if e/kind = 'necessary [
				append/only pairs reduce [e/to e/from]
			]
		]
		if empty? pairs [return false]

		goal: none
		foreach q pairs [
			w: q/1
			reqs: copy []
			foreach p pairs [if p/1 = w [append reqs p/2]]
			reqs: unique reqs
			if all [2 = length? reqs not is-need? pairs w] [
				goal: w
				break
			]
		]
		unless goal [return false]

		reqs: copy []
		foreach q pairs [if q/1 = goal [append reqs q/2]]
		reqs: unique reqs
		if 2 <> length? reqs [return false]
		mid-up: reqs/1
		mid-dn: reqs/2

		act-up: none
		act-dn: none
		foreach q pairs [
			if q/1 = mid-up [act-up: q/2]
			if q/1 = mid-dn [act-dn: q/2]
		]
		unless all [act-up act-dn] [return false]

		ok: false
		foreach conf tree/conflicts [
			if all [
				any [conf/left = act-up conf/left = act-dn]
				any [conf/right = act-up conf/right = act-dn]
				conf/left <> conf/right
			] [ok: true]
		]
		unless ok [return false]

		put tree 'cloud make map! reduce [
			'A goal
			'B mid-up
			'C mid-dn
			'D act-up
			'Dprime act-dn
		]
		set-role doc tree goal 'goal
		set-role doc tree mid-up 'requirement
		set-role doc tree mid-dn 'requirement
		set-role doc tree act-up 'action
		set-role doc tree act-dn 'action
		true
	]

	validate-tree: func [
		doc [map!]
		tree [map!]
		/local kind e
	][
		kind: tree/kind
		foreach e tree/edges [
			unless allowed-edge kind e/kind [
				add-error doc rejoin [
					"tree " to-string kind " rejects edge kind " to-string e/kind
					" (" e/from " -> " e/to ")"
				]
			]
		]
		if cloud-kind? kind [
			unless validate-cloud doc tree [
				add-error doc rejoin [
					"cloud: cannot reconstruct A/B/C/D/Dprime from edges+conflict ("
					to-string kind ")"
				]
			]
		]
		switch kind [
			prt [
				foreach o tree/obstacles [
					unless all [o/obstacle o/io] [
						add-error doc "prt: obstacle must have flipped IO"
					]
				]
			]
			trt [
				foreach e tree/edges [
					if e/kind = 'sufficient [
						unless any [
							find tree/actions e/from
							'action = select tree/roles e/from
						] [
							add-error doc rejoin [
								"trt: action not marked for [" e/from "]"
							]
						]
					]
				]
			]
		]
	]

	validate-doc: func [doc [map!] /local t] [
		foreach t values-of doc/trees [
			validate-tree doc t
		]
		empty? doc/errors
	]

	dump-json: func [doc [map!]] [
		to-json doc
	]
]
