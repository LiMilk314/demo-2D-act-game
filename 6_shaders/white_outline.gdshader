shader_type canvas_item;

void fragment() {
    // 获取原始颜色
    vec4 col = texture(TEXTURE, UV);
    
    // 计算单像素步长
    vec2 pixel = 1.0 / vec2(textureSize(TEXTURE, 0));
    
    // 四方向采样
    float edge = max(
        max(texture(TEXTURE, UV + vec2(pixel.x, 0)).a,
            texture(TEXTURE, UV - vec2(pixel.x, 0)).a),
        max(texture(TEXTURE, UV + vec2(0, pixel.y)).a,
            texture(TEXTURE, UV - vec2(0, pixel.y)).a)
    );
    
    // 仅在外轮廓生成描边
    COLOR = (col.a == 0.0 && edge > 0.0) ? vec4(1.0) : col;
}