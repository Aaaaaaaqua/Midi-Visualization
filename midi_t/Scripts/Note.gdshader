shader_type canvas_item;

uniform float highlight_intensity : hint_range(0.0, 5.0) = 0.0;
uniform vec3 highlight_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float bloom_threshold : hint_range(0.0, 2.0) = 1.0;
uniform float glow_radius : hint_range(0.0, 1.0) = 0.3;

varying vec2 world_position;
varying vec2 local_uv;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
    local_uv = UV;
}

void fragment() {
    vec4 original_color = COLOR;

    // 计算从中心的距离，用于辉光效果
    vec2 center = vec2(0.5, 0.5);
    float distance_from_center = distance(local_uv, center);

    // 基础高亮效果
    vec3 final_color = original_color.rgb;
    float final_alpha = original_color.a;

    if (highlight_intensity > 0.0) {
        // 使用音符自身颜色作为高亮颜色，而不是白色
        vec3 self_glow_color = original_color.rgb;

        // 增强高亮效果 - 更强烈的自身颜色亮度提升
        vec3 hdr_color = final_color * (1.0 + highlight_intensity * 2.0);
        hdr_color += self_glow_color * highlight_intensity * 1.2;

        // 辉光效果 - 从中心向外扩散，使用自身颜色
        float glow_factor = 1.0 - smoothstep(0.0, glow_radius, distance_from_center);
        glow_factor = pow(glow_factor, 1.5);  // 降低指数，让辉光更广泛

        // 混合辉光 - 使用音符自身颜色，增强强度
        hdr_color += self_glow_color * glow_factor * highlight_intensity * 0.8;

        // 边缘发光 - 使用自身颜色，增强效果
        float edge_glow = 1.0 - smoothstep(0.2, 0.6, distance_from_center);
        hdr_color += self_glow_color * edge_glow * highlight_intensity * 0.6;

        // 额外的内部发光效果
        float inner_glow = 1.0 - smoothstep(0.0, 0.4, distance_from_center);
        hdr_color += self_glow_color * inner_glow * highlight_intensity * 0.4;

        final_color = hdr_color;

        // 限制Alpha值不超过1.0，但允许在高亮时稍微增强
        final_alpha = min(original_color.a * (1.0 + highlight_intensity * 0.1), 1.0);
    }

    COLOR = vec4(final_color, final_alpha);
}
