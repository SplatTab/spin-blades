shader_type canvas_item;

// The color you want to turn the white pixels into
uniform vec4 replace_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);

// Sensitivity threshold (0.0 means exact match, 1.0 matches everything)
uniform float tolerance : hint_range(0.0, 1.0) = 0.05;

void fragment() {
    // Get the current pixel color from the sprite texture
    vec4 current_color = texture(TEXTURE, UV);
    
    // Target color to detect (White: 1.0, 1.0, 1.0)
    vec3 target_color = vec3(1.0, 1.0, 1.0);
    
    // Calculate how close the pixel is to pure white
    float color_distance = distance(current_color.rgb, target_color);
    
    // If the pixel is white (within our tolerance), swap the color
    if (color_distance <= tolerance) {
        // Keep the original alpha channel so transparency doesn't break
        COLOR = vec4(replace_color.rgb, current_color.a);
    } else {
        // Leave all other pixels exactly as they are
        COLOR = current_color;
    }
}