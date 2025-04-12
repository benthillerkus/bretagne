shader_type canvas_item;

// Uniform textures (to be bound to simulation render targets)
uniform sampler2D height_tex : hint_default_transparent, filter_nearest; // red channel: current height, green channel: previous height
uniform sampler2D collision_tex : hint_default_transparent, filter_nearest;

// Simulation parameters
global uniform float dt = 0.0;     // time step (in seconds)
const float alpha = 0.2;   // velocity damping term
const float g = 9.81;        // gravitational acceleration

const float dx = 1.0 / 512.0;

// Includes the following generated items
// const int P (kernel radius)
// const int kernel_size (P * 2 + 1)
// float kernel_lookup[] with size kernel_size * kernel_size
#include "res://features/water/kernel_lookup_table.gdshaderinc"

// Includes the following generated items
// const float range
// float pack(float value)
// float unpack(float value)
#include "res://features/water/pack.gdshaderinc"

// Compute the vertical derivative via a convolution.
// This reads the current height field over a (2*P+1)^2 window
float convolve(vec2 uv) {
    float weightedSum = 0.0;
    // Loop over a square region centered at the current texel.
    for (int j = -P; j <= P; j++) {
        for (int i = -P; i <= P; i++) {
            // Compute texture coordinate offset (assume uniform spacing)
            vec2 offset = vec2(float(i), float(j)) * dx;
            vec4 sample = textureLod(height_tex, uv + offset, 0.0);
            float height = unpack(sample.x);
            float weight = kernel_lookup[(j + P) * kernel_size + (i + P)];
            weightedSum += height * weight;
        }
    }
    return weightedSum;
}

void fragment() {
    // Map the fragment's screen coordinate into texture UVs.    
    // Read current and previous height values.
    vec3 h = texture(height_tex, UV).xyz;
    float height = unpack(h.x);
    float prev_height = unpack(h.y);

    // Sample obstruction mask (red channel)
    float obstruction = 1.0 - texture(collision_tex, vec2(UV.x, 1.0 - UV.y)).x;

    height *= obstruction;

    // Compute the vertical derivative using convolution.
    float vert_deriv = convolve(UV);
    
    // Apply the propagation update from equation (3) in the article:
    float adt = alpha * dt;
    float adt2 = 1.0 / (1.0 + adt);
    float gravity = g * dt * dt;
    float next_height = height * (2.0 - adt) - prev_height - gravity * vert_deriv;
    next_height *= adt2;
    next_height += 0.1;
    next_height *= obstruction;
                
    COLOR = vec4(pack(next_height), pack(height), obstruction, 1.0);
    
    if (TIME < 2.0) {
      COLOR = vec4(pack(0.1), pack(0.1), 0.0, 1.0);
    }
}