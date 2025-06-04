# Impor paket yang diperlukan
try
    using CSV
    using DataFrames
    using Plots
    using CategoricalArrays
catch e
    println("Error: Salah satu paket tidak ditemukan. Silakan instal paket yang diperlukan.")
    println("Jalankan: import Pkg; Pkg.add(\"NamaPaket\") untuk paket yang hilang.")
    println("Paket yang diperlukan: CSV, DataFrames, Plots, CategoricalArrays")
    rethrow(e)
end

# Set backend plotting ke GR
gr()

# Baca DataFrame dari file CSV
file_path = "selected_data.csv"
if !isfile(file_path)
    error("File $file_path tidak ditemukan. Pastikan file ini ada di direktori.")
end

df_selected = CSV.read(file_path, DataFrame)
println("Berhasil membaca file $file_path")

# Dapatkan nama kolom
selected_attributes = names(df_selected)
println("Atribut yang dipilih: ", selected_attributes)

# Fungsi untuk membuat data berkelompok
function buat_data_berkelompok(df, kolom, jumlah_kelas=10)
    nilai_min = minimum(df[!, kolom])
    nilai_max = maximum(df[!, kolom])
    bins = range(nilai_min, stop=nilai_max, length=jumlah_kelas+1)
    kelompok = cut(df[!, kolom], bins; extend=true)

    levels_kelompok = levels(kelompok)
    temp_df = DataFrame(group=kelompok)
    frekuensi_df = combine(groupby(temp_df, :group), nrow => :Frekuensi)

    complete_df = DataFrame(Interval=string.(levels_kelompok))  # Label interval
    complete_df.Frekuensi = [get(frekuensi_df[frekuensi_df.group .== i, :Frekuensi], 1, 0) for i in levels_kelompok]

    return complete_df, bins
end

# Buat plot dan data berkelompok
for col in selected_attributes
    println("\n=== Data Berkelompok untuk '$col' ===")
    frekuensi, bins = buat_data_berkelompok(df_selected, col, 10)

    # Tampilkan tabel frekuensi
    tabel = DataFrame(Interval=frekuensi.Interval, Frekuensi=frekuensi.Frekuensi)
    println(tabel)

    # Simpan tabel frekuensi ke CSV
    CSV.write("frekuensi_$col.csv", tabel)
    println("Tabel frekuensi disimpan sebagai 'frekuensi_$col.csv'")

    # Hitung titik tengah setiap interval untuk sumbu X
    midpoints = [(bins[i] + bins[i+1]) / 2 for i in 1:length(bins)-1]

    # Buat bar chart berdasarkan titik tengah
    bar(
        midpoints,
        frekuensi.Frekuensi,
        title="Histogram Data Berkelompok: $col",
        xlabel=col,
        ylabel="Frekuensi",
        legend=false,
        bar_width=diff(bins)[1],
        xticks=(bins, string.(round.(bins, digits=1))),
        size=(800, 400)
    )
    savefig("histogram_$col.png")
    println("Histogram disimpan sebagai 'histogram_$col.png'")
end

# Tampilkan semua plot
display(plot!())
