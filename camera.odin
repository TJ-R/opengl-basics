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
}

// Should overload this?
init_camera :: proc(camera: ^Camera) {
	camera.speed = 0.05
	camera.target = {f32(0.0), f32(0.0), f32(0.0)} // Can use target if trying to track something
	camera.position = {f32(0.0), f32(0.0), f32(3.0)}
	camera.front = {f32(0.0), 0.0, -1.0}

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
}

move_camera_forward :: proc(camera: ^Camera) {
	camera.position -= (camera.direction + {f32(0.0), 0.0, camera.speed})
	update_camera_lookat(camera)
}

move_camera_backward :: proc(camera: ^Camera) {
	camera.position += (camera.direction + {f32(0.0), 0.0, camera.speed})
	update_camera_lookat(camera)
}

move_camera_right :: proc(camera: ^Camera) {
	camera.position += (camera.right + {camera.speed, f32(0.0), f32(0.0)})
	update_camera_lookat(camera)
}

move_camera_left :: proc(camera: ^Camera) {
	camera.position -= (camera.right + {camera.speed, f32(0.0), f32(0.0)})
	update_camera_lookat(camera)
}

update_camera_lookat :: proc(camera: ^Camera) {
	camera.lookat = linalg.matrix4_look_at_f32(
		camera.position,
		camera.position + camera.front,
		{f32(0.0), 1.0, 0.0},
	)
}
