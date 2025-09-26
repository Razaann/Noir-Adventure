shader_type canvas_item;

uniform float spacing = 25.0;
uniform float animation_progress : hint_range(0.0, 1.0) = 0.0;
uniform float dot_size : hint_range(0.0, 1.0) = 1.0;
uniform vec4 dot_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
    // 1. Force complete invisibility when progress is zero.
    if (animation_progress <= 0.0) {
        discard; // Key fix: only keep discard
    }
	
    // 2. Calculate the screen grid dimensions.
    vec2 screen_size = vec2(1.0) / SCREEN_PIXEL_SIZE;
    vec2 grid_count = floor(screen_size / spacing);	
	
    // 3. Calculate the normalized grid position [0,1].
    vec2 norm_pos = UV * screen_size / (grid_count * spacing);
	
    // 4. Diagonal delay calculation (top-left 0 → bottom-right 1).
    float delay = 1.0 - norm_pos.y;
	
    // 5. Dual filtering mechanism.
    // Mechanism 1: Position-based delay threshold.
    float visible_threshold = delay * 0.1 + 0.01; // A threshold that increases with the delay.
    if (animation_progress < visible_threshold) {
        discard;
    }	
	
    // 6. Dynamic transition calculation.
    float transition = 0.3;
    float scale = smoothstep(
        delay - transition,
        delay + transition,
        animation_progress * (1.0 + transition)
    );	
	
    // Mechanism 2: Size-based filtering.
    if (scale < 0.005) { // Completely eliminate tiny remnants.
        discard;
    }
    
    // 7. Calculate the dot.
    vec2 grid_center = (floor(UV * screen_size / spacing) + 0.5) * spacing;
    float dist = length(UV * screen_size - grid_center);
    float dot_radius = dot_size * scale * spacing * 0.8;
    
    // 8. Edge softening (to prevent any remnants).
    float alpha = 1.0 - smoothstep(
        max(dot_radius - 1.5, 0.0),
        dot_radius + 1.5, 
        dist
    );
    
    // Mechanism 3: Alpha value filtering.
    if (alpha < 0.01) discard;	
    
    COLOR = vec4(dot_color.rgb, alpha);
}