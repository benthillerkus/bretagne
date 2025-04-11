import math
import numpy as np
import matplotlib.pyplot as plt
from matplotlib import cm
import os

def bessel_function(x):
    """
    Implementation of Bessel function J₀(x) based on approximations from
    http://people.math.sfu.ca/~cbm/aands/frameindex.htm (pages 369-370)
    """
    if x <= -3:
        print("Warning: x is smaller than -3, result may be inaccurate")
    
    # 9.4.1 approximation for -3 <= x <= 3
    if x <= 3:
        # Ignored the small rest term at the end
        return (1 - 
                2.2499997 * (x/3)**2 + 
                1.2656208 * (x/3)**4 - 
                0.3163866 * (x/3)**6 + 
                0.0444479 * (x/3)**8 - 
                0.0039444 * (x/3)**10 + 
                0.0002100 * (x/3)**12)
    
    # 9.4.3 approximation for 3 <= x <= infinity
    else:
        f_zero = (0.79788456 - 
                  0.00000077 * (3/x)**1 - 
                  0.00552740 * (3/x)**2 - 
                  0.00009512 * (3/x)**3 - 
                  0.00137237 * (3/x)**4 - 
                  0.00072805 * (3/x)**5 + 
                  0.00014476 * (3/x)**6)
        
        theta_zero = (x - 
                     0.78539816 - 
                     0.04166397 * (3/x)**1 - 
                     0.00003954 * (3/x)**2 - 
                     0.00262573 * (3/x)**3 - 
                     0.00054125 * (3/x)**4 - 
                     0.00029333 * (3/x)**5 + 
                     0.00013558 * (3/x)**6)
        
        return (x**(-1/3)) * f_zero * math.cos(theta_zero)

def calculate_g_zero():
    """Calculate G_zero value used for normalization"""
    delta_q = 0.001
    sigma = 1.0
    
    g_zero = 0.0
    for n in range(1, 10001):
        q_n_square = (n * delta_q) ** 2
        g_zero += q_n_square * math.exp(-sigma * q_n_square)
    
    return g_zero

def calculate_g(k, l, g_zero):
    """Calculate G(k,l) kernel value"""
    delta_q = 0.001
    sigma = 1.0
    r = math.sqrt(k*k + l*l)
    
    g = 0.0
    for n in range(1, 10001):
        q_n = n * delta_q
        q_n_square = q_n * q_n
        g += q_n_square * math.exp(-sigma * q_n_square) * bessel_function(q_n * r)
    
    g /= g_zero
    
    return g

def precompute_kernel_values(P):
    """Precompute the kernel values G(k,l) for a kernel of size 2P+1 x 2P+1"""
    # Calculate G_zero for normalization
    g_zero = calculate_g_zero()
    
    # Create kernel array
    kernel_size = 2 * P + 1
    kernel = np.zeros((kernel_size, kernel_size))
    
    print(f"Computing {kernel_size}x{kernel_size} kernel values...")
    
    # Fill the kernel array
    for k in range(-P, P + 1):
        print(f"Row {k+P+1}/{kernel_size}")
        for l in range(-P, P + 1):
            kernel[k + P, l + P] = calculate_g(float(k), float(l), g_zero)
    
    return kernel

def format_for_glsl(kernel, P):
    """Format the kernel values as a GLSL-compatible float array"""
    kernel_size = 2 * P + 1
    
    # Start the GLSL string
    glsl: str = ""
    glsl += f"const int kernel_size = {kernel_size};\n"
    glsl += f"const int P = {P};\n"
    glsl += f"\n"
    glsl += f"// {kernel_size}x{kernel_size} kernel lookup table\n"
    glsl += f"const float kernel_lookup[{kernel_size * kernel_size}] = float[](\n"
    
    # Add each value
    values = []
    for i in range(kernel_size):
        for j in range(kernel_size):
            values.append(f"{kernel[i, j]:.8f}")
    
    # Format with 4 values per line
    lines = []
    for i in range(0, len(values), 4):
        lines.append("    " + ", ".join(values[i:i+4]))
    
    glsl += ",\n".join(lines)
    glsl += "\n);"
    
    return glsl

def visualize_kernel(kernel, P, output_path="kernel_visualization.png"):
    """
    Generate a PNG visualization of the kernel values.
    Handles both positive and negative values with different colors.
    """
    kernel_size = 2 * P + 1
    
    # Create figure
    plt.figure(figsize=(10, 8))
    
    # Create main heatmap plot
    ax = plt.subplot(111)
    
    # Determine the range for better visualization
    abs_max = max(abs(np.max(kernel)), abs(np.min(kernel)))
    vmin = -abs_max
    vmax = abs_max
    
    # Use a diverging colormap to show positive and negative values differently
    # 'RdBu_r' uses red for negative values and blue for positive
    heatmap = ax.imshow(kernel, cmap='RdBu_r', vmin=vmin, vmax=vmax)
    
    # Add colorbar
    cbar = plt.colorbar(heatmap)
    cbar.set_label('Kernel Value')
    
    # Add grid lines to separate cells
    ax.set_xticks(np.arange(-.5, kernel_size, 1), minor=True)
    ax.set_yticks(np.arange(-.5, kernel_size, 1), minor=True)
    ax.grid(which='minor', color='black', linestyle='-', linewidth=1)
    
    # Add labels
    plt.title(f'{kernel_size}x{kernel_size} Kernel Visualization')
    plt.xlabel('Column Index (l)')
    plt.ylabel('Row Index (k)')
    
    # Add annotations with actual values
    for i in range(kernel_size):
        for j in range(kernel_size):
            value = kernel[i, j]
            text_color = 'white' if abs(value) > abs_max * 0.7 else 'black'
            ax.text(j, i, f"{value:.3f}", ha="center", va="center", color=text_color, fontsize=8)
    
    # Save figure
    plt.tight_layout()
    plt.savefig(output_path, dpi=150)
    print(f"Kernel visualization saved to: {output_path}")
    
    # Additional 3D visualization
    fig = plt.figure(figsize=(10, 8))
    ax = fig.add_subplot(111, projection='3d')
    
    # Create X, Y coordinates for the grid
    x = np.arange(-P, P+1)
    y = np.arange(-P, P+1)
    x_grid, y_grid = np.meshgrid(x, y)
    
    # Plot the 3D surface
    surf = ax.plot_surface(x_grid, y_grid, kernel, cmap=cm.coolwarm, linewidth=0, antialiased=False)
    
    # Add colorbar and labels
    fig.colorbar(surf, ax=ax, shrink=0.5, aspect=5)
    ax.set_title(f'{kernel_size}x{kernel_size} Kernel 3D Visualization')
    ax.set_xlabel('Column Index (l)')
    ax.set_ylabel('Row Index (k)')
    ax.set_zlabel('Kernel Value')
    
    # Save 3D figure
    three_d_path = output_path.replace('.png', '_3d.png')
    plt.tight_layout()
    plt.savefig(three_d_path, dpi=150)
    print(f"3D kernel visualization saved to: {three_d_path}")
    
    # Close figures to free memory
    plt.close('all')
    
    return output_path

def main():
    # Set kernel size (P parameter from C# code)
    P = 8  # Change this to adjust kernel size
    
    # Compute the kernel
    kernel = precompute_kernel_values(P)
    
    # Generate visualization
    visualize_kernel(kernel, P)
    
    # Format for GLSL
    glsl_code = format_for_glsl(kernel, P)
    
    # Print the GLSL code to console
    print("\nGLSL Lookup Table:")
    print(glsl_code)
    
    # Optionally save to a file
    output_file = "kernel_lookup_table.gdshaderinc"
    with open(output_file, "w") as f:
        f.write(glsl_code)
    
    print(f"\nLookup table saved to {output_file}")

if __name__ == "__main__":
    main()