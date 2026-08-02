package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:strings"
import gl "vendor:OpenGL"
import sdl "vendor:sdl3"
import stbi "vendor:stb/image"

/*
* Really long breakdown of my understanding of how this seems to work
* SDL can do simple rendering but instead we will passing the work off to 
* whatever opengl library my GPU has on hand (generally implementation written)
* by the manufacturer. Seems like we bind the location of the function calls
* to SDL. I think is via the gl.load_up_to function? 
* 
* Anyways the rendering pipeline has two buffers a front and a back
* The front is what you see and the back is creating the next frame
* SwapWindow while passing the back buffer (window) will display next frame. I am assuming it sets the front buffer to the back buffer or dumps the back
* buffer into the front buffer. Then clears the new back buffer or is empty
* as a result of the dump.
*
* SDL handles creating the window, keyboard inputs, audio, networking.
* While OpenGL will handle creating the new frame. To my understanding I just
* passed off the rendering work to a more complex and more competent rendering
* pipeline. I am assuming the same thing works for Vulkan and Metal which I
* believe are two other graphics apis.
*/

main :: proc() {
	if !sdl.Init({.VIDEO}) {
		fmt.eprintln("Failed to initialize SDL:", sdl.GetError())
		return
	}

	fmt.println(sdl.GetCurrentVideoDriver())

	fmt.println("[Debug] Video Initialized")

	// Setting the OpenGL setting the version and match
	// not 100% guarentteed that I get it but will need
	// to check afterwards
	sdl.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, 3)
	sdl.GL_SetAttribute(.CONTEXT_MINOR_VERSION, 3)
	sdl.GL_SetAttribute(.CONTEXT_PROFILE_MASK, i32(sdl.GL_CONTEXT_PROFILE_CORE))

	sdl.GL_SetSwapInterval(0)

	// 16:9 aspect ratio
	width, height: i32
	width = 16 * 80
	height = 9 * 80

	window := sdl.CreateWindow("Test", width, height, {.OPENGL})
	if window == nil {
		fmt.eprintln("Failed to create window:", sdl.GetError())
		return
	}
	defer sdl.DestroyWindow(window)

	fmt.println("[Debug] Window Initialized")

	// Creating the ctx for OpenGL based on SDL's window
	ctx := sdl.GL_CreateContext(window)
	if ctx == nil {
		fmt.eprintln("Failed to create ctx:", sdl.GetError())
		return
	}
	defer sdl.GL_DestroyContext(ctx)

	fmt.println("[Debug] Context Created")

	sdl.GL_MakeCurrent(window, ctx)


	// Have to load the proc address to call gl funcdtions
	gl.load_up_to(3, 3, sdl.gl_set_proc_address)
	gl.Viewport(0, 0, width, height)

	/* ----------------- SHADER INIT ---------------- */
	shader: Shader
	init_shader(&shader, "./shaders/shader.vert", "./shaders/shader.frag")

	/* ----------------- TEXTURE LOAD --------------- */
	// Images start with 0.0 at top. OpenGL expects 0.0 to be at bottom
	stbi.set_flip_vertically_on_load(1)

	box_texture: u32
	// Number of textures, where to slot the ids
	gl.GenTextures(1, &box_texture)
	gl.BindTexture(gl.TEXTURE_2D, box_texture)

	// Set parameters
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
	gl.TexParameteri(
		gl.TEXTURE_2D,
		gl.TEXTURE_WRAP_T,
		gl.CLAMP_TO_EDGE,
	); gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR); gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR); tex_width, tex_height, nrChannels: i32
	// Get texture width, height, and number of color channels

	texture_data: [^]byte = stbi.load(
		"textures/container.jpg",
		&tex_width,
		&tex_height,
		&nrChannels,
		0,
	)

	// Wrap it so we don't try and operate on unbound memory
	if (texture_data != nil) {
		// Binding it so the following gl commands use it much like
		// binding vbo or vao
		gl.TexImage2D(
			gl.TEXTURE_2D,
			0,
			gl.RGB,
			tex_width,
			tex_height,
			0,
			gl.RGB,
			gl.UNSIGNED_BYTE,
			texture_data,
		)

		gl.GenerateMipmap(gl.TEXTURE_2D)
	} else {fmt.println("Failed to load texture")
	}


	// Unbind TEXTURE_2D till we need it
	gl.BindTexture(gl.TEXTURE_2D, 0)

	// Texture is now bound to the to the location of box_texture
	// so we can free the memory since we don't need the image anymore
	stbi.image_free(texture_data)

	/* ----------- Loading Second Texture ---------- */
	// Just copying and pasting above for now to load a second texture
	// TODO BREAK THIS OUT INTO ITS OWN FUNCTION OR SOMETHING
	face_texture: u32
	// Number of textures, where to slot the ids
	gl.GenTextures(1, &face_texture)

	// Activating the second texture unit
	// Guarenteed to have 0-15 units (16 total)
	// To make it so we have multiple textures available in the shaders
	// we need to bind to a different texture unit's texture 2D socket
	// I imagine I actually don't need to activate texture 1 here at all
	// just when binding before using in the loop
	// gl.ActiveTexture(gl.TEXTURE1)
	gl.BindTexture(gl.TEXTURE_2D, face_texture)

	// Set parameters
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	face_width, face_height, face_nrChannels: i32
	// Get texture width, height, and number of color channels
	face_texture_data: [^]byte = stbi.load(
		"textures/awesomeface.png",
		&face_width,
		&face_height,
		&face_nrChannels,
		0,
	)

	// Wrap it so we don't try and operate on unbound memory
	if (face_texture_data != nil) {
		// Binding it so the following gl commands use it much like
		// binding vbo or vao
		gl.TexImage2D(
			gl.TEXTURE_2D,
			0,
			gl.RGB,
			face_width,
			face_height,
			0,
			gl.RGBA,
			gl.UNSIGNED_BYTE,
			face_texture_data,
		)

		gl.GenerateMipmap(gl.TEXTURE_2D)
	} else {
		fmt.println("Failed to load texture")
	}


	// Unbind TEXTURE_2D till we need it
	gl.BindTexture(gl.TEXTURE_2D, 0)

	// Texture is now bound to the to the location of box_texture
	// so we can free the memory since we don't need the image anymore
	stbi.image_free(face_texture_data)

	/* ---------------- VERTEX DATA INIT ---------------- */


	
	// odinfmt: disable
	// vertices := [4][3]f32{
	// 	{0.5, 0.5, 0.0}, xperiment with the different texture wrapping methods by specifying texture coordinates in the range 0.0f to 2.0
	// 	{0.5, -0.5, 0.0}, 
	// 	{-0.5, -0.5, 0.0}, 
	// 	{-0.5, 0.5, 0.0}
	// }

	// With Color Vertex
	// With Texture Cords S and T
	// vertices := [4][8]f32 {
	// 	{0.5, 0.5, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0}, // Top Right
	// 	{0.5, -0.5, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0}, // Bottom Right
	// 	{-0.5, -0.5, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0}, // Bottom Left
	// 	{-0.5, 0.5, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0}, // Top Left
	// }

	vertices := [180]f32 {
		-0.5, -0.5, -0.5,  0.0, 0.0,
		 0.5, -0.5, -0.5,  1.0, 0.0,
		 0.5,  0.5, -0.5,  1.0, 1.0,
		 0.5,  0.5, -0.5,  1.0, 1.0,
		-0.5,  0.5, -0.5,  0.0, 1.0,
		-0.5, -0.5, -0.5,  0.0, 0.0,

		-0.5, -0.5,  0.5,  0.0, 0.0,
		 0.5, -0.5,  0.5,  1.0, 0.0,
		 0.5,  0.5,  0.5,  1.0, 1.0,
		 0.5,  0.5,  0.5,  1.0, 1.0,
		-0.5,  0.5,  0.5,  0.0, 1.0,
		-0.5, -0.5,  0.5,  0.0, 0.0,

		-0.5,  0.5,  0.5,  1.0, 0.0,
		-0.5,  0.5, -0.5,  1.0, 1.0,
		-0.5, -0.5, -0.5,  0.0, 1.0,
		-0.5, -0.5, -0.5,  0.0, 1.0,
		-0.5, -0.5,  0.5,  0.0, 0.0,
		-0.5,  0.5,  0.5,  1.0, 0.0,

		 0.5,  0.5,  0.5,  1.0, 0.0,
		 0.5,  0.5, -0.5,  1.0, 1.0,
		 0.5, -0.5, -0.5,  0.0, 1.0,
		 0.5, -0.5, -0.5,  0.0, 1.0,
		 0.5, -0.5,  0.5,  0.0, 0.0,
		 0.5,  0.5,  0.5,  1.0, 0.0,

		-0.5, -0.5, -0.5,  0.0, 1.0,
		 0.5, -0.5, -0.5,  1.0, 1.0,
		 0.5, -0.5,  0.5,  1.0, 0.0,
		 0.5, -0.5,  0.5,  1.0, 0.0,
		-0.5, -0.5,  0.5,  0.0, 0.0,
		-0.5, -0.5, -0.5,  0.0, 1.0,

		-0.5,  0.5, -0.5,  0.0, 1.0,
		 0.5,  0.5, -0.5,  1.0, 1.0,
		 0.5,  0.5,  0.5,  1.0, 0.0,
		 0.5,  0.5,  0.5,  1.0, 0.0,
		-0.5,  0.5,  0.5,  0.0, 0.0,
		-0.5,  0.5, -0.5,  0.0, 1.0
	}

	/* Two triangle */
	indices := [6]u32{
		0, 1, 3, // First Triangle
		1, 2, 3, // Second Triangle
	}

	// odinfmt: enable

	// Defining Vertex Buffer Object
	// Assigning the unique id to the VBO variable via GenBuffers function
	// call
	//VAO, VBO, EBO: u32
	VAO, VBO, EBO: [2]u32 // multi-pointer

	// Casting fixed array to temp slice then raw_data to make it a multi-ptr
	gl.GenVertexArrays(2, raw_data(VAO[:]))
	gl.GenBuffers(2, raw_data(VBO[:]))
	gl.GenBuffers(2, raw_data(EBO[:]))

	// 1. Bind VAO
	gl.BindVertexArray(VAO[0])

	// 2. Copy and Bind VBO
	gl.BindBuffer(gl.ARRAY_BUFFER, VBO[0])
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), raw_data(vertices[:]), gl.STATIC_DRAW)

	// Same thing for an element buffer object (EBO)
	// TODO if this flips its shit its because I tried to element draw with current
	// set up where I'm using two separate buffers as an exercise
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO[0])
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), raw_data(indices[:]), gl.STATIC_DRAW)

	// 3. Set Vertext Attribute Pointer
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 5 * size_of(f32), uintptr(0))
	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 3 * size_of(f32))
	// gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 6 * size_of(f32))
	gl.EnableVertexAttribArray(0)
	gl.EnableVertexAttribArray(1)
	// gl.EnableVertexAttribArray(2)

	// Unbinding from ARRAY_BUFFER can do this since VAO is already tracking
	// the VBO
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)

	// could unbind the VAO but just am not doing it. To do it gl.BindVertexArray(0)
	gl.BindVertexArray(0)

	// DO NOT UNBIND EBO while VAO is active
	// Unbinding VAO while EBO is bound allow for that binding reference to
	// stay with the VAO and keep being reused. It will be overwritten if
	// something else is bound to gl.ELEMENT_ARRAY_BUFFER while the VAO is active
	// as such only bind EBO is you want to affect the EBO of the currently bound VAO
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0)

	fmt.println("[DEBUG] All VAO and VBO init and binding done")


	// Set shader then set uniform values
	// 0 and 1 here refer to the texture unit integer
	use_shader(&shader)
	shader_set_int(&shader, "ourTexture", 0)
	shader_set_int(&shader, "faceTexture", 1)


	// Wireframe mode uncomment below
	// gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
	gl.Enable(gl.DEPTH_TEST)
	frames := 0
	running := true
	dragging := false

	camera: Camera
	init_camera(&camera)

	// Seems like locking to 60 fixed this on my laptop
	// WHY? TODO investigate this
	targeted_fps: u64 = 1000 / 60
	mix: f32 = 0.2
	for running {
		start := sdl.GetTicks()
		frames += 1
		event: sdl.Event
		for sdl.PollEvent(&event) {
			#partial switch event.type {
			case .QUIT:
				running = false
				break
			case .WINDOW_RESIZED:
				gl.Viewport(0, 0, event.window.data1, event.window.data2)
			case .KEY_DOWN:
				{
					switch event.key.key {
					case sdl.K_UP:
						mix += .1
					case sdl.K_DOWN:
						mix -= .1
					case sdl.K_W:
						move_camera_forward(&camera)
					case sdl.K_S:
						move_camera_backward(&camera)
					case sdl.K_A:
						move_camera_left(&camera)
					case sdl.K_D:
						move_camera_right(&camera)
					}
				}
			}
		}
		// Sets the color of the screen durning the clear screen
		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		// Clears the screen using the Clear Color
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		// 4. Draw step
		/*  This is just some code to pass a calculated color into frag shader */
		timeValue := f32(sdl.GetTicks()) / 1000.0 // Time in seconds


		greenValue := (math.sin(timeValue) / 2.0) + 0.5
		vertexColorLoc := gl.GetUniformLocation(shader.ID, strings.clone_to_cstring("uniColor"))
		use_shader(&shader)

		// fmt.printf("Frame count: %d\n", frames)
		gl.Uniform4f(vertexColorLoc, 0.0, greenValue, 0.0, 1.0)

		shader_set_float(&shader, "textureMix", mix)

		// Transformations (don't have glm using built in math/linalg)
		// Make the model matrix
		model := linalg.MATRIX4F32_IDENTITY // The 4x4 identity matrix
		// Apply tranformations to it
		// model *= linalg.matrix4_rotate_f32(linalg.to_radians(f32(-55.0)), [3]f32{1.0, 0.0, 0.0})
		model *= linalg.matrix4_rotate_f32(
			timeValue * linalg.to_radians(f32(50.0)),
			[3]f32{0.5, 1.0, 0.0},
		)

		// View Matrix
		// view := linalg.MATRIX4F32_IDENTITY
		// view *= linalg.matrix4_translate_f32([3]f32{0.0, 0.0, -3.0})
		// view *= linalg.matrix4_translate_f32([3]f32{0.0, 0.0, 0.0})

		// radius := f32(10.0) // distance from target
		// camX := math.sin(f32(sdl.GetTicks()) / 1000.0) * radius
		// camZ := math.cos(f32(sdl.GetTicks()) / 1000.0) * radius
		// view := linalg.matrix4_look_at_f32(
		// 	{camX, 0.0, camZ},
		// 	{f32(0.0), 0.0, 0.0},
		// 	{f32(0.0), 1.0, 0.0},
		// )

		view := camera.lookat


		// Projection Matrix
		projection := linalg.MATRIX4F32_IDENTITY
		projection *= linalg.matrix4_perspective_f32(
			linalg.to_radians(f32(40.0)),
			f32(width) / f32(height),
			0.1,
			100.0,
		)

		modelLoc := gl.GetUniformLocation(shader.ID, "model")
		viewLoc := gl.GetUniformLocation(shader.ID, "view")
		projectionLoc := gl.GetUniformLocation(shader.ID, "projection")

		gl.UniformMatrix4fv(modelLoc, 1, gl.FALSE, raw_data(&model))
		gl.UniformMatrix4fv(viewLoc, 1, gl.FALSE, raw_data(&view))
		gl.UniformMatrix4fv(projectionLoc, 1, gl.FALSE, raw_data(&projection))

		transLoc := gl.GetUniformLocation(shader.ID, "transform")
		// gl.UniformMatrix4fv(transLoc, 1, gl.FALSE, raw_data(&trans))


		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, box_texture)
		gl.ActiveTexture(gl.TEXTURE1)
		gl.BindTexture(gl.TEXTURE_2D, face_texture)

		// don't technically need to bind it every time since only one
		gl.BindVertexArray(VAO[0])

		// Don't need to bind EBO here since VAO has EBO stored from earlier
		// and has not been overwritten by another binding while active
		// gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO[0])

		// primitive type, starting index of vertex array, how many vertices
		// Drawing using VBO + VAO
		// gl.DrawArrays(gl.TRIANGLES, 0, 36)

		// Drawing using indices in EBO, Data in VBO and VAO
		// unsigned int here is u32 I had uint so it wouldn't run
		// gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)

		cubePositions := [10][3]f32 {
			{0.0, 0.0, 0.0},
			{2.0, 5.0, -15.0},
			{-1.5, -2.2, -2.5},
			{-3.8, -2.0, -12.3},
			{2.4, -0.4, -3.5},
			{-1.7, 3.0, -7.5},
			{1.3, -2.0, -2.5},
			{1.5, 2.0, -2.5},
			{1.5, 1.2, -1.5},
			{-1.3, 1.0, -1.5},
		}

		for i in 0 ..< 10 {
			model := linalg.MATRIX4F32_IDENTITY // The 4x4 identity matrix
			model *= linalg.matrix4_translate_f32(cubePositions[i]) // current postiion

			angle := f32(20.0) * f32(i + 1)

			model *= linalg.matrix4_rotate_f32(linalg.to_radians(angle), [3]f32{1.0, 0.3, 0.5})

			if (i % 2 == 0) {
				model *= linalg.matrix4_rotate_f32(
					timeValue * linalg.to_radians(angle),
					[3]f32{1.0, 0.3, 0.5},
				)
			}
			modelLoc := gl.GetUniformLocation(shader.ID, "model")
			gl.UniformMatrix4fv(modelLoc, 1, gl.FALSE, raw_data(&model))
			gl.DrawArrays(gl.TRIANGLES, 0, 36)

		}

		gl.BindVertexArray(0) // could unbind it every time

		sdl.GL_SwapWindow(window)


		gl.BindBuffer(gl.ARRAY_BUFFER, 0)

		elapsed_time := sdl.GetTicks() - start
		sdl.Delay(u32(targeted_fps - elapsed_time))
	}

	// Clean up
	gl.DeleteVertexArrays(2, raw_data(VAO[:]))
	gl.DeleteBuffers(2, raw_data(VBO[:]))
	gl.DeleteProgram(shader.ID)

	sdl.Quit()
	return
}

// track_mouse :: proc() {
// 	/* Mouse Tracking */
// 	mouseX, mouseY: f32
// 	buttonState := sdl.GetGlobalMouseState(&mouseX, &mouseY)
// 	normalizedX := normalize_global_coordinate(mouseX, 0, f32(width))
// 	// Have to invert the Y
// 	normalizedY := normalize_global_coordinate(mouseY, 0, f32(height)) * -1
// 	fmt.printf("Normalized X: %f\n NormalizedY: %f\n", normalizedX, normalizedY)
// 	leftPressed := sdl.MouseButtonFlags.LEFT in buttonState
// 	fmt.printf("Left Mouse Btn Down: %t\n", leftPressed)
//
// 	// BROKEN FOR NOW SINCE I WENT FROM [3][3] to [3][6]
// 	// Need to make code more maliable
// 	// Check if shape is "grabbed"
// 	if (leftPressed) {
// 		fmt.printf("Cursor inside: %t\n", is_inside(Point2d{normalizedX, normalizedY}, vertices))
//
// 		if (is_inside(Point2d{normalizedX, normalizedY}, vertices)) {
// 			dragging = true
// 		}
//
// 		// follow cursor
// 		// put triangle in center of cursor
// 		// calculate new vertices based on normalized mouse cords
// 		if (dragging) {
// 							// odinfmt: disable
// 					vertices = [3][3]f32{
// 						{0.0+normalizedX, 0.5+normalizedY, 0.0},
// 						{0.25+normalizedX, 0.0+normalizedY, 0.0},
// 						{-0.25+normalizedX, 0.0+normalizedY, 0.0}
// 					}
// 					// odinfmt: enable
// 			gl.BindBuffer(gl.ARRAY_BUFFER, VBO[0])
// 			gl.BufferData(
// 				gl.ARRAY_BUFFER,
// 				size_of(vertices),
// 				raw_data(vertices[:]),
// 				gl.DYNAMIC_DRAW,
// 			)
// 		}
// 	} else {
// 		dragging = false
// 		// drop
// 	}
//
//
// }
