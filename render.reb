Rebol [
	Title: "TOC diagram SVG renderer"
	File: %render.reb
	Purpose: "Layout map -> self-contained SVG string."
]

render: context [

	colors: make map! [
		ude "#C0392B"
		de "#1E8449"
		core "#6C3483"
		injection "#D68910"
		goal "#2E86C1"
		requirement "#5D6D7E"
		action "#2874A6"
		effect "#148F77"
		reality "#7F8C8D"
		obstacle "#A04000"
		io "#1A5276"
		default "#2C3E50"
	]

	fill-of: make map! [
		ude "#FDEDEC"
		de "#E8F8F5"
		core "#F5EEF8"
		injection "#FEF5E7"
		goal "#EAF2F8"
		requirement "#F4F6F7"
		action "#EBF5FB"
		effect "#E8F6F3"
		reality "#F8F9F9"
		obstacle "#FDEBD0"
		io "#EAF2F8"
		default "#FFFFFF"
	]

	esc: func [s [string!] /local out ch] [
		out: copy ""
		foreach ch s [
			case [
				ch == #"<" [append out "&lt;"]
				ch == #">" [append out "&gt;"]
				ch == #"&" [append out "&amp;"]
				ch == #"^"" [append out "&quot;"]
				true [append out ch]
			]
		]
		out
	]

	color-for: func [role [word! none!]] [
		any [select colors role colors/default]
	]

	fill-for: func [role [word! none!]] [
		any [select fill-of role fill-of/default]
	]

	inset-ends: func [
		x1 [number!] y1 [number!] x2 [number!] y2 [number!]
		/local dx dy len ux uy
	][
		dx: x2 - x1
		dy: y2 - y1
		len: square-root ((dx * dx) + (dy * dy))
		if len < 18 [return reduce [x1 y1 x2 y2]]
		ux: dx / len
		uy: dy / len
		reduce [
			x1 + (4 * ux) y1 + (4 * uy)
			x2 - (10 * ux) y2 - (10 * uy)
		]
	]

	simple-arrow: func [
		x1 [number!] y1 [number!] x2 [number!] y2 [number!]
		color [string!]
		/local dx dy len ux uy px py
	][
		dx: x2 - x1
		dy: y2 - y1
		len: square-root ((dx * dx) + (dy * dy))
		if len = 0 [return ""]
		ux: dx / len
		uy: dy / len
		px: 0 - uy
		py: ux
		rejoin [
			{<polygon points="}
			x2 {,} y2 { }
			(x2 - (8 * ux) + (3.2 * px)) {,} (y2 - (8 * uy) + (3.2 * py)) { }
			(x2 - (8 * ux) - (3.2 * px)) {,} (y2 - (8 * uy) - (3.2 * py))
			{" fill="} color {"/>}
		]
	]

	node-svg: func [
		n [map!]
		/local out stroke fill fs y line lh shape
	][
		stroke: color-for n/role
		fill: fill-for n/role
		fs: n/font-size
		lh: fs + 5
		out: copy ""
		shape: any [n/role 'default]
		case [
			shape = 'obstacle [
				append out rejoin [
					{<ellipse cx="} n/cx {" cy="} n/cy {" rx="} (n/w / 2) + 6
					{" ry="} (n/h / 2) + 4 {" fill="} fill {" stroke="} stroke
					{" stroke-width="2" stroke-dasharray="5 3"/>}
				]
			]
			shape = 'injection [
				append out rejoin [
					{<rect x="} n/x {" y="} n/y {" width="} n/w {" height="} n/h
					{" rx="10" ry="10" fill="} fill {" stroke="} stroke
					{" stroke-width="3"/>}
					{<rect x="} n/x + 4 {" y="} n/y + 4 {" width="} n/w - 8
					{" height="} n/h - 8 {" rx="8" ry="8" fill="none" stroke="}
					stroke {" stroke-width="1.5"/>}
				]
			]
			shape = 'ude [
				append out rejoin [
					{<rect x="} n/x {" y="} n/y {" width="} n/w {" height="} n/h
					{" rx="6" ry="6" fill="} fill {" stroke="} stroke
					{" stroke-width="2.5"/>}
				]
			]
			true [
				append out rejoin [
					{<rect x="} n/x {" y="} n/y {" width="} n/w {" height="} n/h
					{" rx="6" ry="6" fill="} fill {" stroke="} stroke
					{" stroke-width="1.5"/>}
				]
			]
		]
		if all [n/badge not empty? n/badge] [
			append out rejoin [
				{<text x="} n/x + 10 {" y="} n/y + 14
				{" font-size="11" font-weight="bold" fill="} stroke {">}
				esc n/badge {</text>}
			]
		]
		y: n/y + 12 + fs
		if n/badge [y: y + 4]
		foreach line n/lines [
			append out rejoin [
				{<text x="} n/cx {" y="} y {" text-anchor="middle" font-size="}
				fs {" font-family="Helvetica,Arial,'PingFang SC','Noto Sans SC',sans-serif" fill="#1C2833">}
				esc line {</text>}
			]
			y: y + lh
		]
		out
	]

	draw-line: func [
		x1 [number!] y1 [number!] x2 [number!] y2 [number!]
		stroke [string!] width [string!] dash [string!]
		/local pts
	][
		pts: inset-ends x1 y1 x2 y2
		rejoin [
			{<line x1="} pts/1 {" y1="} pts/2 {" x2="} pts/3 {" y2="} pts/4
			{" stroke="} stroke {" stroke-width="} width {"} dash {/>}
			simple-arrow pts/1 pts/2 pts/3 pts/4 stroke
		]
	]

	edge-svg: func [
		e [map!]
		/local out stroke dash mid-x mid-y ass pts vx
	][
		out: copy ""
		stroke: "#2C3E50"
		dash: ""
		case [
			e/kind = 'conflict [
				mid-x: (e/x1 + e/x2) / 2.0
				mid-y: (e/y1 + e/y2) / 2.0
				append out rejoin [
					{<path d="M } e/x1 { } e/y1
					{ L } mid-x - 7 { } mid-y - 14
					{ L } mid-x + 7 { } mid-y + 14
					{ L } e/x2 { } e/y2
					{" fill="none" stroke="#C0392B" stroke-width="2.5"/>}
					{<text x="} mid-x - 10 {" y="} mid-y + 4
					{" font-size="16" fill="#C0392B">&#9889;</text>}
				]
				if all [block? e/assumptions not empty? e/assumptions] [
					append out rejoin [
						{<text x="} mid-x - 18 {" y="} mid-y + 18
						{" text-anchor="end" font-size="11" fill="#922B21">} esc e/assumptions/1 {</text>}
					]
				]
				return out
			]
			e/kind = 'flip [
				dash: { stroke-dasharray="5 4"}
				stroke: "#A04000"
			]
			e/kind = 'back [
				stroke: "#7F8C8D"
				dash: { stroke-dasharray="6 3"}
				vx: any [e/via-x 24]
				append out rejoin [
					{<path d="M } e/x1 { } e/y1 { L } vx { } e/y1
					{ L } vx { } e/y2 { L } e/x2 { } e/y2
					{" fill="none" stroke="} stroke {" stroke-width="1.4"} dash {/>}
				]
				append out simple-arrow vx e/y2 e/x2 e/y2 stroke
				return out
			]
			e/kind = 'spine [
				stroke: "#1A5276"
				vx: any [e/via-x (e/x1 + 40)]
				append out rejoin [
					{<path d="M } e/x1 { } e/y1 { L } vx { } e/y1
					{ L } vx { } e/y2 { L } e/x2 { } e/y2
					{" fill="none" stroke="} stroke {" stroke-width="1.5"/>}
				]
				append out simple-arrow vx e/y2 e/x2 e/y2 stroke
				return out
			]
			e/kind = 'necessary [stroke: "#1A5276"]
			e/kind = 'context [
				stroke: "#95A5A6"
				dash: { stroke-dasharray="4 3"}
			]
			e/kind = 'seq [
				stroke: "#85929E"
				dash: { stroke-dasharray="3 3"}
			]
			e/kind = 'breaks [
				stroke: "#D68910"
				dash: { stroke-dasharray="4 3"}
			]
			e/kind = 'cut [
				append out rejoin [
					{<line x1="} e/x1 {" y1="} e/y1 {" x2="} e/x2 {" y2="} e/y2
					{" stroke="#C0392B" stroke-width="2" stroke-dasharray="4 3"/>}
					{<text x="} (e/x1 + e/x2) / 2.0 {" y="} ((e/y1 + e/y2) / 2.0) - 8
					{" text-anchor="middle" font-size="12" fill="#C0392B">cut</text>}
				]
				return out
			]
		]
		if all [select e 'trimmed e/trimmed] [
			append out rejoin [
				{<line x1="} e/x1 {" y1="} e/y1 {" x2="} e/x2 {" y2="} e/y2
				{" stroke="#C0392B" stroke-width="2" stroke-dasharray="4 3"/>}
				{<text x="} (e/x1 + e/x2) / 2.0 {" y="} ((e/y1 + e/y2) / 2.0) - 8
				{" text-anchor="middle" font-size="12" fill="#C0392B">cut</text>}
			]
			return out
		]
		append out draw-line e/x1 e/y1 e/x2 e/y2 stroke "1.6" dash
		if all [block? e/assumptions not empty? e/assumptions] [
			ass: e/assumptions/1
			append out rejoin [
				{<text x="} (e/x1 + e/x2) / 2.0 {" y="} ((e/y1 + e/y2) / 2.0) - 14
				{" text-anchor="middle" font-size="10" fill="#7D3C98">}
				esc rejoin ["[" ass "]"]
				{</text>}
			]
		]
		out
	]

	svg: func [
		lay [map!]
		/local out n e m lab w h
	][
		unless lay [return ""]
		w: any [lay/width 800]
		h: any [lay/height 600]
		out: copy ""
		append out rejoin [
			{<?xml version="1.0" encoding="UTF-8"?>}
			{<svg xmlns="http://www.w3.org/2000/svg" width="} w {" height="} h
			{" viewBox="0 0 } w { } h {">}
			{<style>
				text { font-family: Helvetica, Arial, "PingFang SC", "Noto Sans SC", sans-serif; }
			</style>}
			{<rect width="100%" height="100%" fill="#FDFEFE"/>}
			{<text x="20" y="28" font-size="16" font-weight="bold" fill="#1C2833">}
			esc any [lay/title ""]
			{</text>}
		]
		foreach e lay/edges [append out edge-svg e]
		foreach m lay/and-marks [
			append out rejoin [
				{<ellipse cx="} m/x {" cy="} m/y {" rx="} m/rx {" ry="} m/ry
				{" fill="#FCF3CF" stroke="#B7950B" stroke-width="1.5"/>}
				{<text x="} m/x {" y="} m/y + 4 {" text-anchor="middle" font-size="10" fill="#7D6608">AND</text>}
			]
		]
		foreach n lay/nodes [append out node-svg n]
		foreach lab lay/labels [
			append out rejoin [
				{<text x="} lab/x {" y="} lab/y {" font-size="14" font-weight="bold" fill="#1C2833">}
				esc lab/text {</text>}
			]
		]
		append out {</svg>}
		out
	]
]
