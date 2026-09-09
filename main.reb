Rebol [
	Title: "TOC diagram engine CLI"
	File: %main.reb
	Purpose: "render <file.toc> --out <dir>"
]

root: first split-path system/options/script
change-dir root

do %dsl.reb
do %layout.reb
do %render.reb

cli: context [

	usage: does [
		print "Usage: r3 main.reb render <file.toc> --out <dir>"
		print "       r3 main.reb parse <file.toc>          ; print errors / edge counts"
	]

	ensure-dir: func [d [file!]] [
		unless exists? d [make-dir/deep d]
	]

	kind-filename: func [kind [word!]] [
		switch/default kind [
			crt [%crt.svg]
			cloud [%cloud.svg]
			frt [%frt.svg]
			nbr [%nbr.svg]
			prt [%prt.svg]
			trt [%trt.svg]
		] [rejoin [to-string kind %.svg]]
	]

	cmd-parse: func [path [file!] /local doc t] [
		doc: dsl/parse-file path
		either empty? doc/errors [
			print "OK"
			foreach t words-of doc/trees [
				print rejoin [
					"  " t ": edges=" length? doc/trees/:t/edges
					" roles=" length? words-of doc/trees/:t/roles
				]
			]
		][
			print "ERRORS:"
			foreach e doc/errors [print rejoin ["  - " e]]
			quit/return 1
		]
	]

	cmd-render: func [
		path [file!]
		out-dir [file!]
		/local doc kind lay svg-text fname t
	][
		doc: dsl/parse-file path
		unless empty? doc/errors [
			print "ERRORS:"
			foreach e doc/errors [print rejoin ["  - " e]]
			quit/return 1
		]
		ensure-dir out-dir
		foreach kind words-of doc/trees [
			lay: layout/of doc kind
			unless lay [
				print rejoin ["skip " kind ": no layout"]
				continue
			]
			svg-text: render/svg lay
			fname: join out-dir kind-filename kind
			write/binary fname to-binary svg-text
			print rejoin ["wrote " to-local-file fname]
		]
	]

	run: func [
		/local args cmd path out-dir i
	][
		args: system/options/args
		if any [none? args empty? args] [
			usage
			quit/return 1
		]
		cmd: to-string args/1
		switch/default cmd [
			"parse" [
				unless 2 <= length? args [usage quit/return 1]
				cmd-parse to-rebol-file args/2
			]
			"render" [
				unless 2 <= length? args [usage quit/return 1]
				path: to-rebol-file args/2
				out-dir: %out/
				i: 3
				while [i <= length? args] [
					if args/:i = "--out" [
						if i < length? args [
							out-dir: dirize to-rebol-file args/(i + 1)
						]
					]
					i: i + 1
				]
				cmd-render path out-dir
			]
		] [
			usage
			quit/return 1
		]
	]
]

cli/run
