# Impor paket yang diperlukan
try
    using CSV
    using DataFrames
    using CategoricalArrays
    using Statistics
    using StatsBase
    using Plots
    using Distributions
catch e
    println("Error: Salah satu paket tidak ditemukan. Silakan instal paket yang diperlukan.")
    println("Jalankan: import Pkg; Pkg.add(\"NamaPaket\") untuk paket yang hilang.")
    println("Paket yang diperlukan: CSV, DataFrames, CategoricalArrays, Statistics, StatsBase, Plots, Distributions")
    rethrow(e)
end

# Set backend plotting ke GR
gr()

# ==================== BACA DAN PREPROSES DATA LATIH ====================

# Tentukan path file
file_path = "data_train.csv"

# Periksa apakah file ada
if !isfile(file_path)
    error("File $file_path tidak ditemukan di direktori $(pwd()). Pastikan file ada di direktori yang benar.")
end

# Inisialisasi data_latih sebagai variabel global
global data_latih = nothing
try
    global data_latih = CSV.read(file_path, DataFrame; delim=',', ignorerepeated=true, silencewarnings=true)
    println("Berhasil membaca file $file_path")
catch e
    println("Error: Gagal membaca file $file_path. Pastikan file ada dan formatnya valid.")
    rethrow(e)
end

# Periksa apakah data_latih berhasil dibaca
if data_latih === nothing
    error("Variabel data_latih tidak didefinisikan. Gagal membaca file CSV.")
end

# Cetak nama kolom untuk debugging
println("\nKolom yang tersedia di data_latih: ", names(data_latih))

# Periksa apakah kolom class ada
if !("class" in names(data_latih))
    error("Kolom 'class' tidak ditemukan di data_latih. Kolom yang tersedia: $(names(data_latih))")
end

# Periksa distribusi label awal
println("\nDistribusi label awal di data_latih:")
try
    println(combine(groupby(data_latih, :class), nrow => :count))
catch e
    println("Error: Gagal menghitung distribusi label. Pastikan kolom 'class' ada di data_latih.")
    rethrow(e)
end

# Standarisasi label: normal = 0, anomaly = 1
data_latih.label_num = map(x -> x == "normal" ? 0 : 1, data_latih.class)

# Periksa distribusi label_num setelah standarisasi
println("\nDistribusi label_num setelah standarisasi (0 = normal, 1 = anomaly):")
println("  Normal (0): ", sum(data_latih.label_num .== 0))
println("  Anomaly (1): ", sum(data_latih.label_num .== 1))

# Peringatan jika semua label_num adalah 0
if sum(data_latih.label_num .== 1) == 0
    println("Peringatan: Semua data memiliki label_num = 0 (Normal). Korelasi dengan label_num mungkin tidak bermakna.")
end

# Tentukan kolom kategorikal berdasarkan nama yang benar
categorical_cols = String[]
for col in ["protocol_type", "service", "flag", "class"]
    if col in names(data_latih)
        push!(categorical_cols, col)
    else
        println("Peringatan: Kolom $col tidak ditemukan di data_latih.")
    end
end

# Konversi kolom ke kategorikal
for col in categorical_cols
    data_latih[!, col] = categorical(data_latih[!, col])
end

# Tangani nilai missing di kolom class
data_latih.class = coalesce.(data_latih.class, "normal")

# Pilih kolom numerik untuk analisis korelasi
global numeric_df = nothing
try
    global numeric_df = select(data_latih, Not(categorical_cols))
    println("\nKolom numerik yang dipilih: ", names(numeric_df))
catch e
    println("Error: Gagal memilih kolom numerik. Pastikan kolom kategorikal valid.")
    rethrow(e)
end

# Periksa apakah numeric_df berhasil dibuat
if numeric_df === nothing
    error("Variabel numeric_df tidak didefinisikan.")
end

# Filter hanya kolom bertipe real
real_cols = names(numeric_df)[findall(col -> eltype(numeric_df[!, col]) <: Real, names(numeric_df))]
global numeric_df = select(numeric_df, real_cols)
println("\nKolom bertipe real: ", real_cols)

# Tangani nilai missing di kolom numerik
for col in names(numeric_df)
    if any(ismissing, numeric_df[!, col])
        println("Peringatan: Kolom $col mengandung nilai missing, diganti dengan 0.0")
        numeric_df[!, col] = coalesce.(numeric_df[!, col], 0.0)
    end
end

# Periksa kolom dengan variansi nol
for col in names(numeric_df)
    if var(numeric_df[!, col]) == 0
        println("Peringatan: Kolom $col memiliki variansi nol, akan diabaikan untuk korelasi.")
        global numeric_df = select(numeric_df, Not(col))
    end
end

# Hitung matriks korelasi
cor_matrix = cor(Matrix(numeric_df))
if any(isnan, cor_matrix) || any(ismissing, cor_matrix)
    println("Peringatan: Matriks korelasi mengandung NaN atau nilai missing. Mengganti NaN dengan 0.0.")
    cor_matrix = replace(cor_matrix, NaN => 0.0)
end
println("\nMatriks korelasi untuk atribut bertipe real:\n", cor_matrix)

# ==================== ANALISIS KORELASI (1a) ====================

# Hitung korelasi dengan label_num sebagai vektor
label_corr = [cor(numeric_df[!, col], data_latih.label_num) for col in names(numeric_df)]
label_corr = replace(label_corr, NaN => 0.0)  # Ganti NaN dengan 0.0

# Buat DataFrame untuk korelasi
corr_df = DataFrame(attribute = names(numeric_df), correlation = label_corr)

# Urutkan berdasarkan nilai absolut korelasi
sort!(corr_df, :correlation, by = abs, rev = true)

println("\nKorelasi atribut bertipe real dengan label_num:")
println(corr_df)

# Pilih 3 atribut real dengan korelasi absolut tertinggi
top_3_real_corr = first(corr_df, 3)
selected_real_attributes = top_3_real_corr.attribute
println("\n3 atribut bertipe real dengan korelasi absolut tertinggi:")
println(top_3_real_corr)
println("Atribut yang dipilih: ", selected_real_attributes)

# ==================== ANALISIS STATISTIKA DESKRIPTIF DAN DISTRIBUSI KONTINU (1b) ====================

function descriptive_stats(data, col_name)
    println("\nStatistika Deskriptif untuk kolom: $col_name")
    col_data = data[:, col_name]
    println("  Rata-rata: ", mean(col_data))
    println("  Median: ", median(col_data))
    try
        modes = StatsBase.mode(col_data, 2)  # Coba hitung hingga 2 modus
        println("  Modus: ", modes)
    catch e
        println("  Modus: Tidak dapat dihitung (kemungkinan data kontinu)")
    end
    println("  Standar Deviasi: ", std(col_data))
    println("  Minimum: ", minimum(col_data))
    println("  Maksimum: ", maximum(col_data))
    println("  Kuartil Pertama (Q1): ", quantile(col_data, 0.25))
    println("  Kuartil Ketiga (Q3): ", quantile(col_data, 0.75))
    println("  Skewness: ", skewness(col_data))
    println("  Kurtosis: ", kurtosis(col_data))
end

# Lakukan analisis statistika deskriptif dan distribusi kontinu
for attr in selected_real_attributes
    if attr in names(data_latih)
        # Analisis statistika deskriptif
        descriptive_stats(data_latih, attr)
        
        # Pasang distribusi Normal
        col_data = data_latih[:, attr]
        try
            dist = fit(Normal, col_data)
            println("\nDistribusi Normal yang dipasang untuk $attr: μ = ", mean(dist), ", σ = ", std(dist))
            
            # Plot histogram dengan PDF distribusi Normal
            p = histogram(col_data, bins=30, normalize=true, title="Distribusi $attr", xlabel=attr, ylabel="Densitas", legend=:topright, alpha=0.7)
            x_range = range(minimum(col_data), maximum(col_data), length=100)
            plot!(x_range, pdf.(dist, x_range), label="PDF Normal Terpasang", linewidth=2)
            savefig("distribusi_$(attr).png")
            println("Plot distribusi untuk $attr disimpan sebagai distribusi_$(attr).png")
        catch e
            println("Peringatan: Gagal memasang distribusi Normal untuk $attr: ", e)
        end
    else
        println("Peringatan: Atribut '$attr' tidak ditemukan di data_latih untuk analisis.")
    end
end