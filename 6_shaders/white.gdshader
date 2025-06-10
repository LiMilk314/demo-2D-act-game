// white_texture.gdshader
shader_type canvas_item;

void fragment() {
    // 获取原始纹理的alpha值
    float alpha = texture(TEXTURE, UV).a;
    
    // 输出纯白色并保持原有透明度
    COLOR = vec4(1.0, 1.0, 1.0, alpha);
}