using Plots
import Statistics.mean

function guardar_resultados(resultados, nombre_archivo)
    open(nombre_archivo, "w") do file
        # Escribir encabezado
        write(file, "Alpha\tVelocidades\n")
        
        # Escribir datos
        for (α, velocidades) in resultados
            write(file, "$α\t")
            write(file, join(velocidades, "\t"))
            write(file, "\n")
        end
    end
end

function paso_levy(β=1.0, α=1.5)
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

function mover_peces(n_peces, n_pasos, distancia_maxima, x_nidos, y_nidos, α = 1.5,β=1.0)
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
                dirección_x += β * cos(θ)
                dirección_y += β * sin(θ)
                
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
                paso_x, paso_y = paso_levy(β ,α)
                
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

function calcular_velocidad_media(coordenadas_peces, paso_tiempo=1.0)
    n_peces = length(coordenadas_peces)
    n_pasos = length(coordenadas_peces[1][1])
    velocidades = zeros(n_peces)
    
    for i in 1:n_peces
        distancias = zeros(n_pasos - 1)
        for j in 2:n_pasos
            dx = coordenadas_peces[i][1][j] - coordenadas_peces[i][1][j-1]
            dy = coordenadas_peces[i][2][j] - coordenadas_peces[i][2][j-1]
            distancias[j-1] = sqrt(dx^2 + dy^2)
        end
        velocidades[i] = mean(distancias) / paso_tiempo
    end
    
    return velocidades
end


function simulacion_velocidad_media(n_simulaciones, n_peces, n_pasos, distancia_maxima, α_min, α_max, paso_tiempo)
    alpha_values = range(α_min, stop=α_max, length=10)  # Generar valores de α en el rango
    
    resultados = Dict{Float64, Vector{Float64}}()
    
    # Realizar las simulaciones para cada valor de α
    for α in alpha_values
        velocidades = Float64[]
        
        # Ejecutar las simulaciones
        for _ in 1:n_simulaciones
            x_nidos, y_nidos = generar_posiciones_nidos(n_peces, distancia_maxima)
            coordenadas_peces = mover_peces(n_peces, n_pasos, distancia_maxima, x_nidos, y_nidos, α)
            velocidades = vcat(velocidades, calcular_velocidad_media(coordenadas_peces, paso_tiempo))
        end
        
        resultados[α] = velocidades
    end
    
    return resultados
end

function graficar_simulaciones(resultados)
    # Obtener los valores de α y las velocidades medias
    alphas = collect(keys(resultados))
    velocidades = [mean(resultados[α]) for α in alphas]
    
    # Graficar los resultados
    plot(alphas, velocidades, xlabel="α", ylabel="Velocidad Media", legend=false)
end



# Configuración de la simulación
n_peces = 5
n_pasos = 100
distancia_maxima = 10.0
distancia_minima = 10.0

# Parámetros del movimiento de los peces
α = 2

# Generar posiciones de los nidos espaciados
x_nidos, y_nidos = generar_posiciones_nidos(n_peces, distancia_minima)

# Ejecutar la simulación
coordenadas_peces = mover_peces(n_peces, n_pasos, distancia_maxima, x_nidos, y_nidos, α)

# Graficar el movimiento de los peces y sus nidos
graficar_movimiento(coordenadas_peces, x_nidos, y_nidos, n_peces)

# Calcular la velocidad media de cada pez
velocidades_medias = calcular_velocidad_media(coordenadas_peces)

resultados = simulacion_velocidad_media(10, 100, 1000, 10, 1.5, 3.5, 1)

for (α, velocidades) in resultados
    println("Valor de α: $α")
    println("Velocidades medias promedio: $(mean(velocidades))")
    println()
end

graficar_simulaciones(resultados)

guardar_resultados(resultados, "resultados.txt")