package main

import c "core:c"
import "core:fmt"
import "core:math/linalg"
import gl "vendor:OpenGL"
import sdl "vendor:sdl3"

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


	if (!sdl.SetWindowRelativeMouseMode(window, true)) {
		fmt.eprintln("Failed to set relative mouse mode:", sdl.GetError())
		return
	}


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

	/* ---------------- TEXTURE INIT ---------------- */
	// 0.0 is at bottom for openGl not top
	diffuse_map_tex := load_texture("./textures/container2.png")
	specular_map_tex := load_texture("./textures/container2_specular.png")


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

	vertices := [288]f32 {
		// pos			   // normals       // tex
		-0.5, -0.5, -0.5,  0.0,  0.0, -1.0, 0.0, 0.0,
		 0.5, -0.5, -0.5,  0.0,  0.0, -1.0, 1.0, 0.0,
		 0.5,  0.5, -0.5,  0.0,  0.0, -1.0, 1.0, 1.0,
		 0.5,  0.5, -0.5,  0.0,  0.0, -1.0, 1.0, 1.0,
		-0.5,  0.5, -0.5,  0.0,  0.0, -1.0, 0.0, 1.0, 
		-0.5, -0.5, -0.5,  0.0,  0.0, -1.0, 0.0, 0.0,

		-0.5, -0.5,  0.5,  0.0,  0.0, 1.0, 0.0, 0.0,
		 0.5, -0.5,  0.5,  0.0,  0.0, 1.0, 1.0, 0.0,
		 0.5,  0.5,  0.5,  0.0,  0.0, 1.0, 1.0, 1.0,
		 0.5,  0.5,  0.5,  0.0,  0.0, 1.0, 1.0, 1.0,
		-0.5,  0.5,  0.5,  0.0,  0.0, 1.0, 0.0, 1.0,
		-0.5, -0.5,  0.5,  0.0,  0.0, 1.0, 0.0, 0.0,

		-0.5,  0.5,  0.5, -1.0,  0.0,  0.0, 1.0, 0.0,
		-0.5,  0.5, -0.5, -1.0,  0.0,  0.0, 1.0, 1.0,
		-0.5, -0.5, -0.5, -1.0,  0.0,  0.0, 0.0, 1.0,
		-0.5, -0.5, -0.5, -1.0,  0.0,  0.0, 0.0, 1.0,
		-0.5, -0.5,  0.5, -1.0,  0.0,  0.0, 0.0, 0.0,
		-0.5,  0.5,  0.5, -1.0,  0.0,  0.0, 1.0, 0.0,

		 0.5,  0.5,  0.5,  1.0,  0.0,  0.0, 1.0, 0.0,
		 0.5,  0.5, -0.5,  1.0,  0.0,  0.0, 1.0, 1.0,
		 0.5, -0.5, -0.5,  1.0,  0.0,  0.0, 0.0, 1.0,
		 0.5, -0.5, -0.5,  1.0,  0.0,  0.0, 0.0, 1.0,
		 0.5, -0.5,  0.5,  1.0,  0.0,  0.0, 0.0, 0.0,
		 0.5,  0.5,  0.5,  1.0,  0.0,  0.0, 1.0, 0.0,

		-0.5, -0.5, -0.5,  0.0, -1.0,  0.0, 0.0, 1.0,
		 0.5, -0.5, -0.5,  0.0, -1.0,  0.0, 1.0, 1.0,
		 0.5, -0.5,  0.5,  0.0, -1.0,  0.0, 1.0, 0.0,
		 0.5, -0.5,  0.5,  0.0, -1.0,  0.0, 1.0, 0.0,
		-0.5, -0.5,  0.5,  0.0, -1.0,  0.0, 0.0, 0.0,
		-0.5, -0.5, -0.5,  0.0, -1.0,  0.0, 0.0, 1.0,

		-0.5,  0.5, -0.5,  0.0,  1.0,  0.0, 0.0, 1.0,
		 0.5,  0.5, -0.5,  0.0,  1.0,  0.0, 1.0, 1.0,
		 0.5,  0.5,  0.5,  0.0,  1.0,  0.0, 1.0, 0.0,
		 0.5,  0.5,  0.5,  0.0,  1.0,  0.0, 1.0, 0.0,
		-0.5,  0.5,  0.5,  0.0,  1.0,  0.0, 0.0, 0.0,
		-0.5,  0.5, -0.5,  0.0,  1.0,  0.0, 0.0, 1.0
	}

	// odinfmt: enable
	// Defining Vertex Buffer Object
	// Assigning the unique id to the VBO variable via GenBuffers function
	// call
	//VAO, VBO, EBO: u32
	lightVAO, VBO: u32 // multi-pointer

	// Casting fixed array to temp slice then raw_data to make it a multi-ptr
	gl.GenVertexArrays(1, &lightVAO)
	gl.GenBuffers(1, &VBO)

	// 1. Bind VAO
	gl.BindVertexArray(lightVAO)

	// 2. Copy and Bind VBO
	gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), raw_data(vertices[:]), gl.STATIC_DRAW)

	// 3. Set Vertext Attribute Pointer
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), uintptr(0))
	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 3 * size_of(f32))
	gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 6 * size_of(f32))
	gl.EnableVertexAttribArray(0)
	gl.EnableVertexAttribArray(1)
	gl.EnableVertexAttribArray(2)

	// Unbinding from ARRAY_BUFFER can do this since VAO is already tracking
	// the VBO2
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)

	// could unbind the VAO but just am not doing it. To do it gl.BindVertexArray(0)
	gl.BindVertexArray(0)

	camera: Camera
	init_camera(&camera)

	light_src_shader: Shader
	init_shader(&light_src_shader, "./shaders/light_source.vert", "./shaders/light_source.frag")
	light_src_pos: linalg.Vector3f32
	light_src_pos = {1.2, 1.0, 2.0}

	object_shader: Shader
	init_shader(&object_shader, "./shaders/lighting_object.vert", "./shaders/lighting_object.frag")
	
	//odinfmt: disable
	cubePositions: [10][3]f32 = {
		{0.0, 0.0, 0.0},
		{2.0, 5.0, -15.0},
		{-1.5, -2.2, -2.5},
		{-3.8, 2.0, -12.3},
		{2.4, -0.4, -3.5},
		{-1.7, 3.0, -7.5},
		{1.3, -2.0, -2.5},
		{1.5, 2.0, -2.5},
		{1.5, 0.2, -1.5},
		{-1.3, 1.0, -1.5}
	}
	//odinfmt: enable

	// Wireframe mode uncomment below
	// gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
	gl.Enable(gl.DEPTH_TEST)
	frames := 0
	running := true
	dragging := false
	// Seems like locking to 60 fixed this on my laptop
	// WHY? TODO investigate this
	targeted_fps: u64 = 1000 / 60
	mix: f32 = 0.2
	delta_time: f32 = 0.0
	last_frame: f32 = 0.0
	for running {
		current_frame := f32(sdl.GetTicks()) / 1000.0
		delta_time = current_frame - last_frame
		last_frame = current_frame

		start := sdl.GetTicks()
		frames += 1

		handle_mouse_update(&camera)

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
					}
				}
			case .MOUSE_WHEEL:
				{
					camera.fov -= event.wheel.y
					if (camera.fov < 1.0) {
						camera.fov = 1.0
					} else if (camera.fov > 45.0) {
						camera.fov = 45.0
					}
				}
			}
		}

		keyArr: c.int
		keyState := sdl.GetKeyboardState(&keyArr)
		process_continuous_input(&camera, delta_time, keyState)

		// Sets the color of the screen durning the clear screen
		gl.ClearColor(0.1, 0.1, 0.1, 1.0)
		// Clears the screen using the Clear Color
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		// 4. Draw step
		/*  This is just some code to pass a calculated color into frag shader */
		timeValue := f32(sdl.GetTicks()) / 1000.0 // Time in seconds

		gl.BindVertexArray(lightVAO)

		use_shader(&light_src_shader)
		model := linalg.MATRIX4F32_IDENTITY
		model *= linalg.matrix4_translate_f32(light_src_pos)
		model *= linalg.matrix4_scale_f32({0.3, 0.3, 0.3})

		view := camera.lookat
		projection := linalg.MATRIX4F32_IDENTITY
		projection *= linalg.matrix4_perspective_f32(
			linalg.to_radians(camera.fov),
			f32(width) / f32(height),
			0.1,
			100.0,
		)

		// Set uniforms
		shader_set_mat4f32(&light_src_shader, "model", model)
		shader_set_mat4f32(&light_src_shader, "view", view)
		shader_set_mat4f32(&light_src_shader, "projection", projection)
		gl.DrawArrays(gl.TRIANGLES, 0, 36)


		use_shader(&object_shader)
		// Setting active textures and binding
		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, diffuse_map_tex)
		gl.ActiveTexture(gl.TEXTURE1)
		gl.BindTexture(gl.TEXTURE_2D, specular_map_tex)

		model = linalg.MATRIX4F32_IDENTITY
		shader_set_mat4f32(&object_shader, "model", model)
		shader_set_mat4f32(&object_shader, "view", view)
		shader_set_mat4f32(&object_shader, "projection", projection)
		shader_set_vec3f(
			&object_shader,
			"viewPos",
			camera.position.x,
			camera.position.y,
			camera.position.z,
		)
		shader_set_int(&object_shader, "material.diffuse", 0) // using texture0
		shader_set_int(&object_shader, "material.specural", 1) // using texture1
		shader_set_float(&object_shader, "material.shininess", 32.0)
		shader_set_vec3f(
			&object_shader,
			"light.position",
			light_src_pos.x,
			light_src_pos.y,
			light_src_pos.z,
		)

		// Light Settings
		lightColor: [3]f32
		// lightColor[0] = linalg.sin(timeValue * 1.8)
		// lightColor[1] = linalg.sin(timeValue * .8)
		// lightColor[2] = linalg.sin(timeValue * 1.2)
		lightColor.xyz = 1.0


		ambientColor: [3]f32
		ambientColor = lightColor * 0.2 // strength

		diffuseColor: [3]f32
		diffuseColor = lightColor * 0.5 // strength

		shader_set_vec3f(
			&object_shader,
			"light.ambient",
			ambientColor.x,
			ambientColor.y,
			ambientColor.z,
		)
		shader_set_vec3f(
			&object_shader,
			"light.diffuse",
			diffuseColor.x,
			diffuseColor.y,
			diffuseColor.z,
		)
		shader_set_vec3f(
			&object_shader,
			"light.specural",
			lightColor.x,
			lightColor.y,
			lightColor.z,
		)

		// This was for directional light
		// shader_set_vec3f_vec(&object_shader, "light.direction", {-0.2, -1.0, -0.3})

		// Point Light
		// shader_set_float(&object_shader, "light.constant", 1.0)
		// shader_set_float(&object_shader, "light.linear", 0.09)
		// shader_set_float(&object_shader, "light.quadratic", 0.032)

		// Spotlight ("flash light in this case") but could
		// also use the same idea for a street light straight down
		shader_set_vec3f_vec(&object_shader, "light.position", camera.position)
		shader_set_vec3f_vec(&object_shader, "light.direction", camera.direction)

		// Gets the cosine value of the cutoff from the angle
		// We will compare it with dot product between the spotlight direction
		// and the light direction. Spot is direction of spotlight. While the light direction
		// NOT light.direction is the calculated value. The result of that
		// can be directly compared to cutOff since cos(theta) = a dot b when
		// a and b are both unit vectors
		shader_set_float(&object_shader, "light.cutOff", linalg.cos(linalg.to_radians(f32(12.5))))

		for i := 0; i < 10; i += 1 {
			model = linalg.MATRIX4F32_IDENTITY
			model *= linalg.matrix4_translate_f32(cubePositions[i])
			angle: f32 = linalg.to_radians(f32(20 * i))
			model *= linalg.matrix4_rotate_f32(angle, {1.0, 0.3, 0.5})
			shader_set_mat4f32(&object_shader, "model", model)
			gl.DrawArrays(gl.TRIANGLES, 0, 36)
		}


		sdl.GL_SwapWindow(window)
		gl.BindBuffer(gl.ARRAY_BUFFER, 0)

		elapsed_time := sdl.GetTicks() - start
		sdl.Delay(u32(targeted_fps - elapsed_time))
	}

	// Clean up
	gl.DeleteVertexArrays(1, &lightVAO)
	gl.DeleteBuffers(1, &VBO)
	gl.DeleteProgram(shader.ID)
	gl.DeleteProgram(light_src_shader.ID)
	gl.DeleteProgram(object_shader.ID)

	sdl.Quit()
	return
}

process_continuous_input :: proc(camera: ^Camera, delta_time: f32, keystate: [^]bool) {
	if (keystate[sdl.Scancode.W]) {
		move_camera_forward(camera, delta_time)
	}

	if (keystate[sdl.Scancode.S]) {
		move_camera_backward(camera, delta_time)
	}

	if (keystate[sdl.Scancode.A]) {
		move_camera_left(camera, delta_time)
	}

	if (keystate[sdl.Scancode.D]) {
		move_camera_right(camera, delta_time)
	}
}

handle_mouse_update :: proc(camera: ^Camera) {
	offsetX, offsetY: f32
	mouseState := sdl.GetRelativeMouseState(&offsetX, &offsetY)

	camera.yaw += (offsetX * camera.sensitivity)
	camera.pitch += (-offsetY * camera.sensitivity)
	update_camera_pitch_yaw(camera)
}
