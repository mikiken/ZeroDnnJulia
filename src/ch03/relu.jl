import Plots

function relu(x)
    return max(0, x)
end

x = range(-5, stop=5, step=0.1)
y = relu.(x)
Plots.plot(x, y, ylim=(-1, 5.5))