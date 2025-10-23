import FileIO, Images
import Plots

img = FileIO.load("./dataset/season.jpg")
# スクリプトの位置を基準にパスを指定する場合
# base_dir = @__DIR__
# img_path = joinpath(base_dir, "..", "dataset", "season.jpg")
# img = FileIO.load(img_path)

Plots.plot(img)
