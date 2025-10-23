import Plots

function sigmoid(x)
    1 / (1 + exp(-x))
end

function step_function(x)
    return x > 0 ? 1 : 0
end

x = range(-5, stop=5, step=0.1)
y1 = sigmoid.(x)
y2 = step_function.(x)

Plots.plot(x, y1)
Plots.plot!(x, y2,
    ls=:dash,
    ylim=(-0.1, 1.1)
)
