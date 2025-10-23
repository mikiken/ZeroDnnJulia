module MNISTDataset
export load_mnist, init_mnist

using HTTP
using GZip
using Serialization

# const url_base = "http://yann.lecun.com/exdb/mnist/"
const url_base = "https://ossci-datasets.s3.amazonaws.com/mnist/" # mirror site

const key_file = Dict(
    "train_img" => "train-images-idx3-ubyte.gz",
    "train_label" => "train-labels-idx1-ubyte.gz",
    "test_img" => "t10k-images-idx3-ubyte.gz",
    "test_label" => "t10k-labels-idx1-ubyte.gz"
)

# @__DIR__ はこのスクリプトファイルがあるディレクトリ
const dataset_dir = @__DIR__
# Julia の標準シリアライザを使うため、拡張子を .bin に変更
const save_file = joinpath(dataset_dir, "mnist.bin")

const train_num = 60000
const test_num = 10000
const img_dim = (1, 28, 28) # (Channel, Width, Height)
const img_size = 784

"""
MNISTデータセットのファイルをダウンロードする
"""
function _download(file_name::String)
    file_path = joinpath(dataset_dir, file_name)

    if isfile(file_path)
        return
    end

    println("Downloading $file_name ... ")
    # User-Agent ヘッダーを設定 (Pythonコードに倣う)
    headers = ["User-Agent" => "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:47.0) Gecko/20100101 Firefox/47.0"]

    try
        # HTTP.get でファイルを取得
        response = HTTP.get(url_base * file_name, headers)

        # ファイルにバイナリとして書き込む
        open(file_path, "w") do f
            write(f, response.body)
        end
        println("Done")
    catch e
        println("Error downloading $file_name: $e")
        # エラーが発生したら、ダウンロード途中のファイルを削除
        if isfile(file_path)
            rm(file_path)
        end
        rethrow(e)
    end
end

"""
MNISTデータセットの全ファイルをダウンロードする
"""
function download_mnist()
    for v in values(key_file)
        _download(v)
    end
end

"""
Gzip圧縮されたラベルファイルを読み込み、Array{UInt8} として返す
"""
function _load_label(file_name::String)
    file_path = joinpath(dataset_dir, file_name)

    println("Converting $file_name to Array ...")
    labels = GZip.open(file_path, "r") do f
        # オフセット8バイト (マジックナンバー+アイテム数) を読み飛ばす
        seek(f, 8)
        # 残りの全バイトを読み込む
        return read(f)
    end
    println("Done")

    # バイト列を UInt8 の配列として解釈
    # Python の np.frombuffer(..., np.uint8, offset=8) に相当
    return reinterpret(UInt8, labels)
end

"""
Gzip圧縮された画像ファイルを読み込み、Array{UInt8} (784, N) として返す
"""
function _load_img(file_name::String)
    file_path = joinpath(dataset_dir, file_name)

    println("Converting $file_name to Array ...")
    data = GZip.open(file_path, "r") do f
        # オフセット16バイト (マジックナンバー+アイテム数+行数+列数) を読み飛ばす
        seek(f, 16)
        # 残りの全バイトを読み込む
        return read(f)
    end

    # バイト列を UInt8 の配列として解釈
    data_uint8 = reinterpret(UInt8, data)

    # (784, N) の形状に変形 (Julia は列優先)
    # Python の data.reshape(-1, img_size) は (N, 784)
    data_reshaped = reshape(data_uint8, img_size, :)

    println("Done")
    return data_reshaped
end

"""
全データを読み込み、Dict に格納して返す
"""
function _convert_array()
    dataset = Dict{String,Array}()
    dataset["train_img"] = _load_img(key_file["train_img"])
    dataset["train_label"] = _load_label(key_file["train_label"])
    dataset["test_img"] = _load_img(key_file["test_img"])
    dataset["test_label"] = _load_label(key_file["test_label"])
    return dataset
end

"""
データセットをダウンロード・変換し、シリアライズファイル (mnist.bin) を作成する
"""
function init_mnist()
    download_mnist()
    dataset = _convert_array()
    println("Creating serialization file ($save_file) ...")

    # Serialization.serialize を使ってファイルに保存 (pickle.dump の代わり)
    open(save_file, "w") do f
        serialize(f, dataset)
    end
    println("Done!")
end

"""
ラベル配列 (Vector{UInt8}) を One-Hot 表現 (Matrix{Float32}) に変換する
(10, N) の形状で返す
"""
function _change_one_hot_label(X::Vector{UInt8})
    N = length(X)
    # Julia (Flux.jl) の慣習に合わせて (クラス数, バッチサイズ) = (10, N)
    T = zeros(Float32, 10, N)

    for (idx, val) in enumerate(X)
        # Julia は 1-based index なので、ラベル 0 はインデックス 1 に対応
        T[val+1, idx] = 1.0
    end

    return T
end


"""
MNISTデータセットの読み込み

Parameters
----------
normalize : 画像のピクセル値を0.0~1.0に正規化する (default: true)
flatten : 画像を一次元配列 (784, N) にするかどうか (default: true)
          false の場合は (28, 28, 1, N) の4次元配列にする
one_hot_label :
    trueの場合、ラベルはone-hot配列として返す (default: false)

Returns
-------
(訓練画像, 訓練ラベル), (テスト画像, テストラベル)
"""
function load_mnist(; normalize::Bool=true, flatten::Bool=true, one_hot_label::Bool=false)
    if !isfile(save_file)
        init_mnist()
    end

    # Serialization.deserialize で読み込み (pickle.load の代わり)
    dataset = open(save_file, "r") do f
        deserialize(f)
    end

    if normalize
        for key in ("train_img", "test_img")
            # 型を Float32 に変換
            dataset[key] = Float32.(dataset[key])
            # 255.0 で割る (ブロードキャスト)
            dataset[key] ./= 255.0
        end
    end

    if one_hot_label
        dataset["train_label"] = _change_one_hot_label(dataset["train_label"])
        dataset["test_label"] = _change_one_hot_label(dataset["test_label"])
    end

    if !flatten
        for key in ("train_img", "test_img")
            # (784, N) -> (28, 28, 1, N)
            # Julia (Flux.jl) の標準的な画像フォーマット (Width, Height, Channel, Batch)
            img_data = dataset[key]
            N = size(img_data, 2)
            dataset[key] = reshape(img_data, 28, 28, 1, N)
        end
    end

    return (dataset["train_img"], dataset["train_label"]), (dataset["test_img"], dataset["test_label"])
end

"""
メイン実行関数 (Python の if __name__ == '__main__': に相当)
"""
function main()
    # データセットがなければ初期化
    if !isfile(save_file)
        init_mnist()
    else
        println("MNIST dataset ($save_file) already exists.")
        # テスト読み込み
        println("Loading MNIST dataset for testing...")
        (train_img, train_label), (test_img, test_label) = load_mnist(normalize=true, flatten=true, one_hot_label=true)
        println("Train images: ", size(train_img))
        println("Train labels: ", size(train_label))
        println("Test images: ", size(test_img))
        println("Test labels: ", size(test_label))
        println("Load test successful.")
    end
end

end # module MNISTDataset

# スクリプトとして直接実行された場合のみ main() を呼び出す
using .MNISTDataset: main
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
