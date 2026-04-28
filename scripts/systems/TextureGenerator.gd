class_name TextureGenerator
extends RefCounted

## 纹理生成器 - 负责生成水果的渐变纹理


## 创建水果的渐变圆形纹理
static func create_fruit_texture(radius: float, base_color: Color) -> ImageTexture:
	var texture_size: int = int(radius * 2)
	var image := Image.create(texture_size, texture_size, false, Image.FORMAT_RGBA8)

	# 计算渐变颜色
	var center_color := base_color.lightened(0.3)
	var edge_color := base_color.darkened(0.2)
	var center: Vector2 = Vector2(radius, radius)

	# 逐像素绘制径向渐变
	for y in range(texture_size):
		for x in range(texture_size):
			var pixel_pos: Vector2 = Vector2(x, y)
			var distance: float = pixel_pos.distance_to(center)

			if distance <= radius:
				var ratio: float = distance / radius
				var color: Color

				# 使用平滑的径向渐变
				if ratio < 0.5:
					var t: float = ratio * 2.0
					color = center_color.lerp(base_color, t)
				else:
					var t: float = (ratio - 0.5) * 2.0
					color = base_color.lerp(edge_color, t)

				image.set_pixel(x, y, color)
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

	return ImageTexture.create_from_image(image)
