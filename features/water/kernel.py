import math
import numpy as np
import matplotlib.pyplot as plt
from matplotlib import cm
import os

def j0(x):
    ax = abs(x)
    if ax < 8.0:
        y = x * x
        ans1 = 57568490574.0 + y * (-13362590354.0 + y * (651619640.7 + y * (-11214424.18 + y * (77392.33017 + y * (-184.9052456)))))
        ans2 = 57568490411.0 + y * (1029532985.0 + y * (9494680.718 + y * (59272.64853 + y * (267.8532712 + y * 1.0))))
        return ans1 / ans2
    else:
        z = 8.0 / ax
        y = z * z
        xx = ax - 0.785398164
        ans1 = 1.0 + y * (-0.1098628627e-2 + y * (0.2734510407e-4 + y * (-0.2073370639e-5 + y * 0.2093887211e-6)))
        ans2 = -0.1562499995e-1 + y * (0.1430488765e-3 + y * (-0.6911147651e-5 + y * (0.7621095161e-6 - y * 0.934935152e-7)))
        return math.sqrt(0.636619772 / ax) * (math.cos(xx) * ans1 - z * math.sin(xx) * ans2)

def initialize_kernel(P, dk=0.01, sigma=1.0):
    """
    Compute the elements of the convolution kernel based on the reference implementation.
    dk: Step size for integration.
    sigma: Parameter controlling the exponential decay.
    """
    # Compute normalization factor
    norm = 0.0
    k = 0.0
    while k < 10.0:
        norm += k * k * math.exp(-sigma * k * k)
        k += dk

    # Initialize kernel array
    kernel_size = 2 * P + 1
    kernel = np.zeros((kernel_size, kernel_size))

    # Compute kernel values
    for i in range(-P, P + 1):
        for j in range(-P, P + 1):
            r = math.sqrt(i * i + j * j)
            kern = 0.0
            k = 0.0
            while k < 10.0:
                kern += k * k * math.exp(-sigma * k * k) * j0(r * k)
                k += dk
            kernel[i + P, j + P] = kern / norm

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
    kernel = initialize_kernel(P)
    
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