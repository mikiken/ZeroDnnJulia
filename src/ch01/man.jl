module HumanModule

# 外部に公開する名前を宣言
export Man, hello, goodbye

struct Man
    """サンプル構造体"""
    name::String

    function Man(name::String)
        println("Initilized!")
        new(name)
    end
end

# 関連する関数の定義
function hello(m::Man)
    println("Hello $(m.name)!")
end

function goodbye(m::Man)
    println("Good-bye $(m.name)!")
end

# モジュール内にプライベートな関数（exportしない関数）も定義可能
function private_greeting(name)
    println("This is a private greeting for $name.")
end

end # module HumanModule


# モジュールを読み込む
# using は現在の名前空間にシンボルをインポートする
# 同じファイルやREPLで定義した場合、先頭にドット(.)が必要
using .HumanModule

# export されているので、直接呼び出せる
m = Man("Julia")
hello(m)
goodbye(m)

# export されていない関数はエラーになる
# private_greeting("Test")
# 呼び出す場合はモジュール名を明記する必要がある
HumanModule.private_greeting("Test")


# # モジュールを読み込む
# import はモジュールごとに名前空間が分かれる
import .HumanModule

# 常にモジュール名をプレフィックスとして付ける
m = HumanModule.Man("Julia")
HumanModule.hello(m)
HumanModule.goodbye(m)