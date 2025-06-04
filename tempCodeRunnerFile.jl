# Impor paket yang diperlukan
try
    using CSV
    using DataFrames
    using Plots
    using Statistics
    using Distributions
catch e
    println("Error: Salah satu paket tidak ditemukan. Silakan instal paket yang diperlukan.")
    println("Jalankan: import Pkg; Pkg.add(\"NamaPaket\") untuk paket yang hilang.")
    println("Paket yang diperlukan: CSV, DataFrames, Plots, Statistics, Distributions")
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

# Tampilkan rata-rata untuk setiap kolom tanpa pembulatan
println("\n=== Rata-rata untuk setiap kolom ===")
for col in selected_attributes
    mean_col = mean(df_selected[!, col])
    println("Rata-rata $col: ", mean_col)
end

# Fungsi untuk menghitung distribusi eksponensial dan membuat grafik
function plot_exponential_distribution(df, col)
    # Ambil data kolom, abaikan nilai 0 untuk distribusi eksponensial
    data = df[!, col][df[!, col] .> 0]
    if isempty(data)
        println("Kolom $col hanya berisi nol. Tidak dapat memodelkan distribusi eksponensial.")
        return
    end

    # Hitung parameter laju (λ) = 1 / rata-rata data non-nol
    mean_data = mean(data)
    lambda = 1 / mean_data
    println("Parameter laju (λ) untuk $col (berdasarkan data non-nol): ", lambda)

    # Buat distribusi eksponensial
    dist = Exponential(1/lambda)

    # Tentukan rentang untuk sumbu x (0 hingga 3 kali rata-rata untuk menangkap sebagian besar distribusi)
    x = range(0, stop=3*mean_data, length=1000)

    # Hitung fungsi kepadatan peluang (PDF)
    pdf_values = pdf.(dist, x)

    # Buat plot distribusi peluang kontinu
    plot(
        x,
        pdf_values,
        title="Distribusi Peluang Eksponensial: $col",
        xlabel=col,
        ylabel="Kepadatan Peluang",
        label="PDF Eksponensial (λ = $lambda)",
        linewidth=2,
        size=(800, 400)
    )

    # Simpan grafik
    savefig("exponential_pdf_$col.png")
    println("Grafik distribusi peluang disimpan sebagai 'exponential_pdf_$col.png'")

    # Hitung dan tampilkan beberapa peluang contoh tanpa pembulatan
    println("\nPeluang contoh untuk kolom '$col':")
    # P(X < mean)
    prob_less_mean = cdf(dist, mean_data)
    println("P($col < $mean_data) = ", prob_less_mean)
    # P(X > mean)
    prob_greater_mean = 1 - prob_less_mean
    println("P($col > $mean_data) = ", prob_greater_mean)
    # P(mean/2 < X < mean)
    prob_range = cdf(dist, mean_data) - cdf(dist, mean_data/2)
    println("P($(mean_data/2) < $col < $mean_data) = ", prob_range)
end

# Buat plot distribusi eksponensial untuk setiap kolom
for col in selected_attributes
    println("\n=== Distribusi Eksponensial untuk '$col' ===")
    plot_exponential_distribution(df_selected, col)
end

# Tampilkan semua plot
display(plot!())