shader_type canvas_item;

// Uniform textures (to be bound to simulation render targets)
uniform sampler2D height_tex; // red channel: current height, green channel: previous height
uniform sampler2D collision_tex;

// Simulation parameters
global uniform float dt = 0.016;     // time step (in seconds)
uniform float alpha = 0.9;   // velocity damping term
uniform float g = -9.81;        // gravitational acceleration

const float dx = 1.0 / 513.0;

// Includes the following generated items
// const int P (kernel radius)
// const int kernel_size (P * 2 + 1)
// float kernel_lookup[] with size kernel_size * kernel_size
#include "res://features/water/kernel_lookup_table.gdshaderinc"

const float range = 10.0;

float pack(float v) {
  return (v / range) * 0.5 + 0.5;
}

float unpack(float v) {
  return (v - 0.5) * 2.0 * range;
}

// Compute the vertical derivative via a convolution.
// This reads the current height field over a (2*P+1)^2 window
float convolve(vec2 uv) {
    float weightedSum = 0.0;
    // Loop over a square region centered at the current texel.
    for (int j = -P; j <= P; j++) {
        for (int i = -P; i <= P; i++) {
            // Compute texture coordinate offset (assume uniform spacing)
            vec2 offset = vec2(float(i), float(j)) * dx;
            vec4 sample = texture(height_tex, uv + offset);
            float height = unpack(sample.x);
            height *= sample.y; // Apply the mask (green channel)
            
            float weight = kernel_lookup[(j + P) * kernel_size + (i + P)];
            weightedSum += height * weight;
        }
    }
    return weightedSum;
}

void fragment() {
    // Map the fragment's screen coordinate into texture UVs.    
    // Read current and previous height values.
    vec2 h = texture(height_tex, UV).xy;
    float height = unpack(h.x);
    float prev_height = unpack(h.y);

    // Sample obstruction mask (red channel)
    float obstruction = 1.0 - texture(collision_tex, vec2(UV.x, 1.0 - UV.y)).x;

    height *= obstruction;

    float dtc = dt;

    // Compute the vertical derivative using convolution.
    float vert_deriv = convolve(UV);
    
    // Apply the propagation update from equation (3) in the article:
    float adt = alpha * dtc;
    float adt2 = 1.0 / (1.0 + adt);
    float next_height = height * (2.0 - adt) - prev_height - g * vert_deriv;
    next_height *= adt2;
 
    next_height *= obstruction;

    next_height *= 0.4;
                
    COLOR = vec4(pack(next_height), pack(height), obstruction, 1.0);
    
    if (TIME < 2.0) {
      COLOR = vec4(pack(0.2), pack(0.2), 0.0, 1.0);
    }
}