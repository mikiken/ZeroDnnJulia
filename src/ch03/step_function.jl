import Plots

function step_function(x)
    return x > 0 ? 1 : 0
end

X = range(-5, stop=5, step=0.1)
Y = step_function.(X)
Plots.plot(X, Y, ylim=(-0.1, 1.1))