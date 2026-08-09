package main
import "core:fmt"
import "core:math/linalg"

Camera :: struct {
	speed:       f32,
	target:      linalg.Vector3f32,
	front:       linalg.Vector3f32,
	position:    linalg.Vector3f32,
	direction:   linalg.Vector3f32,
	up:          linalg.Vector3f32,
	right:       linalg.Vector3f32,
	lookat:      linalg.Matrix4f32,
	pitch:       f32,
	yaw:         f32,
	sensitivity: f32,
	fov:         f32,
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
	camera.sensitivity = 0.1
	camera.fov = 45.0

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
	// camera.lookat = linalg.matrix4_look_at_f32(
	// 	camera.position,
	// 	camera.position + camera.front,
	// 	linalg.Vector3f32({f32(0.0), f32(1.0), f32(0.0)}),
	// )
	update_camera_lookat(camera)
	update_camera_pitch_yaw(camera)
}

move_camera_forward :: proc(camera: ^Camera, delta_time: f32) {

	camera.position.xz += (camera.front * (camera.speed * delta_time)).xz
	update_camera_lookat(camera)
}

move_camera_backward :: proc(camera: ^Camera, delta_time: f32) {
	camera.position.xz -= (camera.front * (camera.speed * delta_time)).xz
	update_camera_lookat(camera)
}

move_camera_right :: proc(camera: ^Camera, delta_time: f32) {
	camera.position.xz -= (camera.right * (camera.speed * delta_time)).xz
	update_camera_lookat(camera)
}

move_camera_left :: proc(camera: ^Camera, delta_time: f32) {
	camera.position.xz += (camera.right * (camera.speed * delta_time)).xz
	update_camera_lookat(camera)
}

update_camera_pitch_yaw :: proc(camera: ^Camera) {

	if (camera.pitch > 89.0) {
		camera.pitch = 89.0
	} else if (camera.pitch < -89.0) {
		camera.pitch = -89.0
	}
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

	camera.direction = linalg.normalize(camera.direction)

	camera.front = linalg.normalize(camera.direction)
	camera.right = linalg.cross(
		linalg.Vector3f32({f32(0.0), f32(1.0), f32(0.0)}),
		camera.direction,
	)
	camera.up = linalg.cross(camera.direction, camera.right)

	update_camera_lookat(camera)
}

update_camera_lookat :: proc(camera: ^Camera) {
	fmt.printf("Position: %2.2f\n", camera.position)
	fmt.printf("Front: %2.2f\n", camera.front)
	fmt.printf("Target: %2.2f\n", camera.position + camera.front)

	camera.lookat = linalg.matrix4_look_at_f32(
		camera.position,
		camera.position + camera.front,
		{f32(0.0), 1.0, 0.0},
	)

	fmt.println("================")
	fmt.println("=== BUILT IN ===")
	fmt.println("================")
	for i in 0 ..< 4 {
		for j in 0 ..< 4 {
			fmt.printf("%2.2f ", camera.lookat[i][j])
		}
		fmt.println()
	}
	fmt.println()

	camera.lookat = custom_lookat_matrix4f32(
		camera.position,
		camera.position + camera.front,
		{f32(0.0), 1.0, 0.0},
	)

	fmt.println("==============")
	fmt.println("=== CUSTOM ===")
	fmt.println("==============")
	for i in 0 ..< 4 {
		for j in 0 ..< 4 {
			fmt.printf("%2.2f ", camera.lookat[i][j])
		}
		fmt.println()
	}
	fmt.println()

}

custom_lookat_matrix4f32 :: proc(position, target, up: linalg.Vector3f32) -> linalg.Matrix4f32 {
	lookAt: linalg.Matrix4f32

	fmt.printf("Custom Target: %2.2f\n", target)

	direction := linalg.normalize(position - target)
	right := linalg.cross(linalg.Vector3f32({f32(0.0), f32(1.0), f32(0.0)}), direction).xyz
	cam_up := linalg.cross(direction, right)

	fmt.printf("Custom Direction: %2.2f\n", direction)
	fmt.printf("Custom Right: %2.2f\n", right)

	// I manually transposed this
	lookAt = matrix[4, 4]f32{
		right.x, right.y, right.z, 0,
		cam_up.x, cam_up.y, cam_up.z, 0,
		direction.x, direction.y, direction.z, 0,
		0, 0, 0, 1,
	}


	// Negated
	positionTransform := linalg.MATRIX4F32_IDENTITY
	positionTransform[0][3] -= position.x
	positionTransform[1][3] -= position.y
	positionTransform[2][3] -= position.z

	lookAt *= linalg.transpose(positionTransform)

	return lookAt
}
