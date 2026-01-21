extends Sprite2D

func _ready():
	# 1. Resize immediately when the game starts
	apply_cover_scale()
	
	# 2. Listen for screen size changes (like rotating phone)
	get_viewport().size_changed.connect(apply_cover_scale)

func apply_cover_scale():
	if texture == null: return
	
	# A. Get the current screen size and image size
	var viewport_size = get_viewport_rect().size
	var image_size = texture.get_size()
	
	# B. Calculate how much we need to scale up to fill width vs height
	var scale_x = viewport_size.x / image_size.x
	var scale_y = viewport_size.y / image_size.y
	
	# C. "Cover" Mode: Pick the LARGER scale so no gaps appear
	var final_scale = max(scale_x, scale_y)
	
	# D. Apply the scale
	scale = Vector2(final_scale, final_scale)
	
	# E. Center the image on the screen
	position = viewport_size / 2
