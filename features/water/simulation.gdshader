// This shader implements a simplified iWave simulation pass.
// It uses two textures:
//   • height_tex: the current water height field (as red channel)
//   • prev_height_tex: the water height from the previous time step
// It computes a convolution to approximate the vertical derivative,
// then updates the wave heights according to the finite–difference formula:
//   h_next = ( h * (2 - α · dt) - prev_h - (vert_deriv * g * dt²) )
//            / (1 + α · dt)
//
// To simulate interactivity, one could also add extra source or obstruction
// terms. Here we focus on the core propagation.
//
// The simulation is done in a fragment shader that writes the new height (in red)
// into an output texture, which would be ping-ponged over successive frames.
shader_type canvas_item;

// Uniform textures (to be bound to simulation render targets)
uniform sampler2D height_tex;      // current height field (red channel)
uniform sampler2D prev_height_tex;  // previous height field (red channel)

// Simulation parameters
uniform float dt = 0.016;     // time step (in seconds)
uniform float alpha = 0.02;   // damping / friction coefficient
uniform float g = 9.8;        // gravitational acceleration

// The size (in texels) of the simulation grid/texture
uniform vec2 tex_size; 

// The convolution kernel size: using a radius of 6 (so kernel is 13x13)
const int kernel_radius = 6;

// A simple function to approximate kernel weights.
// In the paper the kernel is derived from fluid dynamics (with Bessel functions),
// but here we use a Gaussian for demonstration. Adjust sigma to tune the "spread."
float kernelWeight(int i, int j) {
    // Compute distance (in grid units) from the kernel’s center:
    float dist = length(vec2(float(i), float(j)));
    // sigma controls the width of the Gaussian; here set roughly to kernel_radius/2.
    float sigma = float(kernel_radius) / 2.0;
    return exp(-dist * dist / (2.0 * sigma * sigma));
}

// Compute the vertical derivative via a convolution.
// This reads the current height field over a (2*kernel_radius+1)^2 window,
// weights it by the kernel, and normalizes by the sum of weights.
float computeConvolution(vec2 uv) {
    float weightedSum = 0.0;
    float weightTotal = 0.0;
    // Loop over a square region centered at the current texel.
    for (int j = -kernel_radius; j <= kernel_radius; j++) {
        for (int i = -kernel_radius; i <= kernel_radius; i++) {
            // Compute texture coordinate offset (assume uniform spacing)
            vec2 offset = vec2(float(i), float(j)) / tex_size;
            float w = kernelWeight(i, j);
            weightedSum += texture(height_tex, uv + offset).r * w;
            weightTotal += w;
        }
    }
    // Normalize the convolution result.
    return weightedSum / weightTotal;
}

void fragment() {
    // Map the fragment's screen coordinate into texture UVs.
    vec2 uv = FRAGCOORD.xy / tex_size;
    
    // Read current and previous height values.
    float h = texture(height_tex, uv).r;
    float prev_h = texture(prev_height_tex, uv).r;
    
    // Compute the vertical derivative using convolution.
    float vert_deriv = computeConvolution(uv);
    
    // Apply the propagation update from equation (3) in the article:
    // h_next = (h*(2.0 - alpha * dt) - prev_h - vert_deriv * g * dt*dt) / (1.0 + alpha * dt)
    float numerator = h * (2.0 - alpha * dt) - prev_h - vert_deriv * g * dt * dt;
    float h_next = numerator / (1.0 + alpha * dt);
    
    // (Optional) You could blend in source or obstruction terms here.
    // For example, if you had:
    // uniform sampler2D source_tex;
    // uniform sampler2D obstruction_tex;
    // then you might write:
    // h_next += texture(source_tex, uv).r;
    // h_next *= texture(obstruction_tex, uv).r;
    
    // Output the updated height field (in the red channel; other channels can be zero).
    COLOR = vec4(h_next, 0.0, 0.0, 1.0);
}