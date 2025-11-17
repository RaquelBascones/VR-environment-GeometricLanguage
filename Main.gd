extends Node3D

# --- Variables de la Escena ---
var room: Node3D
var ghost: Node3D
var camera_controller: Node3D
var camera_origin: Node3D
var main_camera: Camera3D

# Variables para el ghost
var ghost_container: Node3D
var ghost_body: StaticBody3D
var ghost_mesh: MeshInstance3D

# Variables de control (usadas en _ready y _process)
var ghost_position_index = 0
var ghost_positions = [
	Vector3(0, 0, 0),
	Vector3(3, 0, 5),
	Vector3(-3, 0, -5),
	Vector3(6, 0, -3),
	Vector3(-6, 0, 3)
]
var ghost_move_speed = 0.5
var ghost_target_position: Vector3
var ghost_look_target: Vector3

# Variables para la Rotación de la Cámara
var camera_angle = 0.0
var camera_radius = 12.0
var camera_height = 2.5
var camera_speed = 0.1

# --- Función de Inicialización (Godot llama a esto una vez al inicio) ---
func _ready():
	# 1. Construir la escena (la habitación y sus objetos)
	_build_room()
	
	# 2. Inicializar la cámara
	_build_camera()
	
	# 3. Inicializar el objetivo de movimiento del fantasma
	if ghost:
		ghost_target_position = ghost_positions[ghost_position_index]
		ghost_look_target = camera_controller.global_transform.origin
		
# --- Función de Procesamiento (Godot llama a esto en cada fotograma) ---
func _process(delta):
	_update_camera(delta)
	_update_ghost_position(delta)

# --- Funciones de Construcción y Lógica ---

## Función para generar diferentes formas 3D simples
func _make_shape_mesh(code: int) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.from_hsv(fmod(code * 0.1, 1.0), 0.7, 0.9)
	mi.material_override = mat

	# Usaremos un match para crear el tipo de malla correcto
	match code:
		1: mi.mesh = BoxMesh.new() # Cubo
		2: mi.mesh = SphereMesh.new() # Esfera
		3: mi.mesh = CapsuleMesh.new() # Cápsula
		4: mi.mesh = CylinderMesh.new() # Cilindro
		5: mi.mesh = PrismMesh.new() # Prisma (Cuña)
		6: mi.mesh = QuadMesh.new() # Plano 2D
		8: mi.mesh = PlaneMesh.new() # Plano
		# Los casos 7, 9, 10 y 11 se omiten por dar errores de tipo o no ser mallas renderizables
		12: 
			var torus := TorusMesh.new()
			torus.outer_radius = 0.5  
			torus.inner_radius = 0.15
			mi.mesh = torus
			# CORRECCIÓN: Rotar la instancia (mi), no el recurso de malla (torus)
			mi.rotate_x(PI/2.0) 
		_: 
			mi.mesh = BoxMesh.new() # Default a cubo si no se especifica
			
	return mi

## Función para construir el cuerpo del fantasma
func _create_ghost_anatomical(parent: Node3D):
	ghost_container = Node3D.new()
	ghost_container.name = "Ghost"
	parent.add_child(ghost_container)
	
	# Body (cuerpo)
	ghost_body = StaticBody3D.new()
	ghost_container.add_child(ghost_body)
	ghost_body.position.y = -1.5 # Lo baja para que esté al nivel del suelo (y=-2)

	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.0, 0.8, 1.0, 0.5) # Azul turquesa semitransparente
	body_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	body_mat.cull_mode = BaseMaterial3D.CULL_DISABLED # Para verlo por ambos lados
	
	# Cabeza (SphereMesh)
	var head = MeshInstance3D.new()
	ghost_body.add_child(head)
	head.mesh = SphereMesh.new()
	head.scale = Vector3(0.5, 0.5, 0.5)
	head.position = Vector3(0, 2.0, 0)
	head.material_override = body_mat
	
	# Tronco (CapsuleMesh)
	var torso = MeshInstance3D.new()
	ghost_body.add_child(torso)
	torso.mesh = CapsuleMesh.new()
	torso.scale = Vector3(1.0, 1.0, 1.0)
	torso.position = Vector3(0, 1.0, 0)
	torso.material_override = body_mat
	
	# Ojos (SphereMesh sin transparencia)
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color.WHITE
	
	var eye_l = MeshInstance3D.new()
	head.add_child(eye_l)
	eye_l.mesh = SphereMesh.new()
	eye_l.scale = Vector3(0.1, 0.1, 0.1)
	eye_l.position = Vector3(-0.15, 0.1, 0.45)
	eye_l.material_override = eye_mat
	
	var eye_r = MeshInstance3D.new()
	head.add_child(eye_r)
	eye_r.mesh = SphereMesh.new()
	eye_r.scale = Vector3(0.1, 0.1, 0.1)
	eye_r.position = Vector3(0.15, 0.1, 0.45)
	eye_r.material_override = eye_mat
	
	ghost = ghost_container # Asigna el contenedor como la variable principal del fantasma

## Función para actualizar la posición del fantasma
func _update_ghost_position(delta):
	if not ghost: return

	var current_pos = ghost.position
	
	# Mover al objetivo
	var velocity = (ghost_target_position - current_pos).normalized() * ghost_move_speed * delta
	ghost.position += velocity

	# Comprobar si ha llegado al objetivo
	if current_pos.distance_to(ghost_target_position) < 0.1:
		# Cambiar al siguiente objetivo
		ghost_position_index = (ghost_position_index + 1) % ghost_positions.size()
		ghost_target_position = ghost_positions[ghost_position_index]

	# Rotar para mirar al centro (donde está la cámara)
	var target_direction = (ghost_look_target - ghost.position).normalized()
	var target_transform = ghost.global_transform.looking_at(ghost_look_target, Vector3.UP)
	
	# Suaviza la rotación para que no sea instantánea
	ghost.global_transform = ghost.global_transform.interpolate_with(target_transform, 0.1)

## Función para construir la cámara
func _build_camera():
	camera_controller = Node3D.new()
	camera_controller.name = "Camera_Controller"
	add_child(camera_controller)
	
	camera_origin = Node3D.new()
	camera_controller.add_child(camera_origin)
	camera_origin.position.z = camera_radius # Distancia desde el centro
	camera_origin.position.y = camera_height # Altura

	main_camera = Camera3D.new()
	camera_origin.add_child(main_camera)
	main_camera.name = "Main_Camera"
	
	# Hace que la cámara mire al centro del controlador (0,0,0)
	main_camera.look_at(Vector3.ZERO, Vector3.UP)

## Función para rotar la cámara
func _update_camera(delta):
	camera_angle += camera_speed * delta
	if camera_angle > 2 * PI:
		camera_angle -= 2 * PI
		
	camera_controller.rotation.y = camera_angle

## Función para construir la luz principal (DirectionalLight3D)
func _build_light():
	var sun := DirectionalLight3D.new()
	add_child(sun)
	sun.light_color = Color(1.0, 0.95, 0.9) # Luz ligeramente cálida
	sun.light_energy = 2.0
	sun.shadow_enabled = true
	
	# Rotar para simular luz solar entrando por la ventana trasera
	sun.rotation_degrees = Vector3(-45, 180, 0)

# --- FUNCIÓN PRINCIPAL DE CONSTRUCCIÓN DE LA ESCENA (CORREGIDA) ---
func _build_room():
	# Llama a la luz global
	_build_light()
	
	# El nodo "room" contendrá toda la geometría de la habitación
	var room := Node3D.new()
	room.name = "Room"
	add_child(room)
	
	# -----------------------------------------------------------------
	# 1. Paredes, Suelo y Techo (BoxMesh)
	# -----------------------------------------------------------------
	
	# Dimensiones de la habitación
	const ROOM_WIDTH = 15.0 # Eje X
	const ROOM_HEIGHT = 4.0 # Eje Y
	const ROOM_DEPTH = 15.0 # Eje Z
	
	# Materiales comunes
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.9, 0.9, 0.9) # Blanco roto
	
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.6, 0.5, 0.4) # Marrón claro
	floor_mat.roughness = 0.8
	
	# Función para crear una pared, suelo o techo
	var create_plane = func(size_x, size_y, pos, rot_degrees, material):
		var mesh_instance := MeshInstance3D.new()
		room.add_child(mesh_instance)
		
		var box := BoxMesh.new()
		box.size = Vector3(size_x, size_y, 0.1)
		mesh_instance.mesh = box
		
		mesh_instance.position = pos
		mesh_instance.rotation_degrees = rot_degrees
		mesh_instance.material_override = material
		return mesh_instance

	# Suelo
	create_plane.call(ROOM_WIDTH, ROOM_DEPTH, Vector3(0, -ROOM_HEIGHT/2, 0), Vector3(90, 0, 0), floor_mat)
	
	# Techo
	create_plane.call(ROOM_WIDTH, ROOM_DEPTH, Vector3(0, ROOM_HEIGHT/2, 0), Vector3(-90, 0, 0), wall_mat)
	
	# Pared Trasera (en Z negativo)
	create_plane.call(ROOM_WIDTH, ROOM_HEIGHT, Vector3(0, 0, -ROOM_DEPTH/2), Vector3(0, 0, 0), wall_mat)
	
	# Pared Delantera (en Z positivo)
	create_plane.call(ROOM_WIDTH, ROOM_HEIGHT, Vector3(0, 0, ROOM_DEPTH/2), Vector3(0, 180, 0), wall_mat)
	
	# Pared Izquierda (en X negativo)
	create_plane.call(ROOM_DEPTH, ROOM_HEIGHT, Vector3(-ROOM_WIDTH/2, 0, 0), Vector3(0, 90, 0), wall_mat)
	
	# Pared Derecha (en X positivo)
	create_plane.call(ROOM_DEPTH, ROOM_HEIGHT, Vector3(ROOM_WIDTH/2, 0, 0), Vector3(0, -90, 0), wall_mat)
	
	# -----------------------------------------------------------------
	# 2. Ventana (HoleMesh en la pared trasera)
	# -----------------------------------------------------------------
	
	var window_container := Node3D.new()
	room.add_child(window_container)
	window_container.position = Vector3(0, 1.0, -ROOM_DEPTH/2 + 0.05) # Centrada en pared trasera
	
	var window_width = 3.0
	var window_height = 2.0
	var window_depth = 0.1 
	
	var window_mat := StandardMaterial3D.new()
	window_mat.albedo_color = Color(0.8, 0.9, 1.0) # Azul claro
	window_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	window_mat.albedo_color.a = 0.5 # Transparencia
	window_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED # Para que no refleje
	
	var window_pane := MeshInstance3D.new()
	window_container.add_child(window_pane)
	window_pane.mesh = BoxMesh.new()
	window_pane.scale = Vector3(window_width, window_height, window_depth)
	window_pane.material_override = window_mat
	
	# Marco de la ventana
	var frame_thickness = 0.1 # Grosor del marco de la VENTANA
	var frame_size_x = window_width + frame_thickness * 2
	var frame_size_y = window_height + frame_thickness * 2
	
	var frame_mesh := MeshInstance3D.new()
	window_container.add_child(frame_mesh)
	
	# Crea un material para el marco (gris oscuro)
	var frame_mat := StandardMaterial3D.new() # Material del marco de la VENTANA
	frame_mat.albedo_color = Color(0.2, 0.2, 0.2)
	
	# Crea la geometría del marco usando CSGSG (más simple para un marco)
	var frame_csg := CSGCombiner3D.new()
	frame_mesh.add_child(frame_csg)
	
	# Marco exterior
	var outer_box := CSGBox3D.new()
	outer_box.size = Vector3(frame_size_x, frame_size_y, window_depth)
	outer_box.material = frame_mat
	frame_csg.add_child(outer_box)
	
	# Agujero interior
	var inner_box := CSGBox3D.new()
	inner_box.size = Vector3(window_width, window_height, window_depth + 0.1)
	inner_box.operation = CSGBox3D.OPERATION_SUBTRACTION
	frame_csg.add_child(inner_box)
	
	# -----------------------------------------------------------------
	# 3. Mesa Central (CylinderMesh)
	# -----------------------------------------------------------------
	
	var table_container := Node3D.new()
	room.add_child(table_container)
	table_container.position = Vector3(0, -ROOM_HEIGHT/2 + 0.7, 0)
	
	# Tablero (CylinderMesh)
	var table_top := MeshInstance3D.new()
	table_container.add_child(table_top)
	
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 1.5
	cylinder.bottom_radius = 1.5
	cylinder.height = 0.1 
	table_top.mesh = cylinder
	
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.4, 0.2, 0.1) 
	wood_mat.roughness = 0.5
	wood_mat.metallic = 0.1
	table_top.material_override = wood_mat
	
	# Pata (CylinderMesh)
	var table_leg := MeshInstance3D.new()
	table_container.add_child(table_leg)
	table_leg.position = Vector3(0, -0.3, 0) # Debajo del tablero
	
	var leg_cylinder := CylinderMesh.new()
	leg_cylinder.top_radius = 0.1
	leg_cylinder.bottom_radius = 0.1
	leg_cylinder.height = 1.0 
	table_leg.mesh = leg_cylinder
	table_leg.material_override = wood_mat
	
	# -----------------------------------------------------------------
	# 4. Sillas (4 SphereMesh, 4 BoxMesh)
	# -----------------------------------------------------------------
	
	var create_chair = func(pos_offset):
		var chair := Node3D.new()
		table_container.add_child(chair)
		chair.position += pos_offset
		
		var chair_mat := StandardMaterial3D.new()
		chair_mat.albedo_color = Color(0.2, 0.4, 0.2) # Verde oscuro
		
		# Asiento (BoxMesh)
		var seat := MeshInstance3D.new()
		chair.add_child(seat)
		seat.mesh = BoxMesh.new()
		seat.scale = Vector3(0.5, 0.05, 0.5)
		seat.position = Vector3(0, -0.35, 0)
		seat.material_override = chair_mat
		
		# Respaldo (BoxMesh)
		var back := MeshInstance3D.new()
		chair.add_child(back)
		back.mesh = BoxMesh.new()
		back.scale = Vector3(0.5, 0.5, 0.05)
		back.position = Vector3(0, 0, 0.225)
		back.material_override = chair_mat
		
		# Patas (CylinderMesh - 4 patas)
		var leg_mat := StandardMaterial3D.new()
		leg_mat.albedo_color = Color(0.1, 0.1, 0.1)
		
		var leg_positions = [
			Vector3(0.2, -0.575, 0.2),
			Vector3(-0.2, -0.575, 0.2),
			Vector3(0.2, -0.575, -0.2),
			Vector3(-0.2, -0.575, -0.2)
		]
		
		for p in leg_positions:
			var leg := MeshInstance3D.new()
			chair.add_child(leg)
			leg.mesh = CylinderMesh.new()
			leg.mesh.height = 0.45
			leg.mesh.top_radius = 0.03
			leg.mesh.bottom_radius = 0.03
			leg.position = p
			leg.material_override = leg_mat
			
	# Posicionar las 4 sillas alrededor de la mesa
	var radius = 2.0
	create_chair.call(Vector3(0, 0, radius)) # Silla 1 (Frente)
	create_chair.call(Vector3(0, 0, -radius)) # Silla 2 (Atrás)
	create_chair.call(Vector3(radius, 0, 0)) # Silla 3 (Derecha)
	create_chair.call(Vector3(-radius, 0, 0)) # Silla 4 (Izquierda)

	# -----------------------------------------------------------------
	# 5. Alfombra (PlaneMesh)
	# -----------------------------------------------------------------
	
	var carpet := MeshInstance3D.new()
	room.add_child(carpet)
	
	var plane := PlaneMesh.new()
	plane.size = Vector2(7.0, 7.0) # Alfombra grande
	carpet.mesh = plane
	
	var carpet_mat := StandardMaterial3D.new()
	carpet_mat.albedo_color = Color(0.8, 0.4, 0.4) # Rojo claro
	carpet_mat.roughness = 0.7
	carpet_mat.metallic = 0.0
	carpet.material_override = carpet_mat
	
	carpet.position = Vector3(0, -ROOM_HEIGHT/2 + 0.01, 0)
	
	# -----------------------------------------------------------------
	# 6. Lámpara de Techo (SphereMesh + SpotLight3D)
	# -----------------------------------------------------------------
	
	var ceiling_lamp_container := Node3D.new()
	room.add_child(ceiling_lamp_container)
	ceiling_lamp_container.position = Vector3(0, ROOM_HEIGHT/2 - 0.2, 0)
	
	var lamp_mesh := MeshInstance3D.new()
	ceiling_lamp_container.add_child(lamp_mesh)
	
	var sphere := SphereMesh.new()
	sphere.radius = 0.4
	sphere.height = 0.4
	lamp_mesh.mesh = sphere
	
	var lamp_mat := StandardMaterial3D.new()
	lamp_mat.albedo_color = Color(0.9, 0.9, 0.5) # Amarillo pálido
	lamp_mat.emission_enabled = true
	lamp_mat.emission = Color.WHITE
	lamp_mat.emission_energy_multiplier = 0.5
	lamp_mesh.material_override = lamp_mat
	
	# Luz que ilumina
	var lamp_light := SpotLight3D.new()
	ceiling_lamp_container.add_child(lamp_light)
	lamp_light.light_color = Color(1.0, 1.0, 0.8) # Luz cálida
	lamp_light.light_energy = 5.0
	lamp_light.spot_range = 10.0
	lamp_light.spot_angle = 60.0
	lamp_light.position = Vector3(0, -0.2, 0)
	
	# -----------------------------------------------------------------
	# 7. Objetos 3D simples (MeshInstance3D)
	# -----------------------------------------------------------------
	
	var create_object = func(code, pos, rot_y):
		var obj_container = _make_shape_mesh(code) # Utiliza tu función existente
		room.add_child(obj_container)
		obj_container.position = pos
		obj_container.rotate_y(deg_to_rad(rot_y))
		obj_container.scale = Vector3.ONE * 0.3 # Tamaño
		
		# Coloca en la mesa
		obj_container.position.y += table_container.position.y + 0.1
	
	# Cubo
	create_object.call(1, Vector3(0.5, 0, 0.5), 0)
	# Esfera
	create_object.call(2, Vector3(-0.5, 0, 0.5), 0)
	# Cápsula
	create_object.call(3, Vector3(0.5, 0, -0.5), 45)
	# Torus (Donut)
	create_object.call(12, Vector3(-0.5, 0, -0.5), 90)
	
	# -----------------------------------------------------------------
	# 8. Personaje Fantasma (Ghost)
	# -----------------------------------------------------------------
	
	_create_ghost_anatomical(room)
	
	# -----------------------------------------------------------------
	# 9. Obra de Arte Personalizada (CORREGIDA Y ESCALADA)
	# -----------------------------------------------------------------
	
	var art_container := Node3D.new()
	room.add_child(art_container)
	
	# Posición: Cerca de la pared derecha (X=7.38), a 1.8m de altura.
	art_container.position = Vector3(ROOM_WIDTH/2 - 0.1, 1.8, -7.0) 
	
	# Rotación: Rota -90 grados para mirar hacia X negativo (hacia la habitación)
	art_container.rotation_degrees = Vector3(0, -90, 0) 
	
	# MEJORA: Aumentar el tamaño general del cuadro (1.2 = 20% más grande)
	art_container.scale = Vector3.ONE * 1.2 
	
	# ** REEMPLAZA ESTA RUTA POR LA RUTA REAL DE TU IMAGEN JPG/PNG **
	const ART_IMAGE_PATH = "res://images/supernenas.jpg"
	
	var image_texture: Texture2D
	var image_aspect_ratio := 1.0 # Valor predeterminado (cuadrado)
	
	if FileAccess.file_exists(ART_IMAGE_PATH):
		image_texture = load(ART_IMAGE_PATH)
		
		# CALCULAR RELACIÓN DE ASPECTO
		if image_texture:
			image_aspect_ratio = float(image_texture.get_width()) / float(image_texture.get_height())
	else:
		# Crea un placeholder morado
		print("ADVERTENCIA: Archivo de arte no encontrado en la ruta: " + ART_IMAGE_PATH)
		var white_image := Image.create(100, 100, false, Image.FORMAT_RGB8)
		white_image.fill(Color.PURPLE)
		image_texture = ImageTexture.create_from_image(white_image)

	# 9a. Material del Arte (El lienzo)
	var art_mat := StandardMaterial3D.new()
	art_mat.albedo_color = Color.WHITE
	art_mat.albedo_texture = image_texture
	art_mat.roughness = 0.9
	art_mat.metallic = 0.0
	
	# 9b. Geometría del Arte (Lienzo delgado)
	var art_mesh := MeshInstance3D.new()
	art_container.add_child(art_mesh)
	art_mesh.mesh = BoxMesh.new()
	
	# USAR RELACIÓN DE ASPECTO PARA LAS DIMENSIONES
	var base_height = 2.0 # Altura de referencia (2.0 metros)
	var art_height = base_height
	var art_width = base_height * image_aspect_ratio # El ancho se ajusta automáticamente
	var art_depth = 0.01 
	
	art_mesh.scale = Vector3(art_width, art_height, art_depth) 
	art_mesh.position = Vector3(0, 0, 0.02)
	art_mesh.material_override = art_mat
	
	# 9c. Marco Negro (Frame)
	var frame := MeshInstance3D.new()
	art_container.add_child(frame)
	frame.mesh = BoxMesh.new()
	
	var art_frame_thickness = 0.05 # CORRECCIÓN: Grosor del marco del ARTE (variable única)
	
	# La escala del marco usa las dimensiones ajustadas
	frame.scale = Vector3(art_width + art_frame_thickness, art_height + art_frame_thickness, 0.05)
	frame.position = Vector3(0, 0, 0)
	
	# CORRECCIÓN: Usamos un nombre único para el material del marco del arte
	var art_frame_mat := StandardMaterial3D.new() # CORRECCIÓN: Material del marco del ARTE (variable única)
	art_frame_mat.albedo_color = Color(0.05, 0.05, 0.05) 
	art_frame_mat.roughness = 0.1
	art_frame_mat.metallic = 0.1
	frame.material_override = art_frame_mat

	# -----------------------------------------------------------------
	# 10. Lámpara de Pie (SphereMesh + OmniLight3D)
	# -----------------------------------------------------------------
	
	var floor_lamp_container := Node3D.new()
	room.add_child(floor_lamp_container)
	floor_lamp_container.position = Vector3(ROOM_WIDTH/2 - 0.5, -ROOM_HEIGHT/2, 4.0)
	
	# Base (CylinderMesh)
	var lamp_base := MeshInstance3D.new()
	floor_lamp_container.add_child(lamp_base)
	lamp_base.mesh = CylinderMesh.new()
	lamp_base.scale = Vector3(0.5, 0.1, 0.5)
	lamp_base.material_override = art_frame_mat
	
	# Soporte (CylinderMesh)
	var lamp_stand := MeshInstance3D.new()
	floor_lamp_container.add_child(lamp_stand)
	lamp_stand.mesh = CylinderMesh.new()
	lamp_stand.scale = Vector3(0.05, 3.5, 0.05)
	lamp_stand.position = Vector3(0, 1.75, 0)
	lamp_stand.material_override = art_frame_mat
	
	# Pantalla (SphereMesh)
	var lamp_shade := MeshInstance3D.new()
	floor_lamp_container.add_child(lamp_shade)
	lamp_shade.mesh = SphereMesh.new()
	lamp_shade.mesh.radius = 0.5
	lamp_shade.mesh.height = 0.5
	lamp_shade.position = Vector3(0, 3.5, 0)
	
	var shade_mat := StandardMaterial3D.new()
	shade_mat.albedo_color = Color(1.0, 1.0, 0.9) # Amarillo muy pálido
	shade_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shade_mat.albedo_color.a = 0.8 # Ligeramente transparente
	shade_mat.emission_enabled = true
	shade_mat.emission = Color.WHITE
	shade_mat.emission_energy_multiplier = 0.8
	lamp_shade.material_override = shade_mat
	
	# Luz que ilumina
	var omni_light := OmniLight3D.new()
	floor_lamp_container.add_child(omni_light)
	omni_light.light_color = Color(1.0, 1.0, 0.9) # Luz cálida
	omni_light.light_energy = 3.5
	omni_light.omni_range = 8.0
	omni_light.position = Vector3(0, 3.5, 0)
	
	# -----------------------------------------------------------------
	# 11. Escena de la Planta (Plano de ejemplo)
	# -----------------------------------------------------------------
	
	var plant_container := Node3D.new()
	room.add_child(plant_container)
	plant_container.position = Vector3(-ROOM_WIDTH/2 + 0.5, -ROOM_HEIGHT/2, 4.0)
	
	var pot_mat := StandardMaterial3D.new()
	pot_mat.albedo_color = Color(0.6, 0.3, 0.0)
	
	# Maceta (CylinderMesh)
	var pot := MeshInstance3D.new()
	plant_container.add_child(pot)
	pot.mesh = CylinderMesh.new()
	pot.scale = Vector3(0.3, 0.5, 0.3)
	pot.material_override = pot_mat
	
	# Planta (SphereMesh verde)
	var plant := MeshInstance3D.new()
	plant_container.add_child(plant)
	plant.mesh = SphereMesh.new()
	plant.scale = Vector3(0.4, 0.4, 0.4)
	plant.position = Vector3(0, 0.5, 0)
	
	var plant_mat := StandardMaterial3D.new()
	plant_mat.albedo_color = Color(0.2, 0.7, 0.2)
	plant_mat.roughness = 0.3
	plant.material_override = plant_mat
