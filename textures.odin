package main

import "core:fmt"
import gl "vendor:OpenGL"
import stbi "vendor:stb/image"

load_texture :: proc(path: cstring) -> u32 {
	stbi.set_flip_vertically_on_load(1)

	texture: u32
	gl.GenTextures(1, &texture)
	gl.BindTexture(gl.TEXTURE_2D, texture)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	tex_width, tex_height, nrChannels: i32
	tex_data: [^]byte = stbi.load(path, &tex_width, &tex_height, &nrChannels, 0)


	format: i32
	format_u: u32
	switch (nrChannels) {
	case 1:
		format = gl.RED
		format_u = gl.RED
	case 2:
	case 3:
		format = gl.RGB
		format_u = gl.RGB
	case 4:
		format = gl.RGBA
		format_u = gl.RGBA
	case:
		format = gl.RGB
		format_u = gl.RGB
	}

	if (tex_data != nil) {
		// This is where we dump our data into
		// the TEXTURE_2D buffer it seems i.e. whatever location
		// is currently bound to the buffer which happens to be the u32 of use map
		gl.TexImage2D(
			gl.TEXTURE_2D,
			0,
			format,
			tex_width,
			tex_height,
			0,
			format_u,
			gl.UNSIGNED_BYTE,
			tex_data,
		)

		gl.GenerateMipmap(gl.TEXTURE_2D)
	} else {
		fmt.println("[ERROR] Failed to load texture data.")
	}

	gl.BindTexture(gl.TEXTURE_2D, 0)
	stbi.image_free(tex_data)

	return texture
}
