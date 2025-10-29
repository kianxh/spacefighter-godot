# LineDebug3D.gd
extends MeshInstance3D

@export var a: Vector3 = Vector3.ZERO
@export var b: Vector3 = Vector3(0, 0, 5)

var im := ImmediateMesh.new()
var mat := StandardMaterial3D.new()

func _ready():
	mesh = im
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 1, 0)  # yellow

func _process(_dt):
	im.clear_surfaces()
	im.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	im.surface_add_vertex(a)
	im.surface_add_vertex(b)
	im.surface_end()
