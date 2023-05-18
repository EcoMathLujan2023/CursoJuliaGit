using Plots

function paso_levy(α=1.5, β=1.0)
    # Generar un paso de Levy utilizando una distribución de power law
    u = rand()
    r = β / (u^(1/α))
    θ = 2π * rand()
    
    x = r * cos(θ)
    y = r * sin(θ)
    
    return x, y
end

function generar_posiciones_nidos(n_peces, distancia_minima)
    # Generar posiciones de los nidos espaciados
    x_nidos = []
    y_nidos = []
    
    for _ in 1:n_peces
        # Generar una posición de nido aleatoria
        x_nido, y_nido = paso_levy()
        
        # Verificar si la posición del nido está lo suficientemente alejada de los nidos existentes
        while any(sqrt((x_nido - x)^2 + (y_nido - y)^2) < distancia_minima for (x, y) in zip(x_nidos, y_nidos))
            x_nido, y_nido = paso_levy()
        end
        
        push!(x_nidos, x_nido)
        push!(y_nidos, y_nido)
    end
    
    return x_nidos, y_nidos
end

function mover_peces(n_peces, n_pasos, distancia_maxima, x_nidos, y_nidos)
    # Posiciones iniciales de los peces
    xs = zeros(n_peces, n_pasos)
    ys = zeros(n_peces, n_pasos)
    
    # Guardar las coordenadas del movimiento de los peces
    coordenadas_peces = []
    
    for i in 1:n_peces
        # Asignar la posición inicial del pez al nido
        xs[i, 1] = x_nidos[i]
        ys[i, 1] = y_nidos[i]
        
        for j in 2:n_pasos
            # Calcular la distancia al nido
            distancia_nido = sqrt((xs[i, j-1] - x_nidos[i])^2 + (ys[i, j-1] - y_nidos[i])^2)
            
            if distancia_nido > distancia_maxima
                # Calcular la dirección hacia el nido
                dirección_x = x_nidos[i] - xs[i, j-1]
                dirección_y = y_nidos[i] - ys[i, j-1]
                
                # Normalizar la dirección
                dirección_x /= distancia_nido
                dirección_y /= distancia_nido
                
                # Agregar un componente aleatorio a la dirección
                θ = 2π * rand()
                dirección_x += cos(θ)
                dirección_y += sin(θ)
                
                # Normalizar la dirección resultante
                norma = sqrt(dirección_x^2 + dirección_y^2)
                dirección_x /= norma
                dirección_y /= norma
                
                # Generar un paso en dirección al nido
                paso_x = dirección_x * distancia_maxima
                paso_y = dirección_y * distancia_maxima
                
                # Actualizar la posición del pez
                xs[i, j] = xs[i, j-1] + paso_x
                ys[i, j] = ys[i, j-1] + paso_y
            else
                # Generar un paso de Levy
                paso_x, paso_y = paso_levy()
                
                # Actualizar la posición del pez
                xs[i, j] = xs[i, j-1] + paso_x
                ys[i, j] = ys[i, j-1] + paso_y
            end
        end
        
        # Guardar las coordenadas del movimiento del pez actual
        push!(coordenadas_peces, (copy(xs[i, :]), copy(ys[i, :])))
    end
    
    return coordenadas_peces
end

function graficar_movimiento(coordenadas_peces, x_nidos, y_nidos, n_peces)
    plot(legend = false, aspect_ratio = 1)
    
    paleta_colores = palette(:tab10)
    
    for ((xs, ys), (x_nido, y_nido), pez) in zip(coordenadas_peces, zip(x_nidos, y_nidos), 1:n_peces)
        color_trayectoria = paleta_colores[pez]
        
        plot!(xs, ys, seriestype = :path, color = color_trayectoria, marker = false)
        scatter!(xs, ys, color = color_trayectoria, marker = :circle, markersize = 3)
        scatter!([x_nido], [y_nido], color = color_trayectoria, marker = :circle, markersize = 5)
    end
    
    xlabel!("X")
    ylabel!("Y")
    title!("Movimiento de los peces")
    
    plot!()
end

# Configuración de la simulación
n_peces = 5
n_pasos = 100
distancia_maxima = 10.0
distancia_minima = 20.0

# Generar posiciones de los nidos espaciados
x_nidos, y_nidos = generar_posiciones_nidos(n_peces, distancia_minima)

# Ejecutar la simulación
coordenadas_peces = mover_peces(n_peces, n_pasos, distancia_maxima, x_nidos, y_nidos)

# Graficar el movimiento de los peces y sus nidos
graficar_movimiento(coordenadas_peces, x_nidos, y_nidos, n_peces)
