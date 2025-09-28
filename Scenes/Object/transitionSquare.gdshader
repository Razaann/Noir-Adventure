shader_type canvas_item;

// Controls the animation from 0.0 (fully black) to 1.0 (fully revealed)
uniform float progress : hint_range(0.0, 1.0) = 0.0;

// The color of the overlay that gets wiped away
uniform vec4 overlay_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

// How soft the edge of the expanding square is
uniform float softness : hint_range(0.0, 0.5) = 0.05;

void fragment() {
    // 1. Get the original color of the pixel from the texture.
    vec4 original_color = texture(TEXTURE, UV);

    // 2. Define the center point of the screen (0.5, 0.5).
    vec2 center = vec2(0.5);

    // 3. Calculate the distance from the center for a square shape.
    // We use the maximum of the horizontal and vertical distances.
    // This is known as Chebyshev distance.
    float dist = max(abs(UV.x - center.x), abs(UV.y - center.y));

    // 4. Determine the current size of the reveal square based on progress.
    // The maximum distance from the center to any edge is 0.5.
    float size = progress * 0.5;

    // 5. Use smoothstep to create a soft transition instead of a hard edge.
    // This calculates how much of the overlay should be visible.
    float mask = smoothstep(size, size - softness, dist);

    // 6. Mix the original color and the overlay color using the mask.
    // When the mask is 1.0, it shows the overlay; when 0.0, the original color.
    COLOR = mix(original_color, overlay_color, mask);
}