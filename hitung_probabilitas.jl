using CSV
using DataFrames
using Statistics
using Distributions

# Fungsi untuk memuat dataset
function load_dataset(file_path::String)
    try
        df = CSV.read(file_path, DataFrame)
        println("Dataset berhasil dimuat dari: $file_path")
        return df
    catch e
        println("Error memuat dataset: $e")
        return nothing
    end
end

# Fungsi utama untuk menghitung probabilitas
function calculate_probabilities()
    # Path ke file dataset (ganti dengan path lokal Anda)
    file_path = "data_train.csv"
    df = load_dataset(file_path)
    if df === nothing
        return
    end

    # Periksa keberadaan kolom
    if !("dst_host_srv_count" in names(df))
        println("Kolom 'dst_host_srv_count' tidak ditemukan dalam dataset!")
        return
    end

    # Ambil data dan hapus nilai NA
    dst_host_srv_count = filter(!ismissing, df.dst_host_srv_count)
    if length(dst_host_srv_count) == 0
        println("Tidak ada data yang valid untuk 'dst_host_srv_count'!")
        return
    end

    # Hitung mean dan standar deviasi
    μ = mean(dst_host_srv_count)
    σ = std(dst_host_srv_count)
    dist = Normal(μ, σ)

    # Hitung probabilitas untuk kasus tertentu
    p_less_than_100 = cdf(dist, 100)
    p_greater_than_200 = 1 - cdf(dist, 200)
    p_between_50_150 = cdf(dist, 150) - cdf(dist, 50)

    # Tampilkan hasil dengan format yang sama
    println("\nMean dst_host_srv_count: $μ")
    println("Standar Deviasi dst_host_srv_count: $σ")
    println("\nProbabilitas Distribusi Normal untuk dst_host_srv_count:")
    println("P(X < 100): $p_less_than_100")
    println("P(X > 200): $p_greater_than_200")
    println("P(50 < X < 150): $p_between_50_150")
end

# Jalankan program
println("Analisis Distribusi Normal - NSL-KDD Dataset")
calculate_probabilities()