import Plots

function sigmoid(x)
    1 / (1 + exp(-x))
end

X = range(-5, stop=5, step=0.1)
Y = sigmoid.(X)
Plots.plot(X, Y, ylim=(-0.1, 1.1))