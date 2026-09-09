Rebol [
	Title: "UTF-8 probe"
]

;; ??? as UTF-8
cloud-name: to-string #{E586B2E7AA81E59BBE}
print ["cloud-name:" mold cloud-name "len:" length? cloud-name]

m: make map! reduce [cloud-name 'cloud]
print ["select by constructed:" mold select m cloud-name]

text: to-string read/binary %examples/cloud-only.toc
line1: trim first split text #"^/"
print ["line1:" mold line1]
print ["equal?" cloud-name = line1]
print ["select by line1:" mold select m line1]

;; Try Chinese literal in this file
lit: "???"
print ["literal:" mold lit "bin:" mold to-binary lit]
print ["lit=constructed?" lit = cloud-name]
