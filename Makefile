RELEASE_DIR=${TMP_DIR}/hsw_maidroid

.PHONY : luacheck
luacheck:
	luacheck .

# Release stage specifically for HSW to copy the files needed over
.PHONY: prepare.release
prepare.release:
	mkdir -p "${RELEASE_DIR}"

	cp -r --parents autotest "${RELEASE_DIR}"
	cp -r --parents compat "${RELEASE_DIR}"
	cp -r --parents cores "${RELEASE_DIR}"
	cp -r --parents entities "${RELEASE_DIR}"
	cp -r --parents items "${RELEASE_DIR}"
	cp -r --parents models "${RELEASE_DIR}"
	cp -r --parents nodes "${RELEASE_DIR}"
	cp -r --parents sounds "${RELEASE_DIR}"
	cp -r --parents textures "${RELEASE_DIR}"
	cp -r --parents *.lua "${RELEASE_DIR}"

	cp credits.json "${RELEASE_DIR}"
	cp LICENSE "${RELEASE_DIR}"
	cp mod.conf "${RELEASE_DIR}"
	cp README.md "${RELEASE_DIR}"
