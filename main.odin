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

	vertices := [108]f32 {
		-0.5, -0.5, -0.5,  
		 0.5, -0.5, -0.5,  
		 0.5,  0.5, -0.5,  
		 0.5,  0.5, -0.5, 
		-0.5,  0.5, -0.5,  
		-0.5, -0.5, -0.5,  

		-0.5, -0.5,  0.5, 
		 0.5, -0.5,  0.5,  
		 0.5,  0.5,  0.5,  
		 0.5,  0.5,  0.5,  
		-0.5,  0.5,  0.5,  
		-0.5, -0.5,  0.5,  

		-0.5,  0.5,  0.5, 
		-0.5,  0.5, -0.5,  
		-0.5, -0.5, -0.5,  
		-0.5, -0.5, -0.5,  
		-0.5, -0.5,  0.5,  
		-0.5,  0.5,  0.5,  

		 0.5,  0.5,  0.5,  
		 0.5,  0.5, -0.5,  
		 0.5, -0.5, -0.5,  
		 0.5, -0.5, -0.5,  
		 0.5, -0.5,  0.5,  
		 0.5,  0.5,  0.5,  

		-0.5, -0.5, -0.5,  
		 0.5, -0.5, -0.5,  
		 0.5, -0.5,  0.5,  
		 0.5, -0.5,  0.5,  
		-0.5, -0.5,  0.5,  
		-0.5, -0.5, -0.5,  

		-0.5,  0.5, -0.5,  
		 0.5,  0.5, -0.5,  
		 0.5,  0.5,  0.5,  
		 0.5,  0.5,  0.5,  
		-0.5,  0.5,  0.5,  
		-0.5,  0.5, -0.5,  	}

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
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), uintptr(0))
	gl.EnableVertexAttribArray(0)

	// Unbinding from ARRAY_BUFFER can do this since VAO is already tracking
	// the VBO2
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)

	// could unbind the VAO but just am not doing it. To do it gl.BindVertexArray(0)
	gl.BindVertexArray(0)

	object_shader: Shader
	init_shader(&object_shader, "./shaders/lighting_object.vert", "./shaders/lighting_object.frag")
	use_shader(&object_shader)
	shader_set_vec3f(&object_shader, "objectColor", 1.0, 0.5, 0.31) // coral object
	shader_set_vec3f(&object_shader, "lightColor", 1.0, 1.0, 1.0) // white light

	light_src_shader: Shader
	init_shader(&light_src_shader, "./shaders/light_source.vert", "./shaders/light_source.frag")
	use_shader(&light_src_shader)
	light_src_pos: linalg.Vector3f32
	light_src_pos = {1.2, 1.0, 2.0}


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
		// gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		// Clears the screen using the Clear Color
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		// 4. Draw step
		/*  This is just some code to pass a calculated color into frag shader */
		timeValue := f32(sdl.GetTicks()) / 1000.0 // Time in seconds

		gl.BindVertexArray(lightVAO)

		use_shader(&light_src_shader)
		model := linalg.MATRIX4F32_IDENTITY
		model *= linalg.matrix4_translate_f32(light_src_pos)
		model *= linalg.matrix4_scale_f32({0.5, 0.5, 0.5})

		view := camera.lookat
		projection := linalg.MATRIX4F32_IDENTITY
		projection *= linalg.matrix4_perspective_f32(
			linalg.to_radians(camera.fov),
			f32(width) / f32(height),
			0.1,
			100.0,
		)

		// Set uniforms
		modelLoc := gl.GetUniformLocation(light_src_shader.ID, "model")
		viewLoc := gl.GetUniformLocation(light_src_shader.ID, "view")
		projectionLoc := gl.GetUniformLocation(light_src_shader.ID, "projection")
		gl.UniformMatrix4fv(modelLoc, 1, gl.FALSE, raw_data(&model))
		gl.UniformMatrix4fv(viewLoc, 1, gl.FALSE, raw_data(&view))
		gl.UniformMatrix4fv(projectionLoc, 1, gl.FALSE, raw_data(&projection))
		gl.DrawArrays(gl.TRIANGLES, 0, 36)


		use_shader(&object_shader)
		model = linalg.MATRIX4F32_IDENTITY
		modelLoc = gl.GetUniformLocation(object_shader.ID, "model")
		viewLoc = gl.GetUniformLocation(object_shader.ID, "view")
		projectionLoc = gl.GetUniformLocation(object_shader.ID, "projection")
		gl.UniformMatrix4fv(modelLoc, 1, gl.FALSE, raw_data(&model))
		gl.UniformMatrix4fv(viewLoc, 1, gl.FALSE, raw_data(&view))
		gl.UniformMatrix4fv(projectionLoc, 1, gl.FALSE, raw_data(&projection))
		gl.DrawArrays(gl.TRIANGLES, 0, 36)


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
