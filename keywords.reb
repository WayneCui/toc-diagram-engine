Rebol [
	Title: "TOC Chinese keyword constants"
	File: %keywords.reb
	Purpose: "UTF-8 Chinese tokens as binary->string (source stays ASCII-safe)."
]

toc-kw: context [
	;; tree headers
	hdr-crt: to-string #{E78EB0E78AB6E59BBE}
	hdr-cloud: to-string #{E586B2E7AA81E59BBE}
	hdr-frt: to-string #{E69CAAE69DA5E59BBE}
	hdr-nbr: to-string #{E8B49FE99DA2E58886E694AF}
	hdr-nbr-alt: to-string #{E8B49FE99DA2E58886E694AFE59BBE}
	hdr-prt: to-string #{E5898DE68F90E69DA1E4BBB6E6A091}
	hdr-trt: to-string #{E8BDACE58F98E59BBE}

	;; role / keyword prefixes
	ude: to-string #{E4B88DE889AFE69588E5BA94}
	core: to-string #{E6A0B8E5BF83E997AEE9A298}
	de: to-string #{E69C9FE69C9BE69588E5BA94}
	action: to-string #{E58AA8E4BD9C}
	reality: to-string #{E78EB0E5AE9E}
	effect: to-string #{E69588E69E9C}
	obstacle: to-string #{E99A9CE7A28D}
	flip-to: to-string #{E7BFBBE68890}
	injection: to-string #{E6B3A8E585A5}
	break-assump: to-string #{E68993E7A0B4}
	trim: to-string #{E589AAE696AD}
	conflict: to-string #{E586B2E7AA81}
	and-conj: to-string #{E4B88E}          ; ?
	and-conj-alt: to-string #{E5928C}      ; ?
	if-kw: to-string #{E5A682E69E9C}
	then-kw: to-string #{E982A3E4B988}
	and-kw: to-string #{E5B9B6E4B894}       ; 并且
	because: to-string #{E59BA0E4B8BA}
	want: to-string #{E8A681E683B3}
	must: to-string #{E5B0B1E5BF85E9A1BB}

	period: #"^(3002)"   ; 。
	quote-open: #"^(300C)"
	quote-close: #"^(300D)"
]
