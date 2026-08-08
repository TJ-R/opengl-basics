package main
import "core:math/linalg"

Camera :: struct {
	speed:     f32,
	target:    linalg.Vector3f32,
	front:     linalg.Vector3f32,
	position:  linalg.Vector3f32,
	direction: linalg.Vector3f32,
	up:        linalg.Vector3f32,
	right:     linalg.Vector3f32,
	lookat:    linalg.Matrix4f32,
	pitch:     f32,
	yaw:       f32,
}

// Should overload this?
init_camera :: proc(camera: ^Camera) {
	camera.speed = 3.0
	camera.target = {f32(0.0), f32(0.0), f32(0.0)} // Can use target if trying to track something
	camera.position = {f32(0.0), f32(0.0), f32(3.0)}
	camera.front = {f32(0.0), 0.0, -1.0}

	// Default to -90 degrees since we have elements pos in -z direction
	camera.yaw = -90.0
	camera.pitch = 0.0

	/* 
        Just a note on normalization. Keeping the same direction of the vecto       Just a note on normalization. Keeping the same direction of the vector but making its length 1. We accomplish this by dividing
        the vector by its magnitude. Magnitude is the square root of all of the components
        being squared
    */
	camera.direction = linalg.normalize(camera.position - camera.target)

	camera.right = linalg.cross(
		linalg.Vector3f32({f32(0.0), f32(1.0), f32(0.0)}),
		camera.direction,
	)
	camera.up = linalg.cross(camera.direction, camera.right)

	// This does a lot of the work for us that I did above
	camera.lookat = linalg.matrix4_look_at_f32(
		camera.position,
		camera.position + camera.front,
		linalg.Vector3f32({f32(0.0), f32(1.0), f32(0.0)}),
	)

	update_camera_pitch_yaw(camera)
}

move_camera_forward :: proc(camera: ^Camera, delta_time: f32) {
	camera.position += camera.front * (camera.speed * delta_time)
	update_camera_lookat(camera)
}

move_camera_backward :: proc(camera: ^Camera, delta_time: f32) {
	camera.position -= camera.front * (camera.speed * delta_time)
	update_camera_lookat(camera)
}

move_camera_right :: proc(camera: ^Camera, delta_time: f32) {
	camera.position += camera.right * (camera.speed * delta_time)
	update_camera_lookat(camera)
}

move_camera_left :: proc(camera: ^Camera, delta_time: f32) {
	camera.position -= camera.right * (camera.speed * delta_time)
	update_camera_lookat(camera)
}

update_camera_pitch_yaw :: proc(camera: ^Camera) {
	// looking down the y-axis of the camera to set the
	// vectors x and z component in accordance to soh cah toa
	// the yaw angle is at origin the opposite side is length on z-axis
	// the adjacent side is the length on the y axis

	/* This is without pitch
	camera.direction.x = linalg.cos(linalg.to_radians(yaw))
	camera.direction.z = linalg.sin(linalg.to_radians(yaw))
	*/


	// Now updating the pitch is looking at the y axis while sitting on the
	// x/z axis so that it is a line (2D plane just like above)
	// the length on the y axis is the sin of the pitch angle
	camera.direction.y = linalg.sin(linalg.to_radians(camera.pitch))

	// Pitch also affects the x/z plane by cos(pitch) amount
	// The below might not be the way to nicely update it. I'm worried about
	// multiple applications of * cos(pitch)
	camera.direction.x =
		linalg.cos(linalg.to_radians(camera.yaw)) * linalg.cos(linalg.to_radians(camera.pitch))
	camera.direction.z =
		linalg.sin(linalg.to_radians(camera.yaw)) * linalg.cos(linalg.to_radians(camera.pitch))
}

update_camera_lookat :: proc(camera: ^Camera) {
	camera.lookat = linalg.matrix4_look_at_f32(
		camera.position,
		camera.position + camera.front,
		{f32(0.0), 1.0, 0.0},
	)
}
