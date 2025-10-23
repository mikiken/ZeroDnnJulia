import Plots

x = range(0, stop=6, step=0.1)
y = sin.(x) # . 演算子 : 演算子をelement-wiseに適用する (broadcast)
Plots.plot(x, y, label="sin")

# plot! で既存のグラフに追加描画できる
Plots.plot!(x, x -> cos(x),
    label="cos",
    ls=:dash,
    xlabel="x",
    ylabel="y",
    title="sin & cos"
)
